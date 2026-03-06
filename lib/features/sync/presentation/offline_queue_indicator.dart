import 'package:flutter/material.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/features/sync/data/offline_queue_service.dart';

/// Shows a small banner when there are pending offline operations.
///
/// Place this in the dashboard or app bar to give users visibility
/// into unsynchronised changes.
class OfflineQueueIndicator extends StatelessWidget {
  final OfflineQueueService queueService;
  const OfflineQueueIndicator({super.key, required this.queueService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: queueService.watchPendingCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        if (count == 0) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppConstants.warningAmber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppConstants.warningAmber.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_off, color: AppConstants.warningAmber, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$count \u0639\u0645\u0644\u064A\u0629 \u0628\u0627\u0646\u062A\u0638\u0627\u0631 \u0627\u0644\u0645\u0632\u0627\u0645\u0646\u0629', // عملية بانتظار المزامنة
                  style: const TextStyle(
                    color: AppConstants.warningAmber,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => queueService.drainQueue(),
                child: const Icon(Icons.refresh, color: AppConstants.warningAmber, size: 18),
              ),
            ],
          ),
        );
      },
    );
  }
}
