import 'package:flutter/material.dart';
import '../../../../core/themes/app_spacing.dart';
import '../../domain/entities/room.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback? onTap;

  const RoomCard({super.key, required this.room, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              color: _getStatusColor(room.status).withValues(alpha: 0.1),
              child: Icon(
                Icons.meeting_room,
                size: 48,
                color: _getStatusColor(room.status),
              ),
            ),
            Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ห้อง ${room.roomNumber}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  AppSpacing.verticalGapXs,
                  Text(
                    'ชั้น ${room.floor}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  AppSpacing.verticalGapSm,
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(room.status),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          room.status.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.verticalGapSm,
                  Text(
                    '฿${room.monthlyRent.toStringAsFixed(0)}/เดือน',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return Colors.green;
      case RoomStatus.occupied:
        return Colors.blue;
      case RoomStatus.reserved:
        return Colors.orange;
      case RoomStatus.maintenanceVacant:
      case RoomStatus.maintenanceOccupied:
        return Colors.red;
    }
  }
}
