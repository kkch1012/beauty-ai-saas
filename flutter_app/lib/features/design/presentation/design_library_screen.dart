import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_theme.dart';

final designsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  final response = await supabase
      .from('eyebrow_designs')
      .select()
      .or('profile_id.eq.${user.id},is_public.eq.true')
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

class DesignLibraryScreen extends ConsumerWidget {
  const DesignLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final designsAsync = ref.watch(designsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('디자인 라이브러리'),
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.upload),
            onPressed: () {
              // TODO: Upload new design
            },
            tooltip: '디자인 추가',
          ),
        ],
      ),
      body: designsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (designs) {
          if (designs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    FeatherIcons.grid,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '저장된 디자인이 없습니다',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Add design
                    },
                    icon: const Icon(FeatherIcons.plus),
                    label: const Text('디자인 추가'),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemCount: designs.length,
            itemBuilder: (context, index) {
              final design = designs[index];
              return _DesignCard(design: design);
            },
          );
        },
      ),
    );
  }
}

class _DesignCard extends StatelessWidget {
  final Map<String, dynamic> design;

  const _DesignCard({required this.design});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail
          CachedNetworkImage(
            imageUrl: design['thumbnail_url'] ?? design['image_url'] ?? '',
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppColors.surfaceVariant,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: AppColors.surfaceVariant,
              child: const Icon(FeatherIcons.image),
            ),
          ),

          // Gradient overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    design['name'] ?? 'Untitled',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (design['category'] != null)
                    Text(
                      _getCategoryLabel(design['category']),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Favorite indicator
          if (design['is_favorite'] == true)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  FeatherIcons.heart,
                  size: 16,
                  color: AppColors.error,
                ),
              ),
            ),

          // Public indicator
          if (design['is_public'] == true)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.info,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '공개',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'embossed':
        return '엠보';
      case 'shading':
        return '수지';
      case 'combo':
        return '콤보';
      case 'natural':
        return '내추럴';
      default:
        return category;
    }
  }
}
