import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/subscription_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(subscriptionStatusProvider);
    final usageAsync = ref.watch(usageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Subscription Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        FeatherIcons.award,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '구독 플랜',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  subscriptionAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                    data: (status) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getTierColor(status.tier).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getTierLabel(status.tier),
                            style: TextStyle(
                              color: _getTierColor(status.tier),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Usage
                        usageAsync.when(
                          loading: () => const SizedBox(),
                          error: (e, _) => const SizedBox(),
                          data: (usage) => Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('이번 달 사용량'),
                                  Text(
                                    usage.isUnlimited
                                        ? '${usage.used} / 무제한'
                                        : '${usage.used} / ${usage.limit}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: usage.isUnlimited ? 0 : usage.percentage,
                                backgroundColor: AppColors.border,
                                color: usage.percentage > 0.8
                                    ? AppColors.warning
                                    : AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: Show subscription plans
                      },
                      child: const Text('플랜 변경'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Settings List
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: FeatherIcons.user,
                  title: '프로필 설정',
                  onTap: () {
                    // TODO: Profile settings
                  },
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: FeatherIcons.bell,
                  title: '알림 설정',
                  onTap: () {
                    // TODO: Notification settings
                  },
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: FeatherIcons.fileText,
                  title: '계약서 템플릿',
                  onTap: () {
                    // TODO: Contract templates
                  },
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: FeatherIcons.helpCircle,
                  title: '도움말',
                  onTap: () {
                    // TODO: Help
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Logout
          Card(
            child: _SettingsTile(
              icon: FeatherIcons.logOut,
              title: '로그아웃',
              textColor: AppColors.error,
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('로그아웃'),
                    content: const Text('로그아웃 하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text('로그아웃'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              },
            ),
          ),

          const SizedBox(height: 32),

          // App Version
          Center(
            child: Text(
              'Beauty AI v1.0.0',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTierLabel(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.basic:
        return 'Basic';
      case SubscriptionTier.premium:
        return 'Premium';
    }
  }

  Color _getTierColor(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return AppColors.textSecondary;
      case SubscriptionTier.basic:
        return AppColors.info;
      case SubscriptionTier.premium:
        return AppColors.primary;
    }
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      trailing: Icon(
        FeatherIcons.chevronRight,
        color: AppColors.textTertiary,
      ),
      onTap: onTap,
    );
  }
}
