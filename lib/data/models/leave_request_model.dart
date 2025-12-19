import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/leave_request.dart';

part 'leave_request_model.g.dart';

@JsonSerializable()
class LeaveRequestModel {
  final String id;
  @JsonKey(name: 'employee_id')
  final String employeeId;
  @JsonKey(name: 'employee_name')
  final String employeeName;
  @JsonKey(name: 'leave_type')
  final String leaveType;
  @JsonKey(name: 'start_date')
  final String startDate;
  @JsonKey(name: 'end_date')
  final String endDate;
  final String reason;
  final String status;
  @JsonKey(name: 'approved_by')
  final String? approvedBy;
  @JsonKey(name: 'approved_at')
  final String? approvedAt;
  @JsonKey(name: 'rejection_reason')
  final String? rejectionReason;
  @JsonKey(name: 'created_at')
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
      _$LeaveRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$LeaveRequestModelToJson(this);

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
