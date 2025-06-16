// lib/pages/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../chat/presentation/paginated_message_list.dart';
import '../../chat/presentation/chat_composer.dart';
import '../../../main.dart'; // Pour AppColors
import '../data/chat_repository.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String friendName;

  const ChatScreen({
    Key? key,
    required this.conversationId,
    required this.friendName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final ChatRepository _repo = ChatRepository();

  @override
  void initState() {
    super.initState();
    _repo.markConversationRead(widget.conversationId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    // La ListView est inversée, donc on remonte vers minScrollExtent
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Fond en glass background
      backgroundColor: AppColors.glassBackground,
      appBar: AppBar(
        // On utilise glassHeader pour la barre d'app
        backgroundColor: AppColors.glassHeader,
        elevation: 1,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onBackground, // icônes (retour, appel, etc.)
        ),
        title: Text(
          widget.friendName,
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // TODO: démarrer appel audio
            },
            tooltip: 'Appel audio',
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              // TODO: démarrer appel vidéo
            },
            tooltip: 'Appel vidéo',
          ),
        ],
        bottom: PreferredSize(
          // Un fin séparateur sous la barre pour distinguer
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
          ),
        ),
      ),
      body: Column(
        children: [
          // Messages paginés (défilent vers le bas)
          Expanded(
            child: PaginatedMessageList(
              conversationId: widget.conversationId,
              scrollController: _scrollController,
              onNewMessage: () {
                _scrollToBottom();
                _repo.markConversationRead(widget.conversationId);
              },
            ),
          ),

          // Séparateur au-dessus de la zone de saisie
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
          ),

          // Zone de composition (champ de texte + bouton d’envoi)
          ChatComposer(conversationId: widget.conversationId),
        ],
      ),
    );
  }
}