import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/room.dart';
import '../bloc/room/room_bloc.dart';
import '../widgets/room_status_filter.dart';

class RoomListPage extends StatelessWidget {
  const RoomListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'จัดการห้องพัก',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black87),
            onPressed: () => context.push('/hotel/create-room'),
          ),
        ],
      ),
      body: BlocBuilder<RoomBloc, RoomState>(
        builder: (context, state) {
          if (state is RoomLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.black54,
                strokeWidth: 2,
              ),
            );
          }

          if (state is RoomLoaded) {
            return Column(
              children: [
                // Status Filter
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: const RoomStatusFilter(),
                ),

                // Room List
                Expanded(
                  child:
                      state.rooms.isEmpty
                          ? _buildEmptyState(context)
                          : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.rooms.length,
                            itemBuilder: (context, index) {
                              final room = state.rooms[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: MinimalRoomCard(
                                  room: room,
                                  onTap:
                                      () => context.push(
                                        '/hotel/rooms/${room.id}',
                                      ),
                                ),
                              );
                            },
                          ),
                ),
              ],
            );
          }

          if (state is RoomError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'เกิดข้อผิดพลาด',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<RoomBloc>().add(LoadRoomsEvent());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('ลองอีกครั้ง'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hotel_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีห้องพัก',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'เริ่มเพิ่มห้องพักเพื่อจัดการ',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/hotel/create-room'),
            icon: const Icon(Icons.add),
            label: const Text('เพิ่มห้องพัก'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// Keep the MinimalRoomCard class as it was
class MinimalRoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback? onTap;

  const MinimalRoomCard({super.key, required this.room, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Room Number
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getStatusColor(room.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    room.roomNumber,
                    style: TextStyle(
                      color: _getStatusColor(room.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Room Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'ชั้น ${room.floor}',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              room.status,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            room.status.displayName,
                            style: TextStyle(
                              color: _getStatusColor(room.status),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      room.roomType,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '฿${room.monthlyRent.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '/เดือน',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),

              // Arrow
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
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
