import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_snackbars.dart';

class PassphraseGeneratorDialog extends StatefulWidget {
  const PassphraseGeneratorDialog({super.key});

  @override
  State<PassphraseGeneratorDialog> createState() =>
      PassphraseGeneratorDialogState();
}

class PassphraseGeneratorDialogState extends State<PassphraseGeneratorDialog> {
  int wordCount = 4;
  String selectedSeparator = '-';
  String generatedPassphrase = '';
  List<String> wordPool = [];
  bool isLoading = true;

  final List<String> separators = ['-', '_', '.', '*', ' '];

  @override
  void initState() {
    super.initState();
    loadWordlist();
  }

  Future<void> loadWordlist() async {
    try {
      final fileContent = await rootBundle.loadString(
        'assets/passphrase/wordlist.txt',
      );
      final words = fileContent
          .split('\n')
          .map((w) => w.trim())
          .where((w) => w.isNotEmpty)
          .toList();

      setState(() {
        wordPool = words;
        isLoading = false;
      });
      generatePassphrase();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      wordPool = ['error', 'loading', 'wordlist', 'file', 'missing'];
      generatePassphrase();
    }
  }

  void generatePassphrase() {
    if (wordPool.isEmpty) return;

    final random = Random.secure();
    List<String> selectedWords = [];

    for (int i = 0; i < wordCount; i++) {
      final randomIndex = random.nextInt(wordPool.length);
      selectedWords.add(wordPool[randomIndex]);
    }

    setState(() {
      generatedPassphrase = selectedWords.join(selectedSeparator);
    });
  }

  void copyToClipboard() {
    Clipboard.setData(ClipboardData(text: generatedPassphrase));
    AppSnackBars.showCustomSnackBar(
        context: context, message: 'Passphrase copied to clipboard', textColor: Colors.blue);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      title: const Center(child: Text('Passphrase Generator', style: TextStyle(fontWeight: FontWeight.bold))),
      content: isLoading
          ? const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'Say Good Bye to Passwords',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Say Hello to Passphrases',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Easy to remember • Harder to crack',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.maxFinite,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? theme.cardColor : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? theme.dividerColor
                            : Colors.grey[400]!,
                      ),
                    ),
                    child: SelectableText(
                      generatedPassphrase,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: copyToClipboard,
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy'),
                      ),
                      TextButton.icon(
                        onPressed: generatePassphrase,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Regenerate'),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Number of words: $wordCount', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: wordCount.toDouble(),
                          min: 3,
                          max: 8,
                          divisions: 5,
                          label: wordCount.toString(),
                          onChanged: (value) {
                            setState(() {
                              wordCount = value.toInt();
                            });
                            generatePassphrase();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Separator:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ToggleButtons(
                    isSelected: separators
                        .map((s) => s == selectedSeparator)
                        .toList(),
                    onPressed: (index) {
                      setState(() {
                        selectedSeparator = separators[index];
                      });
                      generatePassphrase();
                    },
                    borderRadius: BorderRadius.circular(8),
                    constraints: const BoxConstraints(
                      minWidth: 45,
                      minHeight: 40,
                    ),
                    children: separators.map((s) {
                      return Text(
                        s == ' ' ? ' Space ' : s,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}