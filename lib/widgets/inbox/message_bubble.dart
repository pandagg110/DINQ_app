import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/message_models.dart';
import '../common/base_page.dart';

/// 消息气泡组件
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
    this.showAvatar = false,
    this.senderName,
    this.senderAvatar,
    this.isRead = false,
  });

  final Message message;
  final bool isOwnMessage;
  final bool showAvatar;
  final String? senderName;
  final String? senderAvatar;
  final bool isRead;

  String _formatTime(String timestamp) {
    final date = DateTime.tryParse(timestamp);
    if (date == null) return '';
    // 聊天气泡只显示时间（日期由分割线提供），与 H5 一致
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (message.isRecalled) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Message recalled',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 对方头像（群聊时显示）
          if (!isOwnMessage && showAvatar)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[200],
                backgroundImage: senderAvatar != null && senderAvatar!.isNotEmpty
                    ? NetworkImage(senderAvatar!)
                    : null,
                child: senderAvatar == null || senderAvatar!.isEmpty
                    ? const Icon(Icons.person, size: 20, color: Colors.grey)
                    : null,
              ),
            ),

          // 消息内容区域
          Flexible(
            child: Column(
              crossAxisAlignment: isOwnMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 群聊发送者名称
                if (!isOwnMessage && showAvatar && senderName != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      senderName!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),

                // 消息气泡
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: message.messageType == MessageType.emoji
                      ? const EdgeInsets.all(4)
                      : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: message.messageType == MessageType.emoji
                        ? Colors.transparent
                        : isOwnMessage
                            ? const Color(0xFF1487FA)
                            : const Color(0xFFF1F1F1),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isOwnMessage ? 16 : 4),
                      bottomRight: Radius.circular(isOwnMessage ? 4 : 16),
                    ),
                  ),
                  child: _buildContent(),
                ),

                // 时间戳和已读状态
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isOwnMessage && (message.status == MessageStatus.read || isRead))
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: SvgPicture.asset(
                            'assets/icons/sent.svg',
                            width: 14,
                            height: 14,
                          ),
                        ),
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 自己的消息 - 群聊时右侧占位
          if (isOwnMessage && showAvatar)
            const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (message.messageType) {
      case MessageType.emoji:
        return Text(
          message.content,
          style: const TextStyle(fontSize: 36),
        );

      case MessageType.image:
        final imageUrl = message.metadata?['image_url']?.toString();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildTextContent(),
              ),
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: NetworkImageView(
                  imageUrl: imageUrl,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        );

      case MessageType.text:
      default:
        return _buildTextContent();
    }
  }

  Widget _buildTextContent() {
    return Text(
      message.content,
      style: TextStyle(
        fontSize: 15,
        height: 1.5,
        color: isOwnMessage ? Colors.white : const Color(0xFF111827),
      ),
    );
  }
}
