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

  void _showUpdateDialog(int letterId, int currentStatus) {
    int selectedStatus = currentStatus;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Cập nhật trạng thái đơn"),
              content: DropdownButtonFormField<int>(
                value: selectedStatus,
                items: const [
                  DropdownMenuItem(value: 1, child: Text("Đang chờ duyệt")),
                  DropdownMenuItem(value: 3, child: Text("Đã duyệt")),
                  DropdownMenuItem(value: 4, child: Text("Không duyệt")),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => selectedStatus = val);
                },
                decoration: const InputDecoration(labelText: "Trạng thái"),
              ),
              actions: [
                TextButton(
                  child: const Text("Hủy"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text("Cập nhật"),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _updateStatus(letterId, selectedStatus);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateStatus(int letterId, int newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final uri = Uri.parse('$baseUrl/api/Letters/$letterId/update');
    final res = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(newStatus),
    );

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Cập nhật thành công"),
            backgroundColor: Colors.green),
      );
      _loadDetail();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Lỗi: ${res.statusCode}"),
            backgroundColor: Colors.red),
      );
    }
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
          return Colors.green; // Đã duyệt
        case 4:
          return Colors.red; // Không duyệt
        default:
          return Colors.orange; // Đang chờ duyệt
      }
    }();

    return Scaffold(
      appBar: AppBar(
          title: const Text('Thông tin đơn xin nghỉ',
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
                                  _buildRow(Icons.confirmation_number, 'Mã đơn',
                                      request!['code']),
                                  _buildRow(Icons.person, 'Tên nhân viên',
                                      request!['creatorName']),
                                  _buildRow(Icons.work, 'Loại nghỉ',
                                      request!['dayOffTypeName']),
                                  _buildRow(Icons.access_time, 'Buổi nghỉ',
                                      _mapOffType(request!['offTypeId'])),
                                  _buildRow(
                                      Icons.calendar_today,
                                      'Ngày bắt đầu',
                                      _formatDate(request!['fromDate'])),
                                  _buildRow(
                                      Icons.calendar_today,
                                      'Ngày kết thúc',
                                      _formatDate(request!['toDate'])),
                                  _buildRow(
                                      Icons.notes, 'Lý do', request!['reason']),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "Trạng thái đơn: ${_mapStatus(request!['statusId']).toUpperCase()}",
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (groupId == 1 || groupId == 2)
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.white, size: 18),
                                          label: const Text(
                                            "Cập nhật",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blueGrey,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            elevation: 3,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                          ),
                                          onPressed: () {
                                            _showUpdateDialog(request!['id'],
                                                request!['statusId']);
                                          },
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Chỉ hiện nút nếu pending và role là manager
                          if (request!['statusId'] == 1 &&
                              request!['canApprove'] == true)
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
                                          'Duyệt đơn',
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
                                          'Không duyệt đơn',
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
                            ),
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
        return 'Đang chờ duyệt';
      case 3:
        return 'Đã duyệt';
      case 4:
        return 'Không duyệt';
      default:
        return 'unknown';
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
