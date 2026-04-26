import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/sync/sync_service.dart';
import '../utils/sync/sync_connection.dart';
import '../utils/services/storage_service.dart';
import '../utils/crypto/totp_store.dart';
import '../utils/crypto/runtime_key.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => SyncScreenState();
}

class SyncScreenState extends State<SyncScreen> {
  late CipherAuthBroadcaster broadcaster;
  List<Map<String, dynamic>> discoveredDevices = [];
  bool isDiscovering = false;
  bool syncOccurred = false;
  late String deviceName;
  final TextEditingController deviceNameController = TextEditingController();

  String setDeviceName() {
    if (Platform.isAndroid) {
      return 'CipherAuth Android';
    } else if (Platform.isWindows) {
      return 'CipherAuth Windows';
    } else if (Platform.isIOS) {
      return 'CipherAuth iOS';
    } else if (Platform.isMacOS) {
      return 'CipherAuth macOS';
    } else if (Platform.isLinux) {
      return 'CipherAuth Linux';
    }
    return 'CipherAuth Device';
  }

  @override
  void initState() {
    super.initState();
    broadcaster = CipherAuthBroadcaster();
    loadDeviceName();
    initializeListening();
  }

  void initializeListening() async {
    final passwordHash = await Storage.getStoredPassword();
    if (passwordHash != null && mounted) {
      final masterPassword = RuntimeKey.rawPassword;
      if (masterPassword == null) return;

      final localCredentials = await TotpStore.load();
      SyncConnection.startListeningForSync(
        passwordHash,
        masterPassword,
        localCredentials,
        (success, mergedCredentials) async {
          if (!mounted) return;
          if (success && mergedCredentials != null) {
            syncOccurred = true;
            final message = 'SYNC COMPLETE!';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  message,
                  style: const TextStyle(color: Colors.green),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      );
    }
  }

  Future<void> loadDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('device_name') ?? setDeviceName();
    if (!mounted) return;
    setState(() {
      deviceName = savedName;
      deviceNameController.text = deviceName;
    });
    startSync();
  }

  Future<void> saveDeviceName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_name', name);
    if (!mounted) return;
    setState(() => deviceName = name);
    broadcaster.stopBroadcasting();
    startSync();
  }

  Future<void> startSync() async {
    await broadcaster.startBroadcasting(deviceName);
    discoverDevices();
  }

  Future<void> discoverDevices() async {
    if (!mounted) return;
    setState(() => isDiscovering = true);
    final devices = await compute(runDiscovery, deviceName);
    if (!mounted) return;
    setState(() {
      discoveredDevices = devices;
      isDiscovering = false;
    });
  }

  Future<void> connectToDevice(String deviceIp, String deviceName) async {
    final passwordHash = await Storage.getStoredPassword();
    if (passwordHash == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No password set', style: TextStyle(color: Colors.red)),
        ),
      );
      return;
    }

    final masterPassword = RuntimeKey.rawPassword;
    if (masterPassword == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot retrieve master password',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
      return;
    }

    final localCredentials = await TotpStore.load();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Connecting and syncing...'),
        duration: Duration(seconds: 1),
      ),
    );

    final result = await SyncConnection.sendPasswordHashAndSync(
      deviceIp,
      passwordHash,
      masterPassword,
      localCredentials,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final mergedCredentials =
          result['mergedCredentials'] as List<Map<String, String>>?;
      if (mergedCredentials != null) {
        final mergedDeletionLogDynamic =
            result['mergedDeletionLog'] as Map<String, dynamic>?;
        final mergedDeletionLog = <String, int>{};
        if (mergedDeletionLogDynamic != null) {
          mergedDeletionLogDynamic.forEach((k, v) {
            mergedDeletionLog[k] = (v as num).toInt();
          });
        }
        final mergedRecycleBinDynamic =
            result['mergedRecycleBin'] as List<dynamic>?;
        final mergedRecycleBin = <Map<String, String>>[];
        if (mergedRecycleBinDynamic != null) {
          for (final entry in mergedRecycleBinDynamic) {
            if (entry is Map) {
              mergedRecycleBin.add(
                TotpStore.normalizeRecycleBinEntry(
                  entry.cast<String, dynamic>(),
                ),
              );
            }
          }
        }

        await TotpStore.saveAllAndMerge(
          mergedCredentials,
          mergedDeletionLog,
          mergedRecycleBin,
        );
        syncOccurred = true;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'SYNC COMPLETE!',
            style: TextStyle(color: Colors.green),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      final reason = result['reason'] ?? 'unknown_error';
      final message = reason == 'password_mismatch'
          ? 'PASSWORD MISMATCH'
          : 'Sync failed';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.red)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    broadcaster.stopBroadcasting();
    SyncConnection.stopListening();
    deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Devices'),
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            SyncConnection.stopListening();
            broadcaster.stopBroadcasting();
            Navigator.pop(context, syncOccurred);
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: deviceNameController,
                  decoration: InputDecoration(
                    labelText: 'Device Name',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () {
                        saveDeviceName(deviceNameController.text);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Device name updated'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: isDiscovering ? null : discoverDevices,
                  icon: const Icon(Icons.search),
                  label: const Text('Discover Devices'),
                ),
              ],
            ),
          ),

          Expanded(
            child: discoveredDevices.isEmpty
                ? Center(
                    child: Text(
                      isDiscovering ? 'Searching...' : 'No devices found',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: discoveredDevices.length,
                    itemBuilder: (context, index) {
                      final device = discoveredDevices[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.devices),
                          title: Text(device['name'] ?? 'Unknown'),
                          subtitle: Text(device['ip'] ?? 'No IP'),
                          trailing: ElevatedButton(
                            onPressed: () => connectToDevice(
                              device['ip'] ?? '',
                              device['name'] ?? 'Unknown',
                            ),
                            child: const Text('Connect'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

Future<List<Map<String, dynamic>>> runDiscovery(String? excludeDeviceName) {
  return CipherAuthDiscovery.discoverDevices(
    excludeDeviceName: excludeDeviceName,
  );
}
