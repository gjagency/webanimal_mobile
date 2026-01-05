import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum NotificationType { like, comment, follow, adoption, lost, report }

class NotificationItem {
  final String username;
  final String userAvatar;
  final NotificationType type;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? postImage;

  NotificationItem({
    required this.username,
    required this.userAvatar,
    required this.type,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.postImage,
  });
}

class PageAccountNotifications extends StatefulWidget {
  const PageAccountNotifications({super.key});

  @override
  State<PageAccountNotifications> createState() =>
      _PageAccountNotificationsState();
}

class _PageAccountNotificationsState extends State<PageAccountNotifications> {
  final List<NotificationItem> notifications = [
    NotificationItem(
      username: 'maria_rodriguez',
      userAvatar: 'https://i.pravatar.cc/150?img=1',
      type: NotificationType.comment,
      message: 'comentó en tu publicación sobre Max',
      timestamp: DateTime.now().subtract(Duration(minutes: 5)),
      isRead: false,
      postImage: 'https://images.unsplash.com/photo-1543466835-00a7907e9de1',
    ),
    NotificationItem(
      username: 'refugio_patitas',
      userAvatar: 'https://i.pravatar.cc/150?img=2',
      type: NotificationType.like,
      message: 'le gustó tu publicación',
      timestamp: DateTime.now().subtract(Duration(hours: 1)),
      isRead: false,
      postImage: 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e',
    ),
    NotificationItem(
      username: 'carlos_mendez',
      userAvatar: 'https://i.pravatar.cc/150?img=3',
      type: NotificationType.follow,
      message: 'comenzó a seguirte',
      timestamp: DateTime.now().subtract(Duration(hours: 3)),
      isRead: false,
    ),
    NotificationItem(
      username: 'vet_saludable',
      userAvatar: 'https://i.pravatar.cc/150?img=4',
      type: NotificationType.adoption,
      message: 'está interesado en adoptar a Luna',
      timestamp: DateTime.now().subtract(Duration(hours: 5)),
      isRead: true,
    ),
    NotificationItem(
      username: 'ana_garcia',
      userAvatar: 'https://i.pravatar.cc/150?img=5',
      type: NotificationType.comment,
      message: 'comentó: "Hermoso gatito! 😍"',
      timestamp: DateTime.now().subtract(Duration(days: 1)),
      isRead: true,
      postImage: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba',
    ),
    NotificationItem(
      username: 'hogar_perruno',
      userAvatar: 'https://i.pravatar.cc/150?img=6',
      type: NotificationType.report,
      message: 'agradeció tu reporte de maltrato',
      timestamp: DateTime.now().subtract(Duration(days: 2)),
      isRead: true,
    ),
  ];

  void _markAsRead(int index) {
    setState(() {
      notifications[index] = NotificationItem(
        username: notifications[index].username,
        userAvatar: notifications[index].userAvatar,
        type: notifications[index].type,
        message: notifications[index].message,
        timestamp: notifications[index].timestamp,
        isRead: true,
        postImage: notifications[index].postImage,
      );
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (int i = 0; i < notifications.length; i++) {
        notifications[i] = NotificationItem(
          username: notifications[i].username,
          userAvatar: notifications[i].userAvatar,
          type: notifications[i].type,
          message: notifications[i].message,
          timestamp: notifications[i].timestamp,
          isRead: true,
          postImage: notifications[i].postImage,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Notificaciones',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            if (unreadCount > 0)
              Text(
                '$unreadCount nuevas',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Marcar todas',
                style: TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No tienes notificaciones',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return NotificationCard(
                  notification: notifications[index],
                  onTap: () => _markAsRead(index),
                );
              },
            ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  IconData _getTypeIcon() {
    switch (notification.type) {
      case NotificationType.like:
        return Icons.favorite;
      case NotificationType.comment:
        return Icons.chat_bubble;
      case NotificationType.follow:
        return Icons.person_add;
      case NotificationType.adoption:
        return Icons.pets;
      case NotificationType.lost:
        return Icons.search;
      case NotificationType.report:
        return Icons.report;
    }
  }

  Color _getTypeColor() {
    switch (notification.type) {
      case NotificationType.like:
        return Colors.red;
      case NotificationType.comment:
        return Colors.blue;
      case NotificationType.follow:
        return Colors.purple;
      case NotificationType.adoption:
        return Colors.green;
      case NotificationType.lost:
        return Colors.orange;
      case NotificationType.report:
        return Colors.red[700]!;
    }
  }

  String _getTimeAgo() {
    final difference = DateTime.now().difference(notification.timestamp);
    if (difference.inDays > 0) {
      return 'hace ${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'hace ${difference.inMinutes}m';
    } else {
      return 'ahora';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Colors.purple[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead
                ? Colors.transparent
                : Colors.purple[100]!,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar con badge
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.pink],
                    ),
                  ),
                  padding: EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(notification.userAvatar),
                    backgroundColor: Colors.white,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(_getTypeIcon(), size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(width: 12),
            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.black, fontSize: 14),
                      children: [
                        TextSpan(
                          text: notification.username,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' ${notification.message}'),
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _getTimeAgo(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            // Thumbnail de post (si existe)
            if (notification.postImage != null) ...[
              SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  notification.postImage!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: Icon(Icons.pets, color: Colors.grey),
                    );
                  },
                ),
              ),
            ],
            // Indicador no leído
            if (!notification.isRead) ...[
              SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.purple,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
