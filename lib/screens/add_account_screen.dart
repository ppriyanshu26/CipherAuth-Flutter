import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import '../utils/totp_store.dart';
import '../utils/qr_decoder.dart';

class AddAccountScreen extends StatefulWidget {
  final String? initialUrl;

  const AddAccountScreen({super.key, this.initialUrl});

  @override
  State<AddAccountScreen> createState() => AddAccountScreenState();
}

class AddAccountScreenState extends State<AddAccountScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  MobileScannerController? scannerController;

  final platformCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final secretCtrl = TextEditingController();

  bool fromQr = false;
  bool scanned = false;
  bool isScanningImage = false;
  String? error;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);

    if (Platform.isAndroid || Platform.isIOS) {
      scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
    }

    // Handle deep link intent if provided
    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      populateFromOtpAuth(widget.initialUrl!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && tabController.index != 1) {
          tabController.animateTo(1);
        }
      });
    }
  }

  @override
  void dispose() {
    scannerController?.dispose();
    tabController.dispose();
    platformCtrl.dispose();
    usernameCtrl.dispose();
    secretCtrl.dispose();
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
  }

  void onDetect(BarcodeCapture capture) async {
    if (scanned) return;

    final barcode = capture.barcodes.first;
    final value = barcode.rawValue;

    if (value == null || !value.startsWith('otpauth://')) return;

    scanned = true;
    await scannerController?.stop();

    if (!mounted) return;

    populateFromOtpAuth(value);
    tabController.animateTo(1);
    setState(() {});
  }

  Future<void> scanQrFromImage() async {
    try {
      final picker = ImagePicker();

      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 70,
      );

      if (image == null) return;

      setState(() => isScanningImage = true);

      String? value;

      if (Platform.isAndroid || Platform.isIOS) {
        final inputImage = InputImage.fromFilePath(image.path);
        final barcodeScanner = BarcodeScanner();

        try {
          final barcodes = await barcodeScanner
              .processImage(inputImage)
              .timeout(const Duration(seconds: 3));

          if (barcodes.isNotEmpty) {
            value = barcodes.first.rawValue;
          }
        } catch (_) {}

        await barcodeScanner.close();
      } else {
        try {
          value = await QRDecoder.decodeFromFile(image.path)
          .timeout(const Duration(seconds: 3));
        } catch (_) {}
      }

      setState(() => isScanningImage = false);

      if (value == null || !value.startsWith('otpauth://')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to read QR code',
              style: TextStyle(color: Colors.red),
            ),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      if (!mounted) return;

      populateFromOtpAuth(value);
      tabController.animateTo(1);
      setState(() {});
    } catch (_) {
      setState(() => isScanningImage = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error scanning image',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  Future<void> saveManual() async {
    final platform = platformCtrl.text.trim();
    final username = usernameCtrl.text.trim();
    final secret = secretCtrl.text.replaceAll(' ', '').toUpperCase();

    if (platform.isEmpty) {
      setState(() => error = 'Platform cannot be empty');
      return;
    }

    if (username.isEmpty) {
      setState(() => error = 'Username cannot be empty');
      return;
    }

    if (secret.isEmpty) {
      setState(() => error = 'Secret key cannot be empty');
      return;
    }

    if (!isValidBase32(secret)) {
      setState(() => error = 'Invalid secret key format');
      return;
    }

    setState(() => error = null);

    final url = buildTotpUrl(
      platform: platform,
      username: username,
      secret: secret,
    );

    final added = await TotpStore.add(platform, url);

    if (!added) {
      setState(() => error = 'Account already exists');
      return;
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Account'),
        bottom: TabBar(
          controller: tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Scan QR'),
            Tab(text: 'Manual'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          if (Platform.isAndroid || Platform.isIOS)
            Stack(
              children: [
                MobileScanner(
                  controller: scannerController,
                  onDetect: onDetect,
                ),
                if (isScanningImage)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(),
                      ),
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
                    ),
                  ),
                ),
              ],
            )
          else
            Center(
              child: ElevatedButton.icon(
                onPressed: scanQrFromImage,
                icon: const Icon(Icons.image),
                label: const Text('Browse from Device'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                TextField(
                  controller: platformCtrl,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => saveManual(),
                  decoration: const InputDecoration(
                    labelText: 'Platform',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: usernameCtrl,
                  readOnly: fromQr,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => saveManual(),
                  decoration: const InputDecoration(
                    labelText: 'Username / Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: secretCtrl,
                  readOnly: fromQr,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => saveManual(),
                  decoration: const InputDecoration(
                    labelText: 'Secret key',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
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
