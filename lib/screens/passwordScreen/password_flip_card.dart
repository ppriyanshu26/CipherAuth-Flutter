import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'add_password_screen.dart';
import '../../utils/crypto/password_store.dart';
import '../../widgets/app_snackbars.dart';

class MouseWheelHorizontalScroll extends StatefulWidget {
  final Widget child;
  
  const MouseWheelHorizontalScroll({super.key, required this.child});
  @override
  State<MouseWheelHorizontalScroll> createState() => MouseWheelHorizontalScrollState();
}

class MouseWheelHorizontalScrollState
    extends State<MouseWheelHorizontalScroll> {
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
      child: SingleChildScrollView(controller: controller, scrollDirection: Axis.horizontal, child: widget.child),
    );
  }
}

class PasswordFlipCard extends StatefulWidget {
  final Map<String, String> passwordItem;

  const PasswordFlipCard({super.key, required this.passwordItem});

  @override
  State<PasswordFlipCard> createState() => PasswordFlipCardState();
}

class PasswordFlipCardState extends State<PasswordFlipCard> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Map<String, String> item;
  bool obscurePassword = true;
  final ScrollController notesScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    item = widget.passwordItem;
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    notesScrollController.dispose();
    super.dispose();
  }

  void flipCard() {
    if (controller.isCompleted) {
      controller.reverse();
    } else {
      controller.forward();
    }
  }

  void copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    AppSnackBars.showCustomSnackBar(context: context,  message: '$label copied to clipboard',  textColor: Colors.blue);
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

  Future<void> editPassword() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddPasswordScreen(existingPassword: item)),
    );
    if (result is String) {
      final list = await PasswordStore.load();
      final updatedItem = list.firstWhere((e) => e['id'] == result, orElse: () => item);
      setState(() => item = updatedItem);
    }
  }

  Future<void> deletePassword() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Password?'),
        content: Text('Are you sure you want to delete ${item['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await PasswordStore.moveToRecycleBinAndDeleteById(item['id'] ?? '');
      if (!mounted) return;
      Navigator.pop(context, {'action': 'deleted', 'id': item['id']});
    }
  }

  Widget buildRow(String title, String value, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: MouseWheelHorizontalScroll(
                  child: SelectableText(
                    isPassword && obscurePassword ? '•'*value.length : value,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: isPassword ? 'monospace' : null,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
              if (isPassword)
                IconButton(
                  icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off, size: 20),
                  onPressed: () => setState(() => obscurePassword = !obscurePassword),
                  tooltip: obscurePassword ? 'Show Password' : 'Hide Password',
                  visualDensity: VisualDensity.compact,
                ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () => copyToClipboard(value, title),
                tooltip: 'Copy Field',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildFront() {
    final updatedAt = item['updatedAt'] ?? item['createdAt'] ?? '';

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).dialogTheme.backgroundColor?? Theme.of(context).colorScheme.surface,
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
                  child: Text(item['name'] ?? 'Unknown', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: editPassword,
                    tooltip: 'Edit Password Details',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                    onPressed: deletePassword,
                    tooltip: 'Delete Password',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              )
            ],
          ),
          const Divider(),
          buildRow('Username', item['username'] ?? ''),
          buildRow('Password', item['password'] ?? '', isPassword: true),
          buildRow('URL / Domain', item['domain'] ?? ''),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text('Updated: ${formatDateString(updatedAt)}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              ),
              IconButton(
                icon: const Icon(Icons.flip_camera_android),
                color: Theme.of(context).colorScheme.secondary,
                onPressed: flipCard,
                tooltip: 'Flip to Notes',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildBack() {
    final notes = item['notes'] ?? '';

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: 400,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).dialogTheme.backgroundColor?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Notes',
                style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
              ),
              if (notes.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => copyToClipboard(notes, 'Notes'),
                  tooltip: 'Copy Notes',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const Divider(),
          Expanded(
            child: Scrollbar(
              controller: notesScrollController,
              thumbVisibility: true,
              thickness: 6,
              radius: const Radius.circular(10),
              child: SingleChildScrollView(
                controller: notesScrollController,
                padding: const EdgeInsets.only(right: 12.0),
                child: notes.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40.0),
                          child: Text('No notes saved.',
                            style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                          ),
                        ),
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: SelectableText(
                          notes,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: IconButton(
              icon: const Icon(Icons.flip_camera_android),
              color: Theme.of(context).colorScheme.secondary,
              onPressed: flipCard,
              tooltip: 'Flip to Front',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final angle = controller.value * math.pi;
          final isFrontVisible = angle <= math.pi / 2;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isFrontVisible
                ? buildFront()
                : Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: buildBack(),
                  ),
          );
        },
      ),
    );
  }
}