import '../entities/leave_request.dart';

abstract class LeaveRequestRepository {
  Future<List<LeaveRequest>> getLetters();
  Future<LeaveRequest> getLetterById(int id);
}
