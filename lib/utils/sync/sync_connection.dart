import 'dart:io';
import 'dart:convert';
import 'dart:async';
import '../crypto/crypto.dart';
import '../crypto/password_store.dart';
import '../crypto/totp_store.dart';

class SyncConnection {
  static const int syncPort = 34568;
  static ServerSocket? currServer;

  static void stopListening() {
    currServer?.close();
    currServer = null;
  }

  static int parseTime(String t) {
    if (t.length != 15) return 0;
    try {
      final d = int.parse(t.substring(0, 2));
      final m = int.parse(t.substring(2, 4));
      final y = int.parse(t.substring(4, 8));
      final h = int.parse(t.substring(9, 11));
      final min = int.parse(t.substring(11, 13));
      final s = int.parse(t.substring(13, 15));
      return DateTime(y, m, d, h, min, s).millisecondsSinceEpoch;
    } catch (e) {
      return 0;
    }
  }

  static List<Map<String, String>> mergeCredentials(List<Map<String, String>> localCreds, List<Map<String, dynamic>> remoteCreds) {
    final merged = <String, Map<String, String>>{};
    for (final cred in localCreds) {
      final id = cred['id'];
      if (id != null) {
        merged[id] = cred;
      }
    }
    for (final cred in remoteCreds) {
      final normalized = cred.map((k, v) => MapEntry(k, v.toString()));
      final id = normalized['id'];
      if (id != null) {
        final existing = merged[id];
        if (existing == null) {
          merged[id] = normalized;
        } else {
          final existingTime = parseTime(existing['updatedAt'] ?? existing['createdAt'] ?? '');
          final incomingTime = parseTime(normalized['updatedAt'] ?? normalized['createdAt'] ?? '');
          if (incomingTime > existingTime) {
            merged[id] = normalized;
          }
        }
      }
    }
    return merged.values.toList();
  }

  static Future<Map<String, List<Map<String, String>>>> sendSyncAndMerge( String deviceIp, String masterPassword, List<Map<String, String>> localTotps, List<Map<String, String>> localPasswords, List<Map<String, String>> localPasswordRecycleBin, List<Map<String, String>> localTotpRecycleBin, String myDeviceName) async {
    final socket = await Socket.connect(deviceIp, syncPort).timeout(const Duration(seconds: 5));
    final req = jsonEncode({'type': 'REQUEST_DATA', 'deviceName': myDeviceName});
    socket.write('$req\n');
    await socket.flush();

    final completer = Completer<Map<String, List<Map<String, String>>>>();
    final buffer = <int>[];
    socket.listen((data) async {
        buffer.addAll(data);
        while (buffer.contains(10)) {
          final idx = buffer.indexOf(10);
          final line = utf8.decode(buffer.sublist(0, idx));
          buffer.removeRange(0, idx + 1);
          if (line.trim().isEmpty) continue;

          try {
            final msg = jsonDecode(line);
            if (msg['type'] == 'SYNC_DATA') {
              final remoteEncryptedTotps = msg['totps'] ?? '';
              final remoteEncryptedPasswords = msg['passwords'] ?? '';
              final remotePasswordRecycleBin = msg['passwordRecycleBin'] ?? [];
              final remoteEncryptedTotpRecycleBin = msg['totpRecycleBin'] ?? '';

              List<Map<String, dynamic>> remoteTotps = [];
              List<Map<String, dynamic>> remotePasswords = [];
              List<Map<String, String>> remotePasswordRecycleBinList = [];
              List<Map<String, String>> remoteTotpRecycleBinList = [];
              try {
                final decTotps = await Crypto.decryptAesWithPassword(remoteEncryptedTotps, masterPassword);
                remoteTotps = List<Map<String, dynamic>>.from(jsonDecode(decTotps));
              } catch (_) {
                throw const FormatException('Master password mismatch');
              }
              try {
                final decPass = await Crypto.decryptAesWithPassword(remoteEncryptedPasswords, masterPassword);
                remotePasswords = List<Map<String, dynamic>>.from(jsonDecode(decPass));
              } catch (_) {
                throw const FormatException('Master password mismatch');
              }
              try {
                remotePasswordRecycleBinList = List<Map<String, String>>.from(
                  (remotePasswordRecycleBin as List).whereType<Map>().map(
                    (item) => item.map(
                      (k, v) => MapEntry(k.toString(), v.toString()),
                    ),
                  ),
                );
              } catch (_) {}
              try {
                if (remoteEncryptedTotpRecycleBin.isNotEmpty) {
                  final decTotpBin = await Crypto.decryptAesWithPassword(remoteEncryptedTotpRecycleBin, masterPassword);
                  remoteTotpRecycleBinList = List<Map<String, String>>.from(
                    jsonDecode(decTotpBin).map((e) => Map<String, String>.from(e))
                  );
                }
              } catch (_) {
                throw const FormatException('Master password mismatch');
              }

              final mergedTotps = mergeCredentials(localTotps, remoteTotps);
              mergedTotps.sort((a, b) => (a['platform'] ?? '').toLowerCase().compareTo((b['platform'] ?? '').toLowerCase()));

              final mergedPasswords = mergeCredentials(localPasswords, remotePasswords);
              mergedPasswords.sort((a, b) => (a['name'] ?? '').toLowerCase().compareTo((b['name'] ?? '').toLowerCase()));
 
              final mergedPasswordRecycleBin = PasswordStore.mergeRecycleBins(localPasswordRecycleBin, remotePasswordRecycleBinList); 
              final mergedTotpRecycleBin = TotpStore.mergeRecycleBins(localTotpRecycleBin, remoteTotpRecycleBinList);

              await PasswordStore.saveAllAndMerge(
                mergedPasswords,
                mergedPasswordRecycleBin,
              );

              final Map<String, int> remoteDeletedLog = {};
              for (final entry in mergedTotpRecycleBin) {
                final id = entry['id'] ?? '';
                if (id.isNotEmpty) {
                  remoteDeletedLog[id] = TotpStore.getDeletedAtMillis(entry);
                }
              }

              await TotpStore.saveAllAndMerge(
                mergedTotps.map((e) => Map<String, String>.from(e)).toList(),
                remoteDeletedLog,
                mergedTotpRecycleBin,
              );

              final encMergedTotps = await Crypto.encryptAesWithPassword(
                jsonEncode(mergedTotps),
                masterPassword,
              );
              final encMergedPasswords = await Crypto.encryptAesWithPassword(
                jsonEncode(mergedPasswords),
                masterPassword,
              );
              final encMergedTotpBin = await Crypto.encryptAesWithPassword(
                jsonEncode(mergedTotpRecycleBin),
                masterPassword,
              );

              final ack = jsonEncode({
                'type': 'SYNC_ACK',
                'totps': encMergedTotps,
                'passwords': encMergedPasswords,
                'passwordRecycleBin': mergedPasswordRecycleBin,
                'totpRecycleBin': encMergedTotpBin,
              });

              socket.write('$ack\n');
              await socket.flush();
              socket.close();

              completer.complete({
                'totps': mergedTotps,
                'passwords': mergedPasswords,
              });
            }
          } catch (e) {
            socket.close();
            if (!completer.isCompleted) completer.completeError(e);
          }
        }
      }, onError: (e) {
        socket.close();
        if (!completer.isCompleted) completer.completeError(e);
      }, onDone: () {
        socket.close();
        if (!completer.isCompleted) completer.completeError('Connection closed');   
    });
    return completer.future;
  }

  static void startListening(String masterPassword, List<Map<String, String>> Function() getLocalTotps, List<Map<String, String>> Function() getLocalPasswords, List<Map<String, String>> Function() getLocalPasswordRecycleBin, List<Map<String, String>> Function() getLocalTotpRecycleBin,
    Future<void> Function( List<Map<String, String>> totps, List<Map<String, String>> passwords, String peerDeviceName) onSyncComplete) async {
    stopListening();
    try {
      currServer = await ServerSocket.bind(InternetAddress.anyIPv4, syncPort);
      currServer?.listen((socket) {
        final buffer = <int>[];
        String peerDeviceName = 'Unknown Device';

        socket.listen((data) async {
            buffer.addAll(data);
            while (buffer.contains(10)) {
              final idx = buffer.indexOf(10);
              final line = utf8.decode(buffer.sublist(0, idx));
              buffer.removeRange(0, idx + 1);
              if (line.trim().isEmpty) continue;

              try {
                final msg = jsonDecode(line);

                if (msg['type'] == 'REQUEST_DATA') {
                  peerDeviceName = msg['deviceName'] ?? 'Unknown Device';

                  final localTotps = getLocalTotps();
                  final localPasswords = getLocalPasswords();
                  final localPasswordRecycleBin = getLocalPasswordRecycleBin();
                  final localTotpRecycleBin = getLocalTotpRecycleBin();

                  final encTotps = await Crypto.encryptAesWithPassword(jsonEncode(localTotps), masterPassword);
                  final encPasswords = await Crypto.encryptAesWithPassword(jsonEncode(localPasswords), masterPassword);
                  final encTotpBin = await Crypto.encryptAesWithPassword(jsonEncode(localTotpRecycleBin), masterPassword);

                  final reply = jsonEncode({
                    'type': 'SYNC_DATA',
                    'totps': encTotps,
                    'passwords': encPasswords,
                    'passwordRecycleBin': localPasswordRecycleBin,
                    'totpRecycleBin': encTotpBin,
                  });
                  socket.write('$reply\n');
                  await socket.flush();
                } 
                else if (msg['type'] == 'SYNC_ACK') {
                  final encTotps = msg['totps'] ?? '';
                  final encPasswords = msg['passwords'] ?? '';
                  final passwordRecycleBinPayload = msg['passwordRecycleBin'] ?? [];
                  final encTotpRecycleBin = msg['totpRecycleBin'] ?? '';

                  List<Map<String, String>> mergedTotps = [];
                  List<Map<String, String>> mergedPasswords = [];
                  List<Map<String, String>> mergedPasswordRecycleBin = [];
                  List<Map<String, String>> mergedTotpRecycleBin = [];

                  try {
                    final decTotps = await Crypto.decryptAesWithPassword(encTotps, masterPassword);
                    mergedTotps = List<Map<String, String>>.from(jsonDecode(decTotps).map((e) => Map<String, String>.from(e)));
                  } catch (_) {
                    throw const FormatException('Master password mismatch');
                  }

                  try {
                    final decPass = await Crypto.decryptAesWithPassword(encPasswords, masterPassword);
                    mergedPasswords = List<Map<String, String>>.from(jsonDecode(decPass).map((e) => Map<String, String>.from(e)));
                  } catch (_) {
                    throw const FormatException('Master password mismatch');
                  }

                  try {
                    mergedPasswordRecycleBin = List<Map<String, String>>.from(
                      (passwordRecycleBinPayload as List).whereType<Map>().map(
                        (item) => item.map(
                          (k, v) => MapEntry(k.toString(), v.toString()),
                        ),
                      ),
                    );
                  } catch (_) {}

                  try {
                    if (encTotpRecycleBin.isNotEmpty) {
                      final decTotpBin = await Crypto.decryptAesWithPassword(encTotpRecycleBin, masterPassword);
                      mergedTotpRecycleBin = List<Map<String, String>>.from(
                        jsonDecode(decTotpBin).map((e) => Map<String, String>.from(e))
                      );
                    }
                  } catch (_) {
                    throw const FormatException('Master password mismatch');
                  }

                  await PasswordStore.saveAllAndMerge(
                    mergedPasswords,
                    mergedPasswordRecycleBin,
                  );

                  final Map<String, int> remoteDeletedLog = {};
                  for (final entry in mergedTotpRecycleBin) {
                    final id = entry['id'] ?? '';
                    if (id.isNotEmpty) {
                      remoteDeletedLog[id] = TotpStore.getDeletedAtMillis(entry);
                    }
                  }

                  await TotpStore.saveAllAndMerge(
                    mergedTotps,
                    remoteDeletedLog,
                    mergedTotpRecycleBin,
                  );

                  await onSyncComplete(
                    mergedTotps,
                    mergedPasswords,
                    peerDeviceName,
                  );
                  socket.close();
                }
              } catch (e) {
                socket.close();
              }
            }
          }, onError: (_) => socket.close(), onDone: () => socket.close());
      });
    } catch (_) {}
  }
}