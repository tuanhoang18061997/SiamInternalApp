class LeaveRequest {
  LeaveRequest({
    required this.id,
    required this.code,
    required this.fromDate,
    required this.toDate,
    required this.daysOff,
    required this.reason,
    required this.statusId,
    required this.offTypeId,
    required this.replacePerson,
    required this.creatorName,
    required this.approverName,
    required this.dayOffTypeName,
  });
  final int id;
  final String code;
  final DateTime fromDate;
  final DateTime toDate;
  final double daysOff;
  final String reason;
  final int statusId;
  final int offTypeId;
  final String replacePerson;
  final String creatorName;
  final String approverName;
  final String dayOffTypeName;
}
