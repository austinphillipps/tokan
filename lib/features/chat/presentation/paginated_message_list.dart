// lib/features/chat/presentation/paginated_message_list.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/chat_repository.dart';
import 'message_bubble.dart';

class PaginatedMessageList extends StatefulWidget {
  final String conversationId;
  final int batchSize;
  final ScrollController? scrollController;
  final VoidCallback? onNewMessage;

  const PaginatedMessageList({
    Key? key,
    required this.conversationId,
    this.batchSize = 20,
    this.scrollController,
    this.onNewMessage,
  }) : super(key: key);

  @override
  _PaginatedMessageListState createState() => _PaginatedMessageListState();
}

class _PaginatedMessageListState extends State<PaginatedMessageList> {
  final ChatRepository _repo = ChatRepository();
  late final ScrollController _ctrl;
  List<QueryDocumentSnapshot> _allDocs = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;
  StreamSubscription<List<QueryDocumentSnapshot>>? _sub;

  @override
  void initState() {
    super.initState();
    _ctrl = widget.scrollController ?? ScrollController();
    _loadInitial();
    _ctrl.addListener(_onScroll);
  }

  void _loadInitial() {
    if (_isLoading) return;
    _isLoading = true;
    _sub = _repo
        .messagesStream(
      conversationId: widget.conversationId,
      limit: widget.batchSize,
    )
        .listen((docs) {
      setState(() {
        _allDocs = docs;
        _hasMore = docs.length == widget.batchSize;
        _lastDoc = docs.isNotEmpty ? docs.last : null;
        _isLoading = false;
      });
      widget.onNewMessage?.call();
    });
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;
    final more = await _repo
        .messagesStream(
      conversationId: widget.conversationId,
      limit: widget.batchSize,
      startAfter: _lastDoc,
    )
        .first;
    setState(() {
      if (more.isEmpty) {
        _hasMore = false;
      } else {
        _allDocs.addAll(more);
        _lastDoc = more.last;
      }
      _isLoading = false;
    });
    widget.onNewMessage?.call();
  }

  void _onScroll() {
    if (_ctrl.position.pixels >= _ctrl.position.maxScrollExtent - 100) {
      _loadMore();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    if (widget.scrollController == null) {
      _ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          controller: _ctrl,
          reverse: true,
          itemCount: _allDocs.length + (_hasMore && _allDocs.isNotEmpty ? 1 : 0),
          itemBuilder: (ctx, i) {
            if (_hasMore && _allDocs.isNotEmpty && i == _allDocs.length) {
              // Spinner pour pagination
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final doc = _allDocs[i];
            return MessageBubble(
              messageDoc: doc,
              conversationId: widget.conversationId,
            );
          },
        ),

        // Loader plein écran pour le premier chargement
        if (_isLoading && _allDocs.isEmpty)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
