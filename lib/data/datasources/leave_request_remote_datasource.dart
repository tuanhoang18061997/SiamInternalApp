import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/leave_request_model.dart';

abstract class LeaveRequestRemoteDataSource {
  Future<List<LeaveRequestModel>> getLetters(String token);
}

class LeaveRequestRemoteDataSourceImpl implements LeaveRequestRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  LeaveRequestRemoteDataSourceImpl(this.client, this.baseUrl);

  @override
  Future<List<LeaveRequestModel>> getLetters(String token) async {
    final res = await client.get(
      Uri.parse('$baseUrl/letters'),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => LeaveRequestModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load letters");
    }
  }
}
