// lib/features/projects/widgets/discussion_screen.dart

import 'package:flutter/material.dart';
import '../../chat/presentation/paginated_message_list.dart';
import '../../chat/presentation/chat_composer.dart';

/// Écran de discussion de groupe pour un projet,
/// basé sur projectId comme conversationId.
class ProjectDiscussionScreen extends StatefulWidget {
  final String projectId;

  const ProjectDiscussionScreen({
    Key? key,
    required this.projectId,
  }) : super(key: key);

  @override
  _ProjectDiscussionScreenState createState() =>
      _ProjectDiscussionScreenState();
}

class _ProjectDiscussionScreenState extends State<ProjectDiscussionScreen> {
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Couleur de fond adaptée au thème :
    // - En clair : couleur de surface (blanc)
    // - En sombre : couleur de background (gris foncé)
    final backgroundColor = theme.scaffoldBackgroundColor;

    // Couleur de séparation (divider) depuis le ColorScheme
    final dividerColor = theme.colorScheme.onBackground.withOpacity(0.3);

    return Container(
      // On positionne le fond global du panneau de discussion ici
      color: backgroundColor,
      child: Column(
        children: [
          // Liste paginée des messages
          Expanded(
            child: PaginatedMessageList(
              conversationId: widget.projectId,
              scrollController: _scrollController,
              onNewMessage: _scrollToBottom,
            ),
          ),

          // Séparateur : on utilise la couleur depuis le thème
          Divider(height: 1, color: dividerColor),

          // Zone de saisie
          // On encapsule ChatComposer dans un Container dont le fond
          // reprend backgroundColor pour éviter le texte blanc sur fond blanc
          Container(
            color: backgroundColor,
            child: ChatComposer(conversationId: widget.projectId),
          ),
        ],
      ),
    );
  }
}
