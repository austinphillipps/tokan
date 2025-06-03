// lib/features/chat/presentation/reactions_picker.dart

import 'package:flutter/material.dart';

class ReactionsPicker extends StatelessWidget {
  final void Function(String emoji) onReact;
  const ReactionsPicker({Key? key, required this.onReact}) : super(key: key);

  static const _emojis = ['👍', '❤️', '😂', '😮', '😢', '👏'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: _emojis.map((e) {
          return IconButton(
            splashRadius: 24,
            onPressed: () {
              onReact(e);
              Navigator.of(context).pop();
            },
            icon: Text(e, style: const TextStyle(fontSize: 28)),
          );
        }).toList(),
      ),
    );
  }
}
