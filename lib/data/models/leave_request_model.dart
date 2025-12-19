import '../../domain/entities/leave_request.dart';

class LeaveRequestModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String leaveType;
  final String startDate;
  final String endDate;
  final String reason;
  final String status;
  final String? approvedBy;
  final String? approvedAt;
  final String? rejectionReason;
  final String? createdAt;

  LeaveRequestModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.createdAt,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) =>
      LeaveRequestModel(
        id: json['id'] as String,
        employeeId: json['employee_id'] as String,
        employeeName: json['employee_name'] as String,
        leaveType: json['leave_type'] as String,
        startDate: json['start_date'] as String,
        endDate: json['end_date'] as String,
        reason: json['reason'] as String,
        status: json['status'] as String,
        approvedBy: json['approved_by'] as String?,
        approvedAt: json['approved_at'] as String?,
        rejectionReason: json['rejection_reason'] as String?,
        createdAt: json['created_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'employee_id': employeeId,
        'employee_name': employeeName,
        'leave_type': leaveType,
        'start_date': startDate,
        'end_date': endDate,
        'reason': reason,
        'status': status,
        'approved_by': approvedBy,
        'approved_at': approvedAt,
        'rejection_reason': rejectionReason,
        'created_at': createdAt,
      };

  LeaveRequest toEntity() => LeaveRequest(
        id: id,
        employeeId: employeeId,
        employeeName: employeeName,
        leaveType: leaveType,
        startDate: DateTime.parse(startDate),
        endDate: DateTime.parse(endDate),
        reason: reason,
        status: status,
        approvedBy: approvedBy,
        approvedAt: approvedAt != null ? DateTime.parse(approvedAt!) : null,
        rejectionReason: rejectionReason,
        createdAt: createdAt != null ? DateTime.parse(createdAt!) : null,
      );

  factory LeaveRequestModel.fromEntity(LeaveRequest entity) =>
      LeaveRequestModel(
        id: entity.id,
        employeeId: entity.employeeId,
        employeeName: entity.employeeName,
        leaveType: entity.leaveType,
        startDate: entity.startDate.toIso8601String(),
        endDate: entity.endDate.toIso8601String(),
        reason: entity.reason,
        status: entity.status,
        approvedBy: entity.approvedBy,
        approvedAt: entity.approvedAt?.toIso8601String(),
        rejectionReason: entity.rejectionReason,
        createdAt: entity.createdAt?.toIso8601String(),
      );
}
