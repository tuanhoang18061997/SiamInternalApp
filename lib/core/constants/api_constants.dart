class ApiConstants {
  static const String baseUrl = 'https://api.example.com';
  static const String loginEndpoint = '/auth/login';
  static const String leaveRequestsEndpoint = '/leave-requests';
  static const String createLeaveRequestEndpoint = '/leave-requests';
  static const String approveLeaveRequestEndpoint = '/leave-requests/{id}/approve';
  static const String rejectLeaveRequestEndpoint = '/leave-requests/{id}/reject';
  
  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
