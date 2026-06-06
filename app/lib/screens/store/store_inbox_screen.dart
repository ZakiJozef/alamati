import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../models/message.dart';
import '../../services/store_chat_service.dart';
import 'store_chat_room_screen.dart';

// Helper class for consistent colors
class AppColors {
  static Color get primary => AppTheme.primaryColor;
}

/// Store inbox screen - shows all customer conversations for a store
class StoreInboxScreen extends StatefulWidget {
  final int storeId;
  final String storeName;

  const StoreInboxScreen({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  @override
  State<StoreInboxScreen> createState() => _StoreInboxScreenState();
}

class _StoreInboxScreenState extends State<StoreInboxScreen> {
  final StoreChatService _chatService = StoreChatService();
  List<StoreConversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    final conversations = await _chatService.getStoreConversations(widget.storeId);
    setState(() {
      _conversations = conversations;
      _isLoading = false;
    });
  }

  void _openChat(StoreConversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreChatRoomScreen(
          storeId: widget.storeId,
          storeName: widget.storeName,
          customerId: conversation.customerId,
          customerName: conversation.displayName,
          customerImage: conversation.customerProfilePic,
        ),
      ),
    ).then((_) => _loadConversations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.storeName} - Inbox'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      return _ConversationTile(
                        conversation: conversation,
                        onTap: () => _openChat(conversation),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customer messages will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final StoreConversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.primary.withOpacity(0.1),
        backgroundImage: conversation.customerProfilePic != null
            ? CachedNetworkImageProvider(conversation.customerProfilePic!)
            : null,
        child: conversation.customerProfilePic == null
            ? Text(
                conversation.displayName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.displayName,
              style: TextStyle(
                fontWeight: conversation.hasUnread ? FontWeight.bold : FontWeight.w600,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation.lastMessageTime != null)
            Text(
              _formatTime(conversation.lastMessageTime!),
              style: TextStyle(
                fontSize: 12,
                color: conversation.hasUnread ? AppColors.primary : Colors.grey[500],
                fontWeight: conversation.hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          if (conversation.lastMessageSenderAsStore)
            Container(
              margin: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.reply,
                size: 14,
                color: Colors.grey[500],
              ),
            ),
          Expanded(
            child: Text(
              conversation.lastMessageContent ?? 'No messages',
              style: TextStyle(
                color: conversation.hasUnread ? Colors.black87 : Colors.grey[600],
                fontWeight: conversation.hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: conversation.hasUnread
          ? Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 7) {
      return '${time.day}/${time.month}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
