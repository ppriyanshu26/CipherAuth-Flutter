import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/services/sync_service.dart';
import '../../utils/sync/sync_connection.dart';
import '../../utils/crypto/totp_store.dart';
import '../../utils/crypto/password_store.dart';
import '../../utils/crypto/runtime_key.dart';
import '../../widgets/app_snackbars.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => SyncScreenState();
}

class SyncScreenState extends State<SyncScreen> {
  static const String deviceNamePrefsKey = 'sync_device_name';
  late CipherAuthBroadcaster broadcaster;
  List<Map<String, dynamic>> discoveredDevices = [];
  bool isDiscovering = false;
  late String deviceName;
  final TextEditingController deviceNameController = TextEditingController();
  List<Map<String, String>> localTotps = [];
  List<Map<String, String>> localPasswords = [];
  List<Map<String, String>> localPasswordRecycleBin = [];
  List<Map<String, String>> localTotpRecycleBin = [];

  @override
  void initState() {
    super.initState();
    broadcaster = CipherAuthBroadcaster();
    initializeDeviceName();
  }

  String getDefaultDeviceName() {
    if (kIsWeb) return 'CipherAuth Web';
    if (Platform.isAndroid) return 'CipherAuth Android';
    if (Platform.isWindows) return 'CipherAuth Windows';
    if (Platform.isIOS) return 'CipherAuth iOS';
    if (Platform.isMacOS) return 'CipherAuth macOS';
    if (Platform.isLinux) return 'CipherAuth Linux';
    return 'CipherAuth Device';
  }

  Future<void> initializeDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString(deviceNamePrefsKey)?.trim();
    final initialName = savedName == null || savedName.isEmpty ? getDefaultDeviceName() : savedName;

    if (!mounted) return;
    setState(() {
      deviceName = initialName;
      deviceNameController.text = initialName;
    });

    await loadLocalData();
    if (!mounted) return;

    startListeningAsServer();
    scanForDevices();
  }

  Future<void> loadLocalData() async {
    localTotps = await TotpStore.load();
    localPasswords = await PasswordStore.load();
    localPasswordRecycleBin = await PasswordStore.getRecycleBin(
      purgeExpired: true,
    );
    localTotpRecycleBin = await TotpStore.getRecycleBin(purgeExpired: true);
  }

  Future<void> saveDeviceName() async {
    final updatedName = deviceNameController.text.trim();
    if (updatedName.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(deviceNamePrefsKey, updatedName);
    if (!mounted) return;

    setState(() {
      deviceName = updatedName;
      deviceNameController.text = updatedName;
      deviceNameController.selection = TextSelection.collapsed(
        offset: updatedName.length,
      );
    });

    try {
      broadcaster.stopBroadcasting();
    } catch (_) {}

    await broadcaster.startBroadcasting(deviceName);
    if (!mounted) return;
    AppSnackBars.showCustomSnackBar(context: context, message: 'Device name updated', textColor: Colors.green);
    await scanForDevices();
  }

  void startListeningAsServer() {
    final masterPass = RuntimeKey.rawPassword ?? '';
    if (masterPass.isEmpty) return;

    SyncConnection.startListening(
      masterPass,
      () => localTotps,
      () => localPasswords,
      () => localPasswordRecycleBin,
      () => localTotpRecycleBin,
      (mergedTotps, mergedPasswords, peerName) async {
        await loadLocalData();
        if (mounted) {
          AppSnackBars.showCustomSnackBar(context: context, message: 'Sync successful', textColor: Colors.greenAccent.shade700);
        }
      },
    );
    broadcaster.startBroadcasting(deviceName);
  }

  Future<void> scanForDevices() async {
    setState(() => isDiscovering = true);
    final devices = await CipherAuthDiscovery.discoverDevices(
      excludeDeviceName: deviceName,
    );
    if (mounted) {
      setState(() {
        discoveredDevices = devices;
        isDiscovering = false;
      });
    }
  }

  Future<void> connectToDevice(String ip, String name) async {
    final masterPass = RuntimeKey.rawPassword ?? '';
    if (masterPass.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await SyncConnection.sendSyncAndMerge( ip, masterPass, localTotps, localPasswords, localPasswordRecycleBin, localTotpRecycleBin, deviceName);
      await loadLocalData();

      if (!mounted) return;
      Navigator.pop(context);
      AppSnackBars.showCustomSnackBar(context: context, message: 'Sync successful', textColor: Colors.greenAccent.shade700);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      final errorMsg = e is FormatException && e.message.contains('password mismatch')
          ? 'Password mismatch'
          : 'Sync failed';
      AppSnackBars.showCustomSnackBar(context: context, message: errorMsg, textColor: Colors.red);
    }
  }

  @override
  void dispose() {
    try {
      broadcaster.stopBroadcasting();
    } catch (_) {}
    SyncConnection.stopListening();
    deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Sync'), scrolledUnderElevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh Devices', onPressed: scanForDevices)],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Sync is now compatible only with CipherAuth version 8 or later.\nDevices must be on the same Wi-Fi network.\nPlease disable any VPNs or services that change your IP address.',
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: deviceNameController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'This Device Name',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(icon: const Icon(Icons.check), onPressed: saveDeviceName, tooltip: 'Save Device Name'),
              ),
              onSubmitted: (_) => saveDeviceName(),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: isDiscovering
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Searching for devices on network...'),
                      ],
                    ),
                  )
                : discoveredDevices.isEmpty
                ? Center(
                    child: Text('No devices found on local network.\nEnsure both devices are on the same Wi-Fi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.outline),
                    ),
                  )
                : ListView.builder(
                    itemCount: discoveredDevices.length,
                    itemBuilder: (context, index) {
                      final device = discoveredDevices[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context,).colorScheme.primaryContainer,
                            child: Icon(Icons.devices, color: Theme.of(context,).colorScheme.onPrimaryContainer),
                          ),
                          title: Text(device['name'] ?? 'Unknown Device', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(device['ip'] ?? 'Unknown IP'),
                          trailing: ElevatedButton.icon(
                            onPressed: () => connectToDevice(device['ip'] ?? '', device['name'] ?? 'Unknown',),
                            icon: const Icon(Icons.sync),
                            label: const Text('Sync'),
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
