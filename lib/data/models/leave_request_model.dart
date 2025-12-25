import '../../domain/entities/leave_request.dart';

class LeaveRequestModel extends LeaveRequest {
  LeaveRequestModel({
    required super.id,
    required super.code,
    required super.fromDate,
    required super.toDate,
    required super.daysOff,
    required super.reason,
    required super.statusId,
    required super.offTypeId,
    required super.replacePerson,
    required super.creatorName,
    required super.approverName,
    required super.dayOffTypeName,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      id: json['id'],
      code: json['code'],
      fromDate: DateTime.parse(json['fromDate']),
      toDate: DateTime.parse(json['toDate']),
      daysOff: (json['daysOff'] as num).toDouble(),
      reason: json['reason'] ?? '',
      statusId: json['statusId'] ?? 0,
      offTypeId: json['offTypeId'] ?? 3,
      replacePerson: json['replacePerson'] ?? '',
      creatorName: json['creatorName'] ?? '',
      approverName: json['approverName'] ?? '',
      dayOffTypeName: json['dayOffTypeName'] ?? '',
    );
  }
}
