import 'dart:io';
import 'dart:convert';
import 'dart:async';

class CipherAuthBroadcaster {
  static const int broadcastPort = 34567;
  static const String serviceType = 'CIPHERAUTH_SYNC';
  static const String broadcastAddress = '255.255.255.255';

  late RawDatagramSocket socket;
  bool isRunning = false;
  late Timer broadcastTimer;

  Future<void> startBroadcasting(String deviceName) async {
    if (isRunning) return;

    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      isRunning = true;

      String localIP = await getLocalIP();

      broadcastTimer = Timer.periodic(Duration(seconds: 1), (_) async {
        final message = {
          'type': serviceType,
          'device_name': deviceName,
          'ip': localIP,
          'timestamp': DateTime.now().millisecondsSinceEpoch / 1000,
        };

        final encoded = utf8.encode(jsonEncode(message));

        try {
          socket.send(
            encoded,
            InternetAddress(broadcastAddress),
            broadcastPort,
          );
        } catch (e) {
          //
        }
      });
    } catch (e) {
      isRunning = false;
    }
  }

  void stopBroadcasting() {
    if (!isRunning) return;
    broadcastTimer.cancel();
    socket.close();
    isRunning = false;
  }

  Future<String> getLocalIP() async {
    try {
      final interfaces = await NetworkInterface.list();

      for (final interface in interfaces) {
        if (interface.name.contains('docker') ||
            interface.name.contains('lo') ||
            !interface.addresses.isNotEmpty) {
          continue;
        }

        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4 &&
              !address.address.startsWith('127.')) {
            return address.address;
          }
        }
      }
    } catch (e) {
      //
    }
    return '127.0.0.1';
  }
}

class CipherAuthDiscovery {
  static const int broadcastPort = 34567;
  static const String serviceType = 'CIPHERAUTH_SYNC';
  static const int discoveryTimeoutSeconds = 3;

  static Future<List<Map<String, dynamic>>> discoverDevices({
    String? excludeDeviceName,
  }) async {
    final devices = await performDiscovery(
      excludeDeviceName: excludeDeviceName,
    );

    if (devices.isEmpty) {
      final scannedDevices = await scanNetworkRange(
        excludeDeviceName: excludeDeviceName,
      );
      return scannedDevices;
    }

    return devices;
  }

  static Future<List<Map<String, dynamic>>> performDiscovery({
    String? excludeDeviceName,
  }) async {
    final devices = <String, Map<String, dynamic>>{};

    try {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        broadcastPort,
        reuseAddress: true,
      );

      final completer = Completer<void>();
      final subscription = socket.asBroadcastStream().listen(
        (RawSocketEvent event) {
          if (event == RawSocketEvent.read) {
            final datagram = socket.receive();
            if (datagram == null) return;

            try {
              final message = jsonDecode(utf8.decode(datagram.data));

              if (message['type'] == serviceType) {
                final deviceName = message['device_name'] ?? 'Unknown';

                if (excludeDeviceName != null &&
                    deviceName == excludeDeviceName) {
                  return;
                }

                final deviceIp = datagram.address.address;

                devices[deviceName] = {
                  'name': deviceName,
                  'ip': deviceIp,
                  'timestamp': message['timestamp'] ?? 0,
                };
              }
            } catch (e) {
              //
            }
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );

      await completer.future
          .timeout(Duration(seconds: discoveryTimeoutSeconds))
          .catchError((e) {
            //
          });

      subscription.cancel();
      socket.close();
      return devices.values.toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> scanNetworkRange({
    String? excludeDeviceName,
  }) async {
    final devices = <String, Map<String, dynamic>>{};

    try {
      final localIP = await getLocalIPForScanning();
      if (localIP == null) return [];

      final parts = localIP.split('.');
      if (parts.length != 4) return [];

      final networkPrefix = '${parts[0]}.${parts[1]}.${parts[2]}';

      final futures = <Future>[];
      for (int i = 1; i <= 254; i++) {
        final ip = '$networkPrefix.$i';
        if (ip == localIP) continue;
        futures.add(probeDeviceIP(ip, devices));
      }

      await Future.wait(
        futures,
        eagerError: false,
      ).timeout(Duration(seconds: 10)).catchError((_) {
        return [];
      });

      return devices.values.toList();
    } catch (e) {
      return [];
    }
  }

  static Future<String?> getLocalIPForScanning() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        if (interface.name.contains('docker') ||
            interface.name.contains('lo')) {
          continue;
        }
        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4 &&
              !address.address.startsWith('127.')) {
            return address.address;
          }
        }
      }
    } catch (e) {
      //
    }
    return null;
  }

  static Future<void> probeDeviceIP(
    String ip,
    Map<String, Map<String, dynamic>> devices,
  ) async {
    try {
      final socket = await Socket.connect(
        ip,
        34567,
        timeout: Duration(milliseconds: 500),
      );
      socket.close();
      devices[ip] = {
        'name': 'Device at $ip',
        'ip': ip,
        'timestamp': DateTime.now().millisecondsSinceEpoch / 1000,
      };
    } catch (e) {
      //
    }
  }
}
