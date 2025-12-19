import 'package:flutter_test/flutter_test.dart';
import 'package:siam_internal_app/domain/entities/user.dart';
import 'package:siam_internal_app/domain/entities/leave_request.dart';

void main() {
  group('User Entity', () {
    test('creates user with required fields', () {
      final user = User(
        id: '1',
        email: 'test@example.com',
        name: 'Test User',
        role: 'employee',
      );

      expect(user.id, '1');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.role, 'employee');
      expect(user.department, isNull);
    });

    test('creates user with optional department', () {
      final user = User(
        id: '1',
        email: 'test@example.com',
        name: 'Test User',
        role: 'employee',
        department: 'Engineering',
      );

      expect(user.department, 'Engineering');
    });
  });

  group('LeaveRequest Entity', () {
    test('creates leave request with required fields', () {
      final startDate = DateTime.now();
      final endDate = DateTime.now().add(const Duration(days: 2));

      final request = LeaveRequest(
        id: '1',
        employeeId: '1',
        employeeName: 'John Doe',
        leaveType: 'Annual Leave',
        startDate: startDate,
        endDate: endDate,
        reason: 'Family vacation',
        status: 'pending',
      );

      expect(request.id, '1');
      expect(request.employeeId, '1');
      expect(request.employeeName, 'John Doe');
      expect(request.leaveType, 'Annual Leave');
      expect(request.startDate, startDate);
      expect(request.endDate, endDate);
      expect(request.reason, 'Family vacation');
      expect(request.status, 'pending');
    });

    test('creates approved leave request with approval details', () {
      final approvedAt = DateTime.now();

      final request = LeaveRequest(
        id: '1',
        employeeId: '1',
        employeeName: 'John Doe',
        leaveType: 'Annual Leave',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 2)),
        reason: 'Family vacation',
        status: 'approved',
        approvedBy: 'Manager',
        approvedAt: approvedAt,
      );

      expect(request.status, 'approved');
      expect(request.approvedBy, 'Manager');
      expect(request.approvedAt, approvedAt);
    });

    test('creates rejected leave request with rejection reason', () {
      final request = LeaveRequest(
        id: '1',
        employeeId: '1',
        employeeName: 'John Doe',
        leaveType: 'Annual Leave',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 2)),
        reason: 'Family vacation',
        status: 'rejected',
        rejectionReason: 'Insufficient leave balance',
      );

      expect(request.status, 'rejected');
      expect(request.rejectionReason, 'Insufficient leave balance');
    });
  });
}
