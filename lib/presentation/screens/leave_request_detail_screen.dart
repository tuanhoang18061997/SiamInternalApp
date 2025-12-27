import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LeaveRequestDetailScreen extends StatefulWidget {
  const LeaveRequestDetailScreen({super.key, required this.requestId});
  final String requestId;

  @override
  State<LeaveRequestDetailScreen> createState() =>
      _LeaveRequestDetailScreenState();
}

class _LeaveRequestDetailScreenState extends State<LeaveRequestDetailScreen> {
  Map<String, dynamic>? request;
  bool loading = true;
  String? error;
  int groupId = 0; // role hiện tại lấy từ API

  static const String baseUrl = 'http://localhost:5204';

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _callAction(String action) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No token found'), backgroundColor: Colors.red),
        );
        return;
      }

      final uri = Uri.parse('$baseUrl/api/Letters/${widget.requestId}/$action');
      final res = await http.put(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      });

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$action success'), backgroundColor: Colors.green),
        );
        _loadDetail(); // reload để cập nhật trạng thái
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: ${res.statusCode}'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _loadDetail() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        setState(() => error = 'No token found');
        return;
      }

      final uri = Uri.parse('$baseUrl/api/Letters/${widget.requestId}');
      final res =
          await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          request = body;
          groupId = body['currentUserGroupId'] ?? 0; // lấy role từ API
          print("statusId: ${request?['statusId']}, groupId: $groupId");
        });
      } else {
        setState(() => error = 'Failed: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = () {
      final statusId = request?['statusId'];
      switch (statusId) {
        case 3:
          return Colors.green; // approved
        case 4:
          return Colors.red; // rejected
        case 2:
          return Colors.grey; // canceled
        default:
          return Colors.orange; // pending
      }
    }();

    return Scaffold(
      appBar: AppBar(
          title: const Text('Leave Request Detail',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    blurRadius: 4.0,
                    color: Colors.black45,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ))),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Lỗi: $error'))
              : request == null
                  ? const Center(child: Text('Không có dữ liệu'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildRow(Icons.confirmation_number, 'Code',
                                      request!['code']),
                                  _buildRow(Icons.person, 'Employee',
                                      request!['creatorName']),
                                  _buildRow(Icons.work, 'Leave Type',
                                      request!['dayOffTypeName']),
                                  _buildRow(Icons.access_time, 'Off Type',
                                      _mapOffType(request!['offTypeId'])),
                                  _buildRow(Icons.calendar_today, 'Start Date',
                                      _formatDate(request!['fromDate'])),
                                  _buildRow(Icons.calendar_today, 'End Date',
                                      _formatDate(request!['toDate'])),
                                  _buildRow(Icons.notes, 'Reason',
                                      request!['reason']),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "Status: ${_mapStatus(request!['statusId']).toUpperCase()}",
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Chỉ hiện nút nếu pending và role là manager
                          if (request!['statusId'] == 1 &&
                              (groupId == 1 || groupId == 2))
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _callAction('approve');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 4,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          'Approve',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _callAction('reject');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 4,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.close, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          'Reject',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                        ],
                      ),
                    ),
    );
  }

  Widget _buildRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey, size: 20),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value?.toString() ?? ''),
          ),
        ],
      ),
    );
  }

  String _mapStatus(dynamic statusId) {
    switch (statusId) {
      case 1:
        return 'pending';
      case 2:
        return 'canceled';
      case 3:
        return 'approved';
      case 4:
        return 'rejected';
      default:
        return 'pending';
    }
  }

  String _mapOffType(dynamic offTypeId) {
    switch (offTypeId) {
      case 1:
        return 'Buổi sáng';
      case 2:
        return 'Buổi chiều';
      case 3:
        return 'Cả ngày';
      default:
        return 'Không xác định';
    }
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    final d = DateTime.tryParse(dateStr.toString());
    if (d == null) return dateStr.toString();
    return '${d.day}/${d.month}/${d.year}';
  }
}
