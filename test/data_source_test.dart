import 'package:flutter_test/flutter_test.dart';
import 'package:siam_internal_app/data/datasources/mock_api_datasource.dart';

void main() {
  late MockApiDataSource dataSource;

  setUp(() {
    dataSource = MockApiDataSource();
  });

  group('MockApiDataSource', () {
    test('login with valid credentials returns user', () async {
      final user = await dataSource.login('admin@siam.com', 'password');
      
      expect(user.email, 'admin@siam.com');
      expect(user.name, 'Admin User');
      expect(user.role, 'manager');
    });

    test('login with invalid credentials throws exception', () async {
      expect(
        () => dataSource.login('invalid@email.com', 'password'),
        throwsException,
      );
    });

    test('getLeaveRequests returns list of requests', () async {
      final requests = await dataSource.getLeaveRequests();
      
      expect(requests, isNotEmpty);
      expect(requests.length, greaterThanOrEqualTo(2));
    });

    test('createLeaveRequest adds new request', () async {
      final initialRequests = await dataSource.getLeaveRequests();
      final initialCount = initialRequests.length;

      final newRequest = await dataSource.createLeaveRequest(
        employeeId: '2',
        employeeName: 'John Doe',
        leaveType: 'Annual Leave',
        startDate: DateTime.now().add(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 3)),
        reason: 'Test leave request',
      );

      expect(newRequest.status, 'pending');
      
      final updatedRequests = await dataSource.getLeaveRequests();
      expect(updatedRequests.length, initialCount + 1);
    });

    test('approveLeaveRequest changes status to approved', () async {
      final requests = await dataSource.getLeaveRequests();
      final pendingRequest = requests.firstWhere((r) => r.status == 'pending');

      final approved = await dataSource.approveLeaveRequest(
        pendingRequest.id,
        'Admin User',
      );

      expect(approved.status, 'approved');
      expect(approved.approvedBy, 'Admin User');
      expect(approved.approvedAt, isNotNull);
    });

    test('rejectLeaveRequest changes status to rejected', () async {
      final requests = await dataSource.getLeaveRequests();
      final pendingRequest = requests.firstWhere((r) => r.status == 'pending');

      final rejected = await dataSource.rejectLeaveRequest(
        pendingRequest.id,
        'Admin User',
        'Insufficient leave balance',
      );

      expect(rejected.status, 'rejected');
      expect(rejected.approvedBy, 'Admin User');
      expect(rejected.rejectionReason, 'Insufficient leave balance');
    });
  });
}
