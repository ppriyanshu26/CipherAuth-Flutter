import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/sync_service.dart';
import '../utils/sync_connection.dart';
import '../utils/storage.dart';
import '../utils/totp_store.dart';
import '../utils/runtime_key.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => SyncScreenState();
}

class SyncScreenState extends State<SyncScreen> {
  late CipherAuthBroadcaster broadcaster;
  List<Map<String, dynamic>> discoveredDevices = [];
  bool isDiscovering = false;
  bool isBroadcasting = false;
  bool syncOccurred = false;
  String deviceName = 'Flutter Device';
  final TextEditingController deviceNameController = TextEditingController();

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
            await TotpStore.saveAll(mergedCredentials);
            if (!mounted) return;
            syncOccurred = true;
            final message = '✅ SYNC COMPLETE!';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.green,
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
    final savedName = prefs.getString('device_name') ?? 'Flutter Device';
    setState(() {
      deviceName = savedName;
      deviceNameController.text = deviceName;
    });
    startSync();
  }

  Future<void> saveDeviceName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_name', name);
    setState(() => deviceName = name);
    broadcaster.stopBroadcasting();
    startSync();
  }

  Future<void> startSync() async {
    setState(() => isBroadcasting = true);
    await broadcaster.startBroadcasting(deviceName);
    discoverDevices();
  }

  Future<void> discoverDevices() async {
    setState(() => isDiscovering = true);
    final devices = await compute(runDiscovery, deviceName);
    setState(() {
      discoveredDevices = devices;
      isDiscovering = false;
    });
  }

  Future<void> connectToDevice(String deviceIp, String deviceName) async {
    final passwordHash = await Storage.getStoredPassword();
    if (passwordHash == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('❌ No password set')));
      return;
    }

    final masterPassword = RuntimeKey.rawPassword;
    if (masterPassword == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Cannot retrieve master password')),
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
        await TotpStore.saveAll(mergedCredentials);
        syncOccurred = true;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ SYNC COMPLETE!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      final reason = result['reason'] ?? 'unknown_error';
      final message = reason == 'password_mismatch'
          ? '❌ PASSWORD MISMATCH'
          : '❌ Sync failed: $reason';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
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
                const SizedBox(height: 16),
                Text(
                  isBroadcasting ? '📡 Broadcasting...' : 'Ready to sync',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
          if (discoveredDevices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: isDiscovering ? null : discoverDevices,
                icon: const Icon(Icons.refresh),
                label: const Text('Search Again'),
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
