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
              FilterChip(
                label: const Text('ทั้งหมด'),
                selected: selectedStatus == null,
                onSelected: (_) {
                  context.read<RoomBloc>().add(
                    const FilterRoomsByStatusEvent(null),
                  );
                },
              ),
              const SizedBox(width: 8),
              ...RoomStatus.values.map(
                (status) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status.displayName),
                    selected: selectedStatus == status,
                    onSelected: (_) {
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
}
