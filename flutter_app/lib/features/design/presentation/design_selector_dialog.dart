import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_theme.dart';
import 'design_library_screen.dart';

class DesignSelectorDialog extends ConsumerStatefulWidget {
  const DesignSelectorDialog({super.key});

  @override
  ConsumerState<DesignSelectorDialog> createState() => _DesignSelectorDialogState();
}

class _DesignSelectorDialogState extends ConsumerState<DesignSelectorDialog> {
  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final designsAsync = ref.watch(designsProvider);

    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '눈썹 디자인 선택',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(FeatherIcons.x),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Upload from gallery
            OutlinedButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(FeatherIcons.image),
              label: const Text('갤러리에서 선택'),
            ),
            const SizedBox(height: 16),

            const Divider(),
            const SizedBox(height: 16),

            // Library designs
            Text(
              '내 디자인 라이브러리',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            Expanded(
              child: designsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (designs) {
                  if (designs.isEmpty) {
                    return Center(
                      child: Text(
                        '저장된 디자인이 없습니다',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: designs.length,
                    itemBuilder: (context, index) {
                      final design = designs[index];
                      return InkWell(
                        onTap: () => _selectDesign(design),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                            image: design['thumbnail_url'] != null
                                ? DecorationImage(
                                    image: NetworkImage(design['thumbnail_url']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: design['thumbnail_url'] == null
                              ? const Icon(FeatherIcons.image)
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final xFile = await _picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      Navigator.pop(context, File(xFile.path));
    }
  }

  Future<void> _selectDesign(Map<String, dynamic> design) async {
    final imageUrl = design['image_url'];
    if (imageUrl == null) return;

    // Download image to temp file
    try {
      final response = await http.get(Uri.parse(imageUrl));
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/design_${design['id']}.png');
      await tempFile.writeAsBytes(response.bodyBytes);

      if (mounted) {
        Navigator.pop(context, tempFile);
      }
    } catch (e) {
      // Handle error
    }
  }
}
