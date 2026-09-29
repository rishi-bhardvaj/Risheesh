import 'package:flutter/material.dart';

/// Full-screen dialog for pasting resume text. Returns the text, or null.
Future<String?> showPasteResumeDialog(BuildContext context) =>
    Navigator.of(context).push<String>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const _PasteResumePage()));

class _PasteResumePage extends StatefulWidget {
  const _PasteResumePage();

  @override
  State<_PasteResumePage> createState() => _PasteResumePageState();
}

class _PasteResumePageState extends State<_PasteResumePage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = _controller.text.trim().isEmpty ? 0 : _controller.text.trim().split(RegExp(r'\s+')).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paste resume'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: words < 30 ? null : () => Navigator.pop(context, _controller.text),
              child: const Text('Parse'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Paste the full text of your resume or CV. Keep section headings like Experience, Skills and Education on their own lines.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: true,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(hintText: 'Jane Doe\nSenior Software Engineer\njane@example.com …'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 8),
            Text(words < 30 ? '$words words · paste at least 30' : '$words words', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
