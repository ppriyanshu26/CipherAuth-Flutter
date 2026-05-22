import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/crypto/totp_store.dart';

class MouseWheelHorizontalScroll extends StatefulWidget {
  final Widget child;
  const MouseWheelHorizontalScroll({super.key, required this.child});
  @override
  State<MouseWheelHorizontalScroll> createState() => MouseWheelHorizontalScrollState();
}

class MouseWheelHorizontalScrollState extends State<MouseWheelHorizontalScroll> {
  final ScrollController controller = ScrollController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || event.kind != PointerDeviceKind.mouse) {
      return;
    }

    if (!controller.hasClients) return;
    final delta = event.scrollDelta.dy != 0
        ? event.scrollDelta.dy
        : event.scrollDelta.dx;
    if (delta == 0) return;

    final position = controller.position;
    final target = (controller.offset + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    controller.jumpTo(target.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: handlePointerSignal,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        child: widget.child,
      ),
    );
  }
}

class AuthenticatorCard extends StatefulWidget {
  final Map<String, String> totpItem;
  const AuthenticatorCard({super.key, required this.totpItem});

  @override
  State<AuthenticatorCard> createState() => AuthenticatorCardState();
}

class AuthenticatorCardState extends State<AuthenticatorCard> {
  late Map<String, String> item;

  @override
  void initState() {
    super.initState();
    item = widget.totpItem;
  }

  void copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String formatDateString(String dateStr) {
    if (dateStr.length == 15 && dateStr.contains(' ')) {
      final parts = dateStr.split(' ');
      final date = parts[0];
      final time = parts[1];
      if (date.length == 8 && time.length == 6) {
        return '${date.substring(0, 2)}/${date.substring(2, 4)}/${date.substring(4, 8)} at ${time.substring(0, 2)}:${time.substring(2, 4)}';
      }
    }
    return dateStr;
  }

  Future<void> deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete credential?'),
        content: Text('Are you sure you want to delete ${item['platform']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final id = item['id'] ?? '';
      if (id.isNotEmpty) {
        await TotpStore.moveToRecycleBinAndDeleteByIds([id]);
        if (!mounted) return;
        Navigator.pop(context, {'action': 'deleted', 'id': id});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = item['createdAt'] ?? '';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).dialogTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: MouseWheelHorizontalScroll(
                    child: Text(item['platform'] ?? 'Unknown', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                  onPressed: deleteAccount,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Username/Email',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: MouseWheelHorizontalScroll(
                          child: SelectableText(
                            (item['username'] == null || item['username']!.isEmpty) ? '-' : item['username']!,
                            style: const TextStyle(fontSize: 16),
                            maxLines: 1,
                          ),
                        ),
                      ),
                      if (item['username'] != null && item['username']!.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () => copyToClipboard(item['username']!, 'Username'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (createdAt.isNotEmpty)
              Text(
                'Added: ${formatDateString(createdAt)}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }
}