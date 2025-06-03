import 'package:flutter/material.dart';

class CommentSectionWidget extends StatelessWidget {
  final TextEditingController controller;

  const CommentSectionWidget({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ajouter un commentaire",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: 2,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[850],
            hintText: "Laisse un commentaire...",
            hintStyle: const TextStyle(color: Colors.white54),
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white24),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
