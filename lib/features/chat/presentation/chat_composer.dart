// lib/features/chat/presentation/chat_composer.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';

import '../data/chat_repository.dart';

class ChatComposer extends StatefulWidget {
  final String conversationId;
  const ChatComposer({Key? key, required this.conversationId}) : super(key: key);

  @override
  _ChatComposerState createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final ChatRepository _repo = ChatRepository();
  final TextEditingController _controller = TextEditingController();
  bool _showEmoji = false;
  Timer? _typingTimer;

  @override
  void dispose() {
    _controller.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged(String text) {
    _repo.setTyping(widget.conversationId, true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 1), () {
      _repo.setTyping(widget.conversationId, false);
    });
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _repo.setTyping(widget.conversationId, false);
    await _repo.sendText(
      conversationId: widget.conversationId,
      text: text,
    );
  }

  Future<void> _pickAndSendAttachment() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;
    final file = File(result.files.single.path!);
    final ext = result.files.single.extension?.toLowerCase() ?? '';
    String type;
    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) {
      type = 'image';
    } else if (['mp3', 'wav', 'm4a'].contains(ext)) {
      type = 'audio';
    } else {
      type = 'file';
    }
    await _repo.sendFile(
      conversationId: widget.conversationId,
      file: file,
      type: type,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showEmoji)
          SizedBox(
            height: 250,
            child: EmojiPicker(
              onEmojiSelected: (_, emoji) {
                _controller.text += emoji.emoji;
                _onTextChanged(_controller.text);
              },
            ),
          ),
        Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.emoji_emotions,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              onPressed: () => setState(() => _showEmoji = !_showEmoji),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Écrivez un message…',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black38,
                  ),
                  border: InputBorder.none,
                ),
                onChanged: _onTextChanged,
                onSubmitted: (_) => _sendText(),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.attach_file,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              onPressed: _pickAndSendAttachment,
            ),
            IconButton(
              icon: Icon(
                Icons.send,
                color: Colors.blueAccent,
              ),
              onPressed: _sendText,
            ),
          ],
        ),
      ],
    );
  }
}
