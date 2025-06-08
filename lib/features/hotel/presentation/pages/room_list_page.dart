import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/themes/app_spacing.dart';
import '../../../../core/themes/theme_extensions.dart';
import '../../../../services/rbac/permission_guard.dart';
import '../bloc/room/room_bloc.dart';
import '../widgets/room_card.dart';
import '../widgets/room_status_filter.dart';

class RoomListPage extends StatelessWidget {
  const RoomListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการห้องพัก')),
      floatingActionButton: PermissionGuard(
        permissionId: 'manage_hotels',
        child: FloatingActionButton(
          onPressed: () => context.push('/hotel/create-room'),
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.add, size: 28),
          elevation: 8,
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: AppSpacing.cardPadding,
            child: const RoomStatusFilter(),
          ),
          Expanded(
            child: BlocBuilder<RoomBloc, RoomState>(
              builder: (context, state) {
                if (state is RoomLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is RoomError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('เกิดข้อผิดพลาด', style: context.typography.h5),
                        AppSpacing.verticalGapSm,
                        Text(state.message),
                        AppSpacing.verticalGapMd,
                        ElevatedButton(
                          onPressed: () {
                            context.read<RoomBloc>().add(LoadRoomsEvent());
                          },
                          child: const Text('ลองใหม่'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is RoomLoaded) {
                  if (state.rooms.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.meeting_room_outlined,
                            size: 64,
                            color: context.customColors.textSecondary,
                          ),
                          AppSpacing.verticalGapMd,
                          Text('ไม่พบห้องพัก', style: context.typography.h5),
                          if (state.selectedStatus != null) ...[
                            AppSpacing.verticalGapSm,
                            Text(
                              'สถานะ: ${state.selectedStatus!.displayName}',
                              style: TextStyle(
                                color: context.customColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<RoomBloc>().add(LoadRoomsEvent());
                    },
                    child: GridView.builder(
                      padding: AppSpacing.screenPadding,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisSpacing: AppSpacing.md,
                          ),
                      itemCount: state.rooms.length,
                      itemBuilder: (context, index) {
                        final room = state.rooms[index];
                        return RoomCard(
                          room: room,
                          onTap: () => context.push('/hotel/rooms/${room.id}'),
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
