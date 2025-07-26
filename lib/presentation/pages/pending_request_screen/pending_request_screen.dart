// improved_pending_request_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pending_request_screen_provider.dart';

class PendingRequestScreen extends ConsumerWidget {
  const PendingRequestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pendingRequestProvider);
    final notifier = ref.read(pendingRequestProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: _buildBody(context, state, notifier),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'Friend Requests',
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 1,
      iconTheme: const IconThemeData(color: AppColors.primary),
      actions: [
        Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(pendingRequestProvider);
            if (state.lastUpdated != null) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    'Updated ${_formatLastUpdated(state.lastUpdated!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, PendingRequestState state, PendingRequestNotifier notifier) {
    return RefreshIndicator(
      onRefresh: () => notifier.loadPendingRequests(isRefresh: true),
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          // Error banner
          if (state.error != null)
            SliverToBoxAdapter(
              child: _ErrorBanner(
                error: state.error!,
                onDismiss: notifier.clearError,
                onRetry: () => notifier.loadPendingRequests(),
              ),
            ),
          
          // Loading indicator
          if (state.isLoading && state.pendingRequests.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          
          // Empty state
          else if (state.pendingRequests.isEmpty && !state.isLoading)
            SliverFillRemaining(child: _buildEmptyState(context))
          
          // Request list
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.builder(
                itemCount: state.pendingRequests.length,
                itemBuilder: (context, index) {
                  final request = state.pendingRequests[index];
                  return _PendingRequestCard(
                    key: ValueKey(request['id']),
                    request: request,
                    isProcessing: state.isRequestProcessing(request['id']),
                    onTap: () => _showProfileBottomSheet(context, request, notifier),
                    onAccept: () => notifier.respondToRequest(request['id'], 'accepted'),  // ✅ Correct
                    onReject: () => notifier.respondToRequest(request['id'], 'rejected'),  // ✅ Correct
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const _EmptyState();
  }

  void _showProfileBottomSheet(
    BuildContext context,
    Map<String, dynamic> request,
    PendingRequestNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProfileBottomSheet(
        request: request,
        notifier: notifier,
      ),
    );
  }

  String _formatLastUpdated(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    
    if (difference.inMinutes < 1) return 'now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}

// Extracted widgets for better organization
class _ErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback onDismiss;
  final VoidCallback onRetry;

  const _ErrorBanner({
    required this.error,
    required this.onDismiss,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade800,
                  ),
                ),
                Text(
                  error,
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close),
            color: Colors.red.shade600,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accent.withOpacity(0.3),
                  AppColors.primary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No pending requests',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'All caught up! No friend requests at the moment.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final bool isProcessing;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _PendingRequestCard({
    super.key,
    required this.request,
    required this.isProcessing,
    required this.onTap,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    // Parse sender info from API structure
    final senderInfo = request['sender_info'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isProcessing ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildAvatar(senderInfo),
                    const SizedBox(width: 16),
                    Expanded(child: _buildUserInfo(senderInfo, context)),
                    if (!isProcessing) _buildTapIndicator(),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> senderInfo) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: CircleAvatar(
        radius: 28,
        backgroundImage: senderInfo['profile_pic'] != null && 
                         senderInfo['profile_pic'].toString().isNotEmpty
            ? NetworkImage(senderInfo['profile_pic'])
            : null,
        backgroundColor: AppColors.accent.withOpacity(0.2),
        child: senderInfo['profile_pic'] == null || 
                senderInfo['profile_pic'].toString().isEmpty
            ? const Icon(Icons.person, color: AppColors.primary, size: 28)
            : null,
      ),
    );
  }

  Widget _buildUserInfo(Map<String, dynamic> senderInfo, BuildContext context) {
    // Build display name from name and surname
    final firstName = senderInfo['name']?.toString() ?? '';
    final lastName = senderInfo['surname']?.toString() ?? '';
    final displayName = '$firstName $lastName'.trim();
    final username = senderInfo['username']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayName.isNotEmpty ? displayName : username ?? 'Unknown User',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        if (username != null && username.isNotEmpty)
          Text(
            '@$username',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        const SizedBox(height: 4),
        Text(
          _formatTimeAgo(request['created_at']),
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTapIndicator() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.touch_app,
        color: AppColors.primary,
        size: 20,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            onPressed: isProcessing ? null : onReject,
            isLoading: isProcessing,
            label: 'Reject',
            icon: Icons.close,
            style: _ActionButtonStyle.outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            onPressed: isProcessing ? null : onAccept,
            isLoading: isProcessing,
            label: 'Accept',
            icon: Icons.check,
            style: _ActionButtonStyle.filled,
          ),
        ),
      ],
    );
  }

  String _formatTimeAgo(String? timestamp) {
    if (timestamp == null) return 'Recently';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) return '${difference.inDays}d ago';
      if (difference.inHours > 0) return '${difference.inHours}h ago';
      if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
      return 'Just now';
    } catch (e) {
      return 'Recently';
    }
  }
}

// Enhanced action button component
enum _ActionButtonStyle { filled, outlined }

class _ActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;
  final IconData icon;
  final _ActionButtonStyle style;

  const _ActionButton({
    required this.onPressed,
    required this.isLoading,
    required this.label,
    required this.icon,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final isFilled = style == _ActionButtonStyle.filled;
    
    return Container(
      decoration: isFilled
          ? BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(12),
            )
          : BoxDecoration(
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(12),
            ),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isFilled ? Colors.white : Colors.red,
                ),
              )
            : Icon(
                icon,
                color: isFilled ? Colors.white : Colors.red,
              ),
        label: Text(
          label,
          style: TextStyle(
            color: isFilled ? Colors.white : Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// Enhanced bottom sheet for profile details
class _ProfileBottomSheet extends ConsumerWidget {
  final Map<String, dynamic> request;
  final PendingRequestNotifier notifier;

  const _ProfileBottomSheet({
    required this.request,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Parse sender info from API structure
    final senderInfo = request['sender_info'] as Map<String, dynamic>? ?? {};
    
    // Get user identifier for blocking/unblocking
    final userIdentifier = senderInfo['uuid'] ?? senderInfo['username'];
    final isBlocked = userIdentifier != null ? notifier.isUserBlocked(userIdentifier) : false;
    
    final state = ref.watch(pendingRequestProvider);
    final isProcessing = state.isRequestProcessing(request['id']);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  _buildProfileHeader(senderInfo, isBlocked),
                  const SizedBox(height: 32),
                  if (senderInfo['bio'] != null && senderInfo['bio'].toString().isNotEmpty) ...[
                    _buildBioSection(senderInfo['bio']),
                    const SizedBox(height: 24),
                  ],
                  _buildRequestDetails(),
                  const SizedBox(height: 24),
                  _buildUserDetails(senderInfo),
                  const SizedBox(height: 32),
                  _buildActionButtons(context, isBlocked, isProcessing),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> senderInfo, bool isBlocked) {
    // Build display name from name and surname
    final firstName = senderInfo['name']?.toString() ?? '';
    final lastName = senderInfo['surname']?.toString() ?? '';
    final displayName = '$firstName $lastName'.trim();
    final username = senderInfo['username']?.toString();

    return Center(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(60),
              border: Border.all(color: AppColors.border, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundImage: senderInfo['profile_pic'] != null && 
                               senderInfo['profile_pic'].toString().isNotEmpty
                  ? NetworkImage(senderInfo['profile_pic'])
                  : null,
              backgroundColor: AppColors.accent.withOpacity(0.2),
              child: senderInfo['profile_pic'] == null || 
                      senderInfo['profile_pic'].toString().isEmpty
                  ? const Icon(Icons.person, size: 40, color: AppColors.primary)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            displayName.isNotEmpty ? displayName : username ?? 'Unknown User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          if (username != null && username.isNotEmpty)
            Text(
              '@$username',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          if (isBlocked) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Text(
                'Blocked',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBioSection(String bio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accent.withOpacity(0.1),
                AppColors.primary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            bio,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserDetails(Map<String, dynamic> senderInfo) {
    final details = <String, String>{};
    
    if (senderInfo['email'] != null && senderInfo['email'].toString().isNotEmpty) {
      details['Email'] = senderInfo['email'];
    }
    
    if (senderInfo['date_of_birth'] != null && senderInfo['date_of_birth'].toString().isNotEmpty) {
      details['Date of Birth'] = senderInfo['date_of_birth'];
    }
    
    if (senderInfo['gender'] != null && senderInfo['gender'].toString().isNotEmpty) {
      details['Gender'] = senderInfo['gender'];
    }

    if (details.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accent.withOpacity(0.1),
                AppColors.primary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: details.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      '${entry.key}:',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Request Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accent.withOpacity(0.1),
                AppColors.primary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule, size: 20, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Sent ${_formatTimeAgo(request['created_at'])}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Status: ${request['status']?.toString().toUpperCase() ?? 'PENDING'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isBlocked, bool isProcessing) {
    final username = request['sender_info']?['username']?.toString();
    
    if (isBlocked) {
      return SizedBox(
        width: double.infinity,
        child: _ActionButton(
          onPressed: isProcessing ? null : () {
            Navigator.of(context).pop();
            if (username != null) {
              notifier.unblockUser(username);
            }
          },
          isLoading: isProcessing,
          label: 'Unblock User',
          icon: Icons.person_add,
          style: _ActionButtonStyle.filled,
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                onPressed: isProcessing ? null : () {
                  Navigator.of(context).pop();
                  notifier.respondToRequest(request['id'], 'rejected');
                },
                isLoading: isProcessing,
                label: 'Reject',
                icon: Icons.close,
                style: _ActionButtonStyle.outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                onPressed: isProcessing ? null : () {
                  Navigator.of(context).pop();
                  notifier.respondToRequest(request['id'], 'accepted');
                },
                isLoading: isProcessing,
                label: 'Accept',
                icon: Icons.check,
                style: _ActionButtonStyle.filled,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isProcessing || username == null ? null : () {
              Navigator.of(context).pop();
              notifier.blockUser(username);
            },
            icon: const Icon(Icons.block, color: Colors.red),
            label: const Text(
              'Block User',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimeAgo(String? timestamp) {
    if (timestamp == null) return 'recently';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'just now';
      }
    } catch (e) {
      return 'recently';
    }
  }
}

// Color constants for consistency
class AppColors {
  static const primary = Color.fromRGBO(88, 86, 214, 1.0);
  static const accent = Color.fromRGBO(135, 206, 250, 1.0);
  static const background = Color.fromRGBO(248, 250, 255, 1.0);
  static const surface = Colors.white;
  static const border = Color.fromRGBO(135, 206, 250, 0.3);
  static const textPrimary = Color.fromRGBO(32, 32, 96, 0.87);
  static const textSecondary = Color.fromRGBO(32, 32, 96, 0.54);
}