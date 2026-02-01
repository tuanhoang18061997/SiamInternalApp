import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '/presentation/utils/language.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/presentation/providers/auth_provider.dart';

class LeaveRequestDetailScreen extends ConsumerStatefulWidget {
  const LeaveRequestDetailScreen({required this.requestId, super.key});
  final String requestId;

  @override
  ConsumerState<LeaveRequestDetailScreen> createState() =>
      _LeaveRequestDetailScreenState();
}

class _LeaveRequestDetailScreenState
    extends ConsumerState<LeaveRequestDetailScreen> {
  Map<String, dynamic>? request;
  bool loading = true;
  String? error;
  int groupId = 0; // role hiện tại lấy từ API

  final baseUrl = dotenv.env['API_BASE_URL'];

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _deleteDraft(int letterId) async {
    final token = ref.read(authProvider).value?.token;
    if (token == null) return;

    final uri = Uri.parse('$baseUrl/api/Letters/$letterId/delete');
    final res = await http.delete(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Đã xóa đơn nháp thành công'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Lỗi: ${res.statusCode} - ${res.body}'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _confirmDelete(int letterId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa đơn nháp'),
        content: const Text('Bạn có muốn xóa đơn nháp này không?'),
        actions: [
          TextButton(
            child: const Text('Hủy'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Đồng ý'),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteDraft(letterId);
            },
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog(int letterId, int currentStatus) {
    int selectedStatus = currentStatus;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Cập nhật trạng thái đơn'),
              content: DropdownButtonFormField<int>(
                initialValue: selectedStatus,
                items: [
                  DropdownMenuItem(value: 2, child: Text('Đang chờ duyệt')),
                  DropdownMenuItem(value: 3, child: Text('Đã duyệt')),
                  DropdownMenuItem(value: 4, child: Text('Không duyệt')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => selectedStatus = val);
                },
                decoration: InputDecoration(labelText: 'Trạng thái'),
              ),
              actions: [
                TextButton(
                  child: Text('Hủy'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: Text('Cập nhật'),
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

  Future<void> _submitDraft(int letterId) async {
    final fromDate = DateTime.tryParse(request?['fromDate'] ?? '');
    final toDate = DateTime.tryParse(request?['toDate'] ?? '');
    final today = DateTime.now();

    if ((fromDate != null && fromDate.weekday == DateTime.sunday) ||
        (toDate != null && toDate.weekday == DateTime.sunday)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thông báo'),
          content: const Text('Không thể gửi hoặc lưu đơn nghỉ vào Chủ Nhật'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (fromDate != null && fromDate.isBefore(today) ||
        toDate != null && toDate.isBefore(today)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thông báo'),
          content: const Text('Ngày đã qua không thể gửi đơn nghỉ'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    if (fromDate != null && toDate != null && toDate.isBefore(fromDate)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thông báo'),
          content: const Text('Ngày kết thúc không thể trước ngày bắt đầu'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final token = ref.read(authProvider).value?.token;
    if (token == null) return;

    final uri = Uri.parse('$baseUrl/api/Letters/$letterId/submit');
    final res = await http.put(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (res.statusCode == 200) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Thông báo'),
          content: Text('Đã gửi đơn nghỉ thành công'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      String message;
      try {
        final data = jsonDecode(res.body);
        message = data['message'] ?? res.body;
      } catch (_) {
        message = res.body;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Thông báo'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _updateStatus(int letterId, int newStatus) async {
    final token = ref.read(authProvider).value?.token;
    if (token == null) return;

    final uri = Uri.parse('$baseUrl/api/Letters/$letterId/update');
    final res = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: newStatus.toString(),
    );

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cập nhật thành công'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${res.statusCode} - ${res.body}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _callAction(String action) async {
    final currentStatus = request?['statusId'];
    if (action == 'approve' && currentStatus == 3) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thông báo'),
          content: const Text('Đơn này đã ở trạng thái Đã duyệt'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    if (action == 'reject' && currentStatus == 4) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thông báo'),
          content: const Text('Đơn này đã ở trạng thái Không duyệt'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    try {
      final token = ref.read(authProvider).value?.token;
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
        _loadDetail();
        Navigator.pop(context, true);
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
      final token = ref.read(authProvider).value?.token;
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
        case 1:
          return Colors.blueGrey;
        case 2:
          return Colors.orange;
        case 3:
          return Colors.green; // Đã duyệt
        case 4:
          return Colors.red; // Không duyệt
        default:
          return Colors.grey; // Đang chờ duyệt
      }
    }();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true); // 👉 báo cho Home reload
          },
        ),
        title: Text(
          'Thông tin đơn xin nghỉ',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          if (request?['statusId'] == 1) // chỉ hiện khi là nháp
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                _confirmDelete(request!['id']);
              },
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Lỗi: $error'))
              : request == null
                  ? Center(child: Text('Không có dữ liệu'))
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
                                  _buildRow(Icons.calendar_view_day,
                                      'Số ngày nghỉ', request!['daysOff']),
                                  _buildRow(Icons.people, 'Người thay thế',
                                      request!['replacePerson']),
                                  _buildRow(
                                      Icons.notes, 'Lý do', request!['reason']),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.circle,
                                                size: 10, color: statusColor),
                                            const SizedBox(width: 6),
                                            Text(
                                              _mapStatus(request!['statusId'])
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                color: statusColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (groupId == 1 || groupId == 2)
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blueGrey),
                                          tooltip: 'Cập nhật trạng thái',
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

                          if (request!['statusId'] == 1)
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.send,
                                        color: Colors.white),
                                    label: Text(
                                      'Gửi đơn nghỉ',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    onPressed: () async {
                                      await _submitDraft(request!['id']);
                                    },
                                  ),
                                ),
                                const SizedBox(
                                    width: 12), // khoảng cách giữa 2 nút
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueGrey,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.edit,
                                        color: Colors.white),
                                    label: Text(
                                      'Sửa thông tin',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    onPressed: () async {
                                      final result = await context.push(
                                          '/create-leave-request',
                                          extra: request);
                                      if (result == true) {
                                        _loadDetail();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),

                          // Chỉ hiện nút nếu pending và role là manager
                          if (request!['statusId'] == 2 &&
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
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.check,
                                            color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Duyệt đơn',
                                          style: const TextStyle(
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
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.close,
                                            color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Không duyệt đơn',
                                          style: const TextStyle(
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
                          // Nếu đơn đã duyệt hoặc từ chối và user có quyền thay đổi quyết định
                          if ((request!['statusId'] == 3 ||
                                  request!['statusId'] == 4) &&
                              request!['canApprove'] == true &&
                              groupId != 1 &&
                              groupId != 2)
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
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.check,
                                            color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text(
                                          'DUYỆT',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
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
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.close,
                                            color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text(
                                          'KHÔNG DUYỆT',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
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
        return 'Đơn nháp';
      case 2:
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
