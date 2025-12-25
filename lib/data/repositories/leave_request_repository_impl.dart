import '../../domain/entities/leave_request.dart';
import '../../domain/repositories/leave_request_repository.dart';
import '../datasources/leave_request_remote_datasource.dart';

class LeaveRequestRepositoryImpl implements LeaveRequestRepository {
  final LeaveRequestRemoteDataSource remoteDataSource;
  final String token;

  LeaveRequestRepositoryImpl(this.remoteDataSource, this.token);

  @override
  Future<List<LeaveRequest>> getLetters() {
    return remoteDataSource.getLetters(token);
  }

  @override
  Future<LeaveRequest> getLetterById(int id) {
    throw UnimplementedError(); // bạn có thể thêm sau
  }
}
