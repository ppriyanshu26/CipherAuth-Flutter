import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

const EdgeInsets _supportTilePadding = EdgeInsets.fromLTRB(16, 0, 16, 16);

Widget supportTileData(
  List<Widget> children, {
  EdgeInsets padding = _supportTilePadding,
}) {
  return Padding(
    padding: padding,
    child: Align(
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );
}

Widget supportPolicySection(String title, String content) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SelectableText(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      const SizedBox(height: 4),
      SelectableText(content, style: const TextStyle(fontSize: 12)),
    ],
  );
}

Widget supportLinkButton(State<StatefulWidget> state, String url) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SelectableText(url, style: const TextStyle(color: Colors.blue)),
      const SizedBox(height: 6),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => supportCopyLink(state, url),
            child: const Text('Copy'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => supportOpenLink(state, url),
            child: const Text('Open'),
          ),
        ],
      ),
    ],
  );
}

Future<void> supportCopyLink(State<StatefulWidget> state, String url) async {
  await Clipboard.setData(ClipboardData(text: url));
  if (!state.mounted) return;
  ScaffoldMessenger.of(
    state.context,
  ).showSnackBar(const SnackBar(content: Text('Link copied to clipboard.')));
}

Future<void> supportOpenLink(State<StatefulWidget> state, String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri)) {
    if (!state.mounted) return;
    ScaffoldMessenger.of(
      state.context,
    ).showSnackBar(const SnackBar(content: Text('Could not open the link.')));
  }
}
