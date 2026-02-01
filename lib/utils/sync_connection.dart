import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'crypto.dart';

class SyncConnection {
  static const int syncPort = 34568;
  static ServerSocket? currServer;

  static void stopListening() {
    currServer?.close();
    currServer = null;
  }

  static Future<Map<String, dynamic>> sendPasswordHashAndSync(
    String deviceIp,
    String passwordHash,
    String masterPassword,
    List<Map<String, String>> localCredentials,
  ) async {
    try {
      final socket = await Socket.connect(
        deviceIp,
        syncPort,
      ).timeout(Duration(seconds: 5));

      final passwordMessage = jsonEncode({
        'type': 'PASSWORD_HASH',
        'hash': passwordHash,
      });
      socket.write('$passwordMessage\n');
      await socket.flush();

      final completer = Completer<Map<String, dynamic>>();
      final messageBuffer = <int>[];
      var receivedPasswordResponse = false;
      var receivedDataResponse = false;

      socket.listen(
        (data) async {
          try {
            messageBuffer.addAll(data);

            while (messageBuffer.contains(10)) {
              final newlineIndex = messageBuffer.indexOf(10);
              final messageBytes = messageBuffer.sublist(0, newlineIndex);
              messageBuffer.removeRange(0, newlineIndex + 1);

              final message = jsonDecode(utf8.decode(messageBytes));
              final type = message['type'] as String?;

              if (!receivedPasswordResponse &&
                  type == 'PASSWORD_HASH_RESPONSE') {
                receivedPasswordResponse = true;
                messageBuffer.clear();

                if (message['hash'] != passwordHash) {
                  socket.close();
                  completer.complete({
                    'success': false,
                    'reason': 'password_mismatch',
                  });
                  return;
                }

                final requestMessage = jsonEncode({'type': 'REQUEST_DATA'});
                socket.write('$requestMessage\n');
                await socket.flush();
              } else if (receivedPasswordResponse &&
                  !receivedDataResponse &&
                  type == 'DATA_RESPONSE') {
                receivedDataResponse = true;
                messageBuffer.clear();

                final encryptedRemoteData = message['encrypted_data'] as String;
                final decryptedRemoteData = await Crypto.decryptAesWithPassword(
                  encryptedRemoteData,
                  masterPassword,
                );
                final remoteCredentials =
                    jsonDecode(decryptedRemoteData) as List<dynamic>;

                final mergedCredentials = mergeCredentials(
                  localCredentials,
                  remoteCredentials.cast<Map<String, dynamic>>(),
                );

                final mergedJson = jsonEncode(mergedCredentials);
                final encryptedMergedData = await Crypto.encryptAesWithPassword(
                  mergedJson,
                  masterPassword,
                );

                final mergedMessage = jsonEncode({
                  'type': 'MERGED_DATA',
                  'encrypted_data': encryptedMergedData,
                });
                socket.write('$mergedMessage\n');
                await socket.flush();

                socket.close();

                completer.complete({
                  'success': true,
                  'mergedCredentials': mergedCredentials,
                });
              }
            }
          } catch (e) {
            if (!completer.isCompleted) {
              completer.complete({
                'success': false,
                'reason': 'message_parse_error',
              });
            }
            socket.close();
          }
        },
        onError: (e) {
          if (!completer.isCompleted) {
            completer.complete({
              'success': false,
              'reason': 'connection_error',
              'error': '$e',
            });
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete({
              'success': false,
              'reason': 'connection_closed',
            });
          }
        },
      );

      return completer.future.timeout(
        Duration(seconds: 10),
        onTimeout: () {
          socket.close();
          return {'success': false, 'reason': 'timeout'};
        },
      );
    } catch (e) {
      return {
        'success': false,
        'reason': 'connection_error',
        'error': e.toString(),
      };
    }
  }

  static void startListeningForSync(
    String passwordHash,
    String masterPassword,
    List<Map<String, String>> localCredentials,
    Function(bool, List<Map<String, String>>?) onComplete,
  ) {
    stopListening();
    Future.delayed(Duration(milliseconds: 100)).then((_) {
      ServerSocket.bind(InternetAddress.anyIPv4, syncPort)
          .then((server) {
            currServer = server;
            server.listen((socket) {
              handleSyncConnection(
                socket,
                passwordHash,
                masterPassword,
                localCredentials,
                onComplete,
              );
            });
          })
          .catchError((e) {
          });
    });
  }

  static void handleSyncConnection(
    Socket socket,
    String passwordHash,
    String masterPassword,
    List<Map<String, String>> localCredentials,
    Function(bool, List<Map<String, String>>?) onComplete,
  ) {
    bool passwordMatched = false;
    final messageBuffer = <int>[];

    socket.listen(
      (data) async {
        try {
          messageBuffer.addAll(data);

          while (messageBuffer.contains(10)) {
            final newlineIndex = messageBuffer.indexOf(10);
            final messageBytes = messageBuffer.sublist(0, newlineIndex);
            messageBuffer.removeRange(0, newlineIndex + 1);

            final message = jsonDecode(utf8.decode(messageBytes));
            final type = message['type'] as String?;

            if (type == 'PASSWORD_HASH') {
              final remoteHash = message['hash'];
              passwordMatched = remoteHash == passwordHash;

              final response = jsonEncode({
                'type': 'PASSWORD_HASH_RESPONSE',
                'hash': passwordHash,
                'match': passwordMatched,
              });
              socket.write('$response\n');
              await socket.flush();
            } else if (type == 'REQUEST_DATA' && passwordMatched) {
              final credentialsJson = jsonEncode(localCredentials);
              final encryptedData = await Crypto.encryptAesWithPassword(
                credentialsJson,
                masterPassword,
              );

              final response = jsonEncode({
                'type': 'DATA_RESPONSE',
                'encrypted_data': encryptedData,
              });
              socket.write('$response\n');
              await socket.flush();
            } else if (type == 'MERGED_DATA' && passwordMatched) {
              final encryptedMergedData = message['encrypted_data'] as String;
              final decryptedMergedData = await Crypto.decryptAesWithPassword(
                encryptedMergedData,
                masterPassword,
              );
              final mergedCredentials =
                  jsonDecode(decryptedMergedData) as List<dynamic>;
              final typedMergedCredentials = <Map<String, String>>[];
              for (final cred in mergedCredentials) {
                if (cred is Map) {
                  typedMergedCredentials.add({
                    'id': (cred['id'] ?? '').toString(),
                    'platform': (cred['platform'] ?? '').toString(),
                    'username': (cred['username'] ?? '').toString(),
                    'secretcode': (cred['secretcode'] ?? '').toString(),
                  });
                }
              }

              onComplete(true, typedMergedCredentials);
              socket.close();
            }
          }
        } catch (e) {
          socket.close();
        }
      },
      onError: (e) {
        socket.close();
      },
      onDone: () {
        socket.close();
      },
    );
  }

  static List<Map<String, String>> mergeCredentials(
    List<Map<String, String>> localCreds,
    List<Map<String, dynamic>> remoteCreds,
  ) {
    final merged = <String, Map<String, String>>{};
    for (final cred in localCreds) {
      final id = cred['id'];
      if (id != null) {
        merged[id] = Map.from(cred);
      }
    }
    for (final cred in remoteCreds) {
      final id = cred['id']?.toString();
      if (id != null) {
        merged[id] = {
          'id': id,
          'platform': (cred['platform'] ?? '').toString(),
          'username': (cred['username'] ?? '').toString(),
          'secretcode': (cred['secretcode'] ?? '').toString(),
        };
      }
    }

    final list = merged.values.toList();
    list.sort((a, b) {
      final platformA = (a['platform'] ?? '').toLowerCase();
      final platformB = (b['platform'] ?? '').toLowerCase();
      return platformA.compareTo(platformB);
    });

    return list;
  }
}
