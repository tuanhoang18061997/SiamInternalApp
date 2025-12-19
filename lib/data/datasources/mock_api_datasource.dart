import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/leave_request_model.dart';

class MockApiDataSource {
  // Mock users
  final List<UserModel> _users = [
    UserModel(
      id: '1',
      email: 'admin@siam.com',
      name: 'Admin User',
      role: 'manager',
      department: 'Management',
    ),
    UserModel(
      id: '2',
      email: 'employee@siam.com',
      name: 'John Doe',
      role: 'employee',
      department: 'Engineering',
    ),
  ];

  // Mock leave requests
  final List<LeaveRequestModel> _leaveRequests = [
    LeaveRequestModel(
      id: '1',
      employeeId: '2',
      employeeName: 'John Doe',
      leaveType: 'Annual Leave',
      startDate: DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      endDate: DateTime.now().add(const Duration(days: 10)).toIso8601String(),
      reason: 'Family vacation',
      status: 'pending',
      createdAt: DateTime.now().toIso8601String(),
    ),
    LeaveRequestModel(
      id: '2',
      employeeId: '2',
      employeeName: 'John Doe',
      leaveType: 'Sick Leave',
      startDate: DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      endDate: DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      reason: 'Medical appointment',
      status: 'approved',
      approvedBy: 'Admin User',
      approvedAt: DateTime.now().subtract(const Duration(days: 6)).toIso8601String(),
      createdAt: DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
    ),
  ];

  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    
    final user = _users.firstWhere(
      (u) => u.email == email,
      orElse: () => throw Exception('Invalid credentials'),
    );
    
    return user;
  }

  Future<List<LeaveRequestModel>> getLeaveRequests() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_leaveRequests);
  }

  Future<LeaveRequestModel> getLeaveRequestById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _leaveRequests.firstWhere(
      (lr) => lr.id == id,
      orElse: () => throw Exception('Leave request not found'),
    );
  }

  Future<LeaveRequestModel> createLeaveRequest({
    required String employeeId,
    required String employeeName,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final newRequest = LeaveRequestModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      employeeId: employeeId,
      employeeName: employeeName,
      leaveType: leaveType,
      startDate: startDate.toIso8601String(),
      endDate: endDate.toIso8601String(),
      reason: reason,
      status: 'pending',
      createdAt: DateTime.now().toIso8601String(),
    );
    
    _leaveRequests.insert(0, newRequest);
    return newRequest;
  }

  Future<LeaveRequestModel> approveLeaveRequest(String id, String approvedBy) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _leaveRequests.indexWhere((lr) => lr.id == id);
    if (index == -1) throw Exception('Leave request not found');
    
    final updated = LeaveRequestModel(
      id: _leaveRequests[index].id,
      employeeId: _leaveRequests[index].employeeId,
      employeeName: _leaveRequests[index].employeeName,
      leaveType: _leaveRequests[index].leaveType,
      startDate: _leaveRequests[index].startDate,
      endDate: _leaveRequests[index].endDate,
      reason: _leaveRequests[index].reason,
      status: 'approved',
      approvedBy: approvedBy,
      approvedAt: DateTime.now().toIso8601String(),
      createdAt: _leaveRequests[index].createdAt,
    );
    
    _leaveRequests[index] = updated;
    return updated;
  }

  Future<LeaveRequestModel> rejectLeaveRequest(
    String id,
    String rejectedBy,
    String reason,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _leaveRequests.indexWhere((lr) => lr.id == id);
    if (index == -1) throw Exception('Leave request not found');
    
    final updated = LeaveRequestModel(
      id: _leaveRequests[index].id,
      employeeId: _leaveRequests[index].employeeId,
      employeeName: _leaveRequests[index].employeeName,
      leaveType: _leaveRequests[index].leaveType,
      startDate: _leaveRequests[index].startDate,
      endDate: _leaveRequests[index].endDate,
      reason: _leaveRequests[index].reason,
      status: 'rejected',
      approvedBy: rejectedBy,
      approvedAt: DateTime.now().toIso8601String(),
      rejectionReason: reason,
      createdAt: _leaveRequests[index].createdAt,
    );
    
    _leaveRequests[index] = updated;
    return updated;
  }
}

final mockApiDataSourceProvider = Provider<MockApiDataSource>((ref) {
  return MockApiDataSource();
});
