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
              onPressed: () { Navigator.pop(context); },
              child: const Text('Dismiss'),
            ),
          ),
        ],
      );
    },
  );
}