import 'package:flutter/material.dart';

Future<void> showMessage(BuildContext context, String caption, String body) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(caption),
        content: SingleChildScrollView(
          child: Text(body),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Dismiss'),
            ),
          ),
        ],
      );
    },
  );
}

class BoilerplateDialog extends StatelessWidget {
  // from https://github.com/treeplate/helpful_widgets/blob/main/boilerplate-dialog.dart

  const BoilerplateDialog(
      {super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(title),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
