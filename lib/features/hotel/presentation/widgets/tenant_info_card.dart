import 'package:flutter/material.dart';
import '../../../../core/themes/app_spacing.dart';
import '../../domain/entities/tenant.dart';

class TenantInfoCard extends StatelessWidget {
  final Tenant tenant;
  final VoidCallback? onViewBills;
  final VoidCallback? onEndTenancy;

  const TenantInfoCard({
    super.key,
    required this.tenant,
    this.onViewBills,
    this.onEndTenancy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ข้อมูลผู้เช่า',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (tenant.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'กำลังเช่า',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            AppSpacing.verticalGapMd,
            _buildInfoRow(
              context,
              'วันที่เริ่มเช่า',
              _formatDate(tenant.startDate),
            ),
            if (tenant.endDate != null)
              _buildInfoRow(
                context,
                'วันที่สิ้นสุด',
                _formatDate(tenant.endDate!),
              ),
            _buildInfoRow(
              context,
              'เงินมัดจำ',
              '฿${tenant.depositAmount.toStringAsFixed(0)}',
            ),
            if (tenant.depositPaidDate != null) ...[
              _buildInfoRow(
                context,
                'วันที่ชำระมัดจำ',
                _formatDate(tenant.depositPaidDate!),
              ),
              if (tenant.depositReceiver != null)
                _buildInfoRow(context, 'ผู้รับเงิน', tenant.depositReceiver!),
            ],
            AppSpacing.verticalGapMd,
            Row(
              children: [
                if (onViewBills != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onViewBills,
                      icon: const Icon(Icons.receipt),
                      label: const Text('ดูบิล'),
                    ),
                  ),
                if (onViewBills != null && onEndTenancy != null)
                  AppSpacing.horizontalGapSm,
                if (onEndTenancy != null && tenant.isActive)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onEndTenancy,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text('สิ้นสุดการเช่า'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
