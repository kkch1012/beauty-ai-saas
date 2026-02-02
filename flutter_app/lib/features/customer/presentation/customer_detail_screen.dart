import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

import '../../../core/constants/app_theme.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('고객 상세'),
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.edit2),
            onPressed: () {
              // TODO: Edit customer
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('고객 상세 화면 (구현 예정)'),
      ),
    );
  }
}
