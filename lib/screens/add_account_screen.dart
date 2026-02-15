import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import '../utils/totp_store.dart';
import '../utils/qr_decoder.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => AddAccountScreenState();
}

class AddAccountScreenState extends State<AddAccountScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  late final MobileScannerController? scannerController;

  final platformCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final secretCtrl = TextEditingController();

  bool fromQr = false;
  bool scanned = false;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    if (Platform.isAndroid || Platform.isIOS) {
      scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
    } else {
      scannerController = null;
    }
  }

  @override
  void dispose() {
    if (Platform.isAndroid || Platform.isIOS) {
      scannerController?.dispose();
    }
    tabController.dispose();
    super.dispose();
  }

  String buildTotpUrl({
    required String platform,
    required String username,
    required String secret,
  }) {
    return Uri(
      scheme: 'otpauth',
      host: 'totp',
      path: '$platform:$username',
      queryParameters: {
        'secret': secret,
        'issuer': platform,
        'digits': '6',
        'period': '30',
      },
    ).toString();
  }

  bool isValidBase32(String input) {
    final cleaned = input.replaceAll(' ', '').replaceAll('=', '').toUpperCase();
    return cleaned.isNotEmpty && RegExp(r'^[A-Z2-7]+$').hasMatch(cleaned);
  }

  void populateFromOtpAuth(String url) {
    final uri = Uri.parse(url);
    final label = uri.pathSegments.last;

    String platform = '';
    String username = '';

    if (label.contains(':')) {
      final parts = label.split(':');
      platform = parts[0];
      username = parts.sublist(1).join(':');
    } else {
      platform = label;
    }

    final issuer = uri.queryParameters['issuer'];
    if (issuer != null && issuer.isNotEmpty) {
      platform = issuer;
    }

    final secret = uri.queryParameters['secret'] ?? '';

    platformCtrl.text = platform;
    usernameCtrl.text = username;
    secretCtrl.text = secret.toUpperCase();

    fromQr = true;
    tabController.animateTo(1);
    setState(() {});
  }

  void onDetect(BarcodeCapture capture) async {
    if (scanned) return;

    final barcode = capture.barcodes.first;
    final value = barcode.rawValue;

    if (value == null || !value.startsWith('otpauth://')) return;

    scanned = true;

    if (Platform.isAndroid || Platform.isIOS) {
      await scannerController?.stop();
    }

    if (!mounted) return;

    populateFromOtpAuth(value);
    setState(() {});
  }

  Future<void> saveManual() async {
    final platform = platformCtrl.text.trim();
    final username = usernameCtrl.text.trim();
    final secret = secretCtrl.text.replaceAll(' ', '').toUpperCase();

    if (platform.isEmpty || username.isEmpty || secret.isEmpty) return;
    if (!isValidBase32(secret)) return;

    final url = buildTotpUrl(
      platform: platform,
      username: username,
      secret: secret,
    );

    final added = await TotpStore.add(platform, url);

    if (!added) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Account already exists')));
      return;
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> scanQrFromImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      String? value;

      if (Platform.isAndroid || Platform.isIOS) {
        // Use ML Kit for mobile platforms (optimal performance)
        final inputImage = InputImage.fromFilePath(image.path);
        final barcodeScanner = BarcodeScanner();

        final barcodes = await barcodeScanner.processImage(inputImage);
        await barcodeScanner.close();

        if (barcodes.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No QR code found in image')),
          );
          return;
        }

        value = barcodes.first.rawValue;
      } else {
        // Use zxing2 for Windows/macOS/Linux
        try {
          value = await QRDecoder.decodeFromFile(image.path);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error scanning image: $e')));
          return;
        }
      }

      if (value == null || !value.startsWith('otpauth://')) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid TOTP QR code')));
        return;
      }

      if (!mounted) return;
      populateFromOtpAuth(value);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error scanning image: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Account'),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: 'Scan QR'),
            Tab(text: 'Manual'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          // Scan QR Tab
          if (Platform.isAndroid || Platform.isIOS)
            Stack(
              children: [
                MobileScanner(
                  controller: scannerController,
                  onDetect: onDetect,
                ),
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: scanQrFromImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Browse from Device'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.smartphone, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Use your mobile to scan',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: scanQrFromImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Browse from Device'),
                  ),
                ],
              ),
            ),
          // Manual Entry Tab
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                TextField(
                  controller: platformCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Platform',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: usernameCtrl,
                  readOnly: fromQr,
                  decoration: const InputDecoration(
                    labelText: 'Username / Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: secretCtrl,
                  readOnly: fromQr,
                  decoration: const InputDecoration(
                    labelText: 'Secret key',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: saveManual,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
