import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/room.dart';
import '../bloc/room/room_bloc.dart';

class RoomStatusFilter extends StatelessWidget {
  const RoomStatusFilter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomBloc, RoomState>(
      builder: (context, state) {
        final selectedStatus =
            state is RoomLoaded ? state.selectedStatus : null;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _MinimalFilterChip(
                label: 'ทั้งหมด',
                isSelected: selectedStatus == null,
                onTap: () {
                  context.read<RoomBloc>().add(
                    const FilterRoomsByStatusEvent(null),
                  );
                },
              ),
              const SizedBox(width: 8),
              ...RoomStatus.values.map(
                (status) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _MinimalFilterChip(
                    label: status.displayName,
                    isSelected: selectedStatus == status,
                    color: _getStatusColor(status),
                    onTap: () {
                      context.read<RoomBloc>().add(
                        FilterRoomsByStatusEvent(status),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return Colors.green[600]!;
      case RoomStatus.occupied:
        return Colors.blue[600]!;
      case RoomStatus.reserved:
        return Colors.orange[600]!;
      case RoomStatus.maintenanceVacant:
      case RoomStatus.maintenanceOccupied:
        return Colors.red[600]!;
    }
  }
}

class _MinimalFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _MinimalFilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? (color ?? Colors.black87) : Colors.white,
          border: Border.all(
            color: isSelected ? (color ?? Colors.black87) : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
