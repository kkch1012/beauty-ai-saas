import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:signature/signature.dart';

import '../../../core/constants/app_theme.dart';

class ContractScreen extends ConsumerStatefulWidget {
  final String? customerId;
  final String? simulationId;

  const ContractScreen({
    super.key,
    this.customerId,
    this.simulationId,
  });

  @override
  ConsumerState<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends ConsumerState<ContractScreen> {
  final _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
  );

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('시술 동의서'),
        actions: [
          TextButton.icon(
            onPressed: () {
              // TODO: Save and generate PDF
            },
            icon: const Icon(FeatherIcons.fileText),
            label: const Text('PDF 저장'),
          ),
        ],
      ),
      body: Row(
        children: [
          // Contract Content
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '반영구 화장 시술 동의서',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '본인은 아래 내용을 충분히 이해하고 시술에 동의합니다.\n\n'
                    '1. 시술 부위 및 방법에 대한 설명을 들었습니다.\n'
                    '2. 시술 후 발생할 수 있는 부작용에 대해 설명을 들었습니다.\n'
                    '3. 시술 후 주의사항에 대해 설명을 들었습니다.\n'
                    '4. 개인의 피부 상태에 따라 결과가 다를 수 있음을 이해합니다.\n'
                    '5. 리터치 시술에 대한 안내를 받았습니다.',
                    style: TextStyle(height: 1.8),
                  ),
                  const SizedBox(height: 32),

                  // Simulation image would be inserted here
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FeatherIcons.image,
                            size: 48,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '시뮬레이션 이미지',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Signature Panel
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                left: BorderSide(color: AppColors.border),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '고객 서명',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Signature(
                        controller: _signatureController,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: () {
                    _signatureController.clear();
                  },
                  icon: const Icon(FeatherIcons.trash2),
                  label: const Text('서명 지우기'),
                ),

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Complete contract
                  },
                  icon: const Icon(FeatherIcons.check),
                  label: const Text('동의 및 완료'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
