import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Controller/service_provider.dart';
import 'buyer_notification_channels.dart';
import 'buyer_notification_models.dart';
import 'buyer_notification_router.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> {
  final List<BuyerNotification> _notifications = [];
  bool _isLoading = true;
  bool _isMutating = false;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNotifications());
  }

  Future<void> _loadNotifications() async {
    final serviceProvider = context.read<ServiceProvider>();
    if (!serviceProvider.isLoggedIn) {
      if (!mounted) return;
      setState(() {
        _notifications.clear();
        _unreadCount = 0;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    final rawNotifications = await serviceProvider.fetchBuyerNotifications();
    final unreadCount = await serviceProvider
        .fetchBuyerNotificationUnreadCount();
    if (!mounted) return;

    setState(() {
      _notifications
        ..clear()
        ..addAll(
          rawNotifications
              .map(BuyerNotification.fromJson)
              .toList(growable: false),
        );
      _unreadCount = unreadCount;
      _isLoading = false;
    });
  }

  Future<void> _openNotification(BuyerNotification notification) async {
    final serviceProvider = context.read<ServiceProvider>();
    if (!notification.isRead) {
      await serviceProvider.markBuyerNotificationRead(notification.id);
      await _loadNotifications();
    }
    if (!mounted) return;

    await BuyerNotificationRouter.handleWithNavigator(
      Navigator.of(context),
      BuyerNotificationRouteIntent.fromNotification(notification),
    );
  }

  Future<void> _deleteNotification(BuyerNotification notification) async {
    setState(() => _isMutating = true);
    final deleted = await context
        .read<ServiceProvider>()
        .deleteBuyerNotification(notification.id);
    if (!mounted) return;
    setState(() => _isMutating = false);
    if (!deleted) {
      _showSnackBar('Notification could not be deleted.');
      return;
    }
    await _loadNotifications();
  }

  Future<void> _markAllRead() async {
    setState(() => _isMutating = true);
    final success = await context
        .read<ServiceProvider>()
        .markAllBuyerNotificationsRead();
    if (!mounted) return;
    setState(() => _isMutating = false);
    if (!success) {
      _showSnackBar('Notifications could not be marked read.');
      return;
    }
    await _loadNotifications();
  }

  Future<void> _deleteRead() async {
    setState(() => _isMutating = true);
    final success = await context
        .read<ServiceProvider>()
        .deleteReadBuyerNotifications();
    if (!mounted) return;
    setState(() => _isMutating = false);
    if (!success) {
      _showSnackBar('Read notifications could not be deleted.');
      return;
    }
    await _loadNotifications();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final serviceProvider = context.watch<ServiceProvider>();
    final hasReadNotifications = _notifications.any(
      (notification) => notification.isRead,
    );
    final canMarkAllRead = !_isMutating && !_isLoading && _unreadCount > 0;
    final canClearRead = !_isMutating && !_isLoading && hasReadNotifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (serviceProvider.isLoggedIn) ...[
            IconButton(
              tooltip: 'Mark all read',
              onPressed: canMarkAllRead ? _markAllRead : null,
              icon: const Icon(Icons.done_all),
            ),
            IconButton(
              tooltip: 'Clear read',
              onPressed: canClearRead ? _deleteRead : null,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _isLoading || _isMutating ? null : _loadNotifications,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          if (!serviceProvider.isLoggedIn)
            _EmptyNotificationState(
              icon: Icons.lock_outline,
              title: 'Sign in required',
              message: 'Sign in to receive order and points updates.',
            )
          else if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_notifications.isEmpty)
            _EmptyNotificationState(
              icon: Icons.notifications_none,
              title: 'No notifications',
              message: 'Order status and points updates will appear here.',
            )
          else
            RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: _notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return Dismissible(
                    key: ValueKey(notification.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      await _deleteNotification(notification);
                      return false;
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: _NotificationTile(
                      notification: notification,
                      onTap: () => _openNotification(notification),
                      onDelete: () => _deleteNotification(notification),
                    ),
                  );
                },
              ),
            ),
          if (_isMutating)
            Container(
              color: Colors.black.withValues(alpha: 0.06),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  final BuyerNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final channelId = BuyerNotificationChannels.resolveChannelId(
      notification.eventType,
    );
    final isPoints = channelId == BuyerNotificationChannels.pointsUpdates;
    final accentColor = isPoints ? Colors.amber.shade800 : primary;

    return Material(
      color: notification.isRead
          ? Colors.grey.shade50
          : accentColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: notification.isRead
                  ? Colors.grey.shade300
                  : accentColor.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPoints ? Icons.star_border : Icons.receipt_long_outlined,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.displayTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!notification.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.displayBody,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatNotificationTime(notification.createdAt),
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.48),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                color: Colors.red.shade600,
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNotificationState extends StatelessWidget {
  const _EmptyNotificationState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: primary.withValues(alpha: 0.72)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black.withValues(alpha: 0.62)),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatNotificationTime(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return '';
  final local = parsed.toLocal();
  final now = DateTime.now();
  final difference = now.difference(local);
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inHours < 1) return '${difference.inMinutes} min ago';
  if (difference.inDays < 1) return '${difference.inHours} hr ago';
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
