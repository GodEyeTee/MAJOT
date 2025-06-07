import 'package:equatable/equatable.dart';

enum MaintenancePriority {
  low('low', 'ต่ำ'),
  normal('normal', 'ปกติ'),
  high('high', 'สูง'),
  urgent('urgent', 'เร่งด่วน');

  final String value;
  final String displayName;

  const MaintenancePriority(this.value, this.displayName);

  static MaintenancePriority fromString(String value) {
    return MaintenancePriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => MaintenancePriority.normal,
    );
  }
}

enum MaintenanceStatus {
  pending('pending', 'รอดำเนินการ'),
  inProgress('in_progress', 'กำลังดำเนินการ'),
  completed('completed', 'เสร็จสิ้น'),
  cancelled('cancelled', 'ยกเลิก');

  final String value;
  final String displayName;

  const MaintenanceStatus(this.value, this.displayName);

  static MaintenanceStatus fromString(String value) {
    return MaintenanceStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => MaintenanceStatus.pending,
    );
  }
}

class MaintenanceRequest extends Equatable {
  final String id;
  final String roomId;
  final String reportedBy;
  final String title;
  final String? description;
  final MaintenancePriority priority;
  final MaintenanceStatus status;
  final List<String> images;
  final String? assignedTo;
  final DateTime? completedDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MaintenanceRequest({
    required this.id,
    required this.roomId,
    required this.reportedBy,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    this.images = const [],
    this.assignedTo,
    this.completedDate,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    roomId,
    reportedBy,
    title,
    description,
    priority,
    status,
    images,
    assignedTo,
    completedDate,
    createdAt,
    updatedAt,
  ];
}
