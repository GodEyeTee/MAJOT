import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/themes/app_spacing.dart';
import '../../../../core/themes/theme_extensions.dart';
import '../../../../services/rbac/permission_guard.dart';
import '../../domain/entities/room.dart';
import '../../domain/entities/tenant.dart';
import '../bloc/room/room_bloc.dart';
import '../bloc/tenant/tenant_bloc.dart';
import '../widgets/tenant_info_card.dart';

class RoomDetailPage extends StatefulWidget {
  final String roomId;

  const RoomDetailPage({super.key, required this.roomId});

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<RoomBloc>().add(LoadRoomEvent(widget.roomId));
    context.read<TenantBloc>().add(LoadTenantByRoomEvent(widget.roomId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดห้อง'),
        actions: [
          PermissionGuard(
            permissionId: 'manage_rooms',
            child: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    context.push('/hotel/rooms/${widget.roomId}/edit');
                    break;
                  case 'delete':
                    _showDeleteConfirmation(context);
                    break;
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('แก้ไข'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('ลบ', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
            ),
          ),
        ],
      ),
      body: BlocBuilder<RoomBloc, RoomState>(
        builder: (context, state) {
          if (state is RoomLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RoomError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('เกิดข้อผิดพลาด: ${state.message}'),
                  AppSpacing.verticalGapMd,
                  ElevatedButton(
                    onPressed: () {
                      context.read<RoomBloc>().add(
                        LoadRoomEvent(widget.roomId),
                      );
                    },
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }

          if (state is RoomDetailLoaded) {
            final room = state.room;
            return RefreshIndicator(
              onRefresh: () async {
                context.read<RoomBloc>().add(LoadRoomEvent(widget.roomId));
                context.read<TenantBloc>().add(
                  LoadTenantByRoomEvent(widget.roomId),
                );
              },
              child: SingleChildScrollView(
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRoomInfoCard(context, room),
                    AppSpacing.verticalGapMd,
                    _buildTenantSection(context, room),
                    AppSpacing.verticalGapMd,
                    _buildActionsSection(context, room),
                    AppSpacing.verticalGapMd,
                    _buildMaintenanceSection(context, room),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildRoomInfoCard(BuildContext context, Room room) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ห้อง ${room.roomNumber}', style: context.typography.h4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(room.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    room.status.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.verticalGapMd,
            _buildInfoRow('ชั้น', '${room.floor}'),
            _buildInfoRow('ประเภท', room.roomType),
            if (room.size != null) _buildInfoRow('ขนาด', '${room.size} ตร.ม.'),
            _buildInfoRow(
              'ค่าเช่า',
              '฿${room.monthlyRent.toStringAsFixed(0)}/เดือน',
            ),
            if (room.description != null) ...[
              AppSpacing.verticalGapMd,
              Text('รายละเอียด', style: context.typography.h6),
              AppSpacing.verticalGapXs,
              Text(room.description!),
            ],
            if (room.amenities.isNotEmpty) ...[
              AppSpacing.verticalGapMd,
              Text('สิ่งอำนวยความสะดวก', style: context.typography.h6),
              AppSpacing.verticalGapXs,
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children:
                    room.amenities
                        .map(
                          (amenity) => Chip(
                            label: Text(amenity),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: context.customColors.textSecondary),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTenantSection(BuildContext context, Room room) {
    return BlocBuilder<TenantBloc, TenantState>(
      builder: (context, state) {
        if (state is TenantLoading) {
          return const Card(
            child: Center(
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (state is TenantLoaded && state.tenant != null) {
          return TenantInfoCard(
            tenant: state.tenant!,
            onViewBills: () {
              context.push('/hotel/tenants/${state.tenant!.id}/bills');
            },
            onEndTenancy:
                room.status == RoomStatus.occupied
                    ? () => _showEndTenancyDialog(context, state.tenant!)
                    : null,
          );
        }

        if (room.status == RoomStatus.available ||
            room.status == RoomStatus.reserved) {
          return Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 48,
                    color: context.customColors.textSecondary,
                  ),
                  AppSpacing.verticalGapSm,
                  Text(
                    room.status == RoomStatus.available
                        ? 'ห้องว่าง พร้อมให้เช่า'
                        : 'ห้องถูกจองแล้ว',
                    style: TextStyle(color: context.customColors.textSecondary),
                  ),
                  if (room.status == RoomStatus.available) ...[
                    AppSpacing.verticalGapMd,
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push('/hotel/rooms/${room.id}/create-tenant');
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('เพิ่มผู้เช่า'),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildActionsSection(BuildContext context, Room room) {
    final List<Widget> actions = [];

    // Meter reading action
    if (room.status == RoomStatus.occupied ||
        room.status == RoomStatus.maintenanceOccupied) {
      actions.add(
        _buildActionCard(
          context,
          icon: Icons.speed,
          title: 'บันทึกมิเตอร์',
          subtitle: 'บันทึกค่าน้ำ/ไฟประจำเดือน',
          color: Colors.blue,
          onTap: () => context.push('/hotel/rooms/${room.id}/meter'),
        ),
      );
    }

    // Bill action
    if (room.status == RoomStatus.occupied ||
        room.status == RoomStatus.maintenanceOccupied) {
      actions.add(
        _buildActionCard(
          context,
          icon: Icons.receipt_long,
          title: 'ออกบิล',
          subtitle: 'สร้างบิลประจำเดือน',
          color: Colors.green,
          onTap: () => context.push('/hotel/rooms/${room.id}/create-bill'),
        ),
      );
    }

    // Maintenance action
    actions.add(
      _buildActionCard(
        context,
        icon: Icons.build,
        title: 'แจ้งซ่อม',
        subtitle: 'บันทึกการแจ้งซ่อม',
        color: Colors.orange,
        onTap: () => context.push('/hotel/rooms/${room.id}/maintenance'),
      ),
    );

    // Chat action
    if (room.status == RoomStatus.occupied ||
        room.status == RoomStatus.maintenanceOccupied) {
      actions.add(
        _buildActionCard(
          context,
          icon: Icons.chat,
          title: 'แชท',
          subtitle: 'ติดต่อกับผู้เช่า',
          color: Colors.purple,
          onTap: () => context.push('/hotel/rooms/${room.id}/chat'),
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('การดำเนินการ', style: context.typography.h5),
        AppSpacing.verticalGapSm,
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          children: actions,
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              AppSpacing.verticalGapXs,
              Text(
                title,
                style: context.typography.h6,
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: context.customColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaintenanceSection(BuildContext context, Room room) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ประวัติการแจ้งซ่อม', style: context.typography.h5),
            TextButton(
              onPressed: () {
                context.push('/hotel/rooms/${room.id}/maintenance/history');
              },
              child: const Text('ดูทั้งหมด'),
            ),
          ],
        ),
        AppSpacing.verticalGapSm,
        Card(
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Center(
              child: Text(
                'ไม่มีการแจ้งซ่อม',
                style: TextStyle(color: context.customColors.textSecondary),
              ),
            ),
          ),
        ),
      ],
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

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ยืนยันการลบ'),
            content: const Text('คุณต้องการลบห้องนี้หรือไม่?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  context.read<RoomBloc>().add(DeleteRoomEvent(widget.roomId));
                  Navigator.pop(context);
                  context.pop();
                },
                child: const Text('ลบ'),
              ),
            ],
          ),
    );
  }

  void _showEndTenancyDialog(BuildContext context, Tenant tenant) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ยืนยันการสิ้นสุดการเช่า'),
            content: const Text('คุณต้องการสิ้นสุดการเช่าห้องนี้หรือไม่?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () {
                  context.read<TenantBloc>().add(
                    EndTenancyEvent(tenant.id, DateTime.now()),
                  );
                  Navigator.pop(context);
                },
                child: const Text('ยืนยัน'),
              ),
            ],
          ),
    );
  }
}
