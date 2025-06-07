import '../../domain/entities/maintenance_request.dart';

class MaintenanceRequestModel extends MaintenanceRequest {
  const MaintenanceRequestModel({
    required super.id,
    required super.roomId,
    required super.reportedBy,
    required super.title,
    super.description,
    required super.priority,
    required super.status,
    super.images,
    super.assignedTo,
    super.completedDate,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MaintenanceRequestModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceRequestModel(
      id: json['id'],
      roomId: json['room_id'],
      reportedBy: json['reported_by'],
      title: json['title'],
      description: json['description'],
      priority: MaintenancePriority.fromString(json['priority'] ?? 'normal'),
      status: MaintenanceStatus.fromString(json['status'] ?? 'pending'),
      images: List<String>.from(json['images'] ?? []),
      assignedTo: json['assigned_to'],
      completedDate:
          json['completed_date'] != null
              ? DateTime.parse(json['completed_date'])
              : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'reported_by': reportedBy,
      'title': title,
      'description': description,
      'priority': priority.value,
      'status': status.value,
      'images': images,
      'assigned_to': assignedTo,
      'completed_date': completedDate?.toIso8601String(),
    };
  }
}
