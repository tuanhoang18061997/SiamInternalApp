import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siam_internal_app/presentation/utils/language.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '/presentation/providers/auth_provider.dart';

class CreateLeaveRequestScreen extends ConsumerStatefulWidget {
  const CreateLeaveRequestScreen({super.key, this.args});
  final Map<String, dynamic>? args;

  @override
  ConsumerState<CreateLeaveRequestScreen> createState() =>
      _CreateLeaveRequestScreenState();
}

class _CreateLeaveRequestScreenState
    extends ConsumerState<CreateLeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _replaceController = TextEditingController();

  String? _selectedOffType;
  int? _selectedDayOffTypeId;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _submitting = false;
  List<Map<String, dynamic>> _dayOffTypes = [];
  bool _loadingBalance = true;
  double? _remainingDays;
  double? _compensationDays;
  String? _error;

  final baseUrl = dotenv.env['API_BASE_URL'];

  @override
  void initState() {
    super.initState();
    _loadDayOffTypes();
    _loadVacationBalance();
  }

  int? _editingId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = widget.args;
    if (args != null) {
      _editingId = args['id']; // lấy id đơn nháp
      _reasonController.text = args['reason'] ?? '';
      _replaceController.text = args['replacePerson'] ?? '';
      _startDate = DateTime.tryParse(args['fromDate']) ?? DateTime.now();
      _endDate = DateTime.tryParse(args['toDate']) ?? DateTime.now();

      final dynamicTypeId = args['dayOffTypeId'];
      _selectedDayOffTypeId = (dynamicTypeId is int)
          ? dynamicTypeId
          : int.tryParse(dynamicTypeId?.toString() ?? '');

      _selectedOffType = _mapOffType(args['offTypeId']);
    }
  }

  String _mapOffType(dynamic offTypeId) {
    switch (offTypeId) {
      case 1:
        return 'Morning';
      case 2:
        return 'Afternoon';
      case 3:
        return 'Full Day';
      default:
        return 'Full Day';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final today = DateTime.now();
    if (_startDate.isBefore(today) || _endDate.isBefore(today)) {
      _showDialog(
        'Thông báo',
        'Ngày đã qua không thể lưu nháp đơn nghỉ',
      );
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      _showDialog(
        'Thông báo',
        'Ngày kết thúc không thể trước ngày bắt đầu',
      );
      return;
    }
    if (_startDate.weekday == DateTime.sunday ||
        _endDate.weekday == DateTime.sunday) {
      _showDialog(
        'Thông báo',
        'Không thể lưu nháp đơn nghỉ vào Chủ Nhật',
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final token = ref.read(authProvider).value?.token;
      if (token == null) return;

      final body = {
        'fromDate': _startDate.toIso8601String(),
        'toDate': _endDate.toIso8601String(),
        'dayOffTypeId': _selectedDayOffTypeId,
        'offTypeId': _selectedOffType == 'Full Day'
            ? 3
            : _selectedOffType == 'Afternoon'
                ? 2
                : 1,
        'reason': _reasonController.text,
        'replacePerson': _replaceController.text,
      };

      http.Response res;
      if (_editingId != null) {
        // 👉 sửa đơn nháp
        final uri = Uri.parse('$baseUrl/api/Letters/$_editingId/edit');
        res = await http.put(uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json'
            },
            body: jsonEncode(body));
      } else {
        // 👉 tạo mới đơn nháp
        final uri = Uri.parse('$baseUrl/api/Letters');
        res = await http.post(uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json'
            },
            body: jsonEncode({...body, 'statusId': 1}));
      }

      if (res.statusCode == 200) {
        _showDialog(
          'Thông báo',
          _editingId == null
              ? 'Đã lưu nháp đơn nghỉ thành công'
              : 'Đã cập nhật đơn nháp thành công',
          onOk: () {
            Navigator.pop(context, true);
          },
        );
      } else {
        _showDialog('Thông báo', '${res.body}');
      }
    } catch (e) {
      _showDialog('Thông báo', 'Unexpected error: $e');
    } finally {
      setState(() => _submitting = false);
    }
  }

  Future<void> _loadVacationBalance() async {
    setState(() => _loadingBalance = true);
    try {
      final token = ref.read(authProvider).value?.token;
      if (token == null) return;

      final uri = Uri.parse('$baseUrl/api/Letters/balance');
      final res =
          await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _remainingDays = (data['vacationDay'] as num).toDouble();
          _compensationDays = (data['compensationDay'] as num).toDouble();
        });
      } else {
        setState(() {
          _error = 'Failed to load balance: ${res.statusCode}';
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loadingBalance = false);
    }
  }

  Future<void> _loadDayOffTypes() async {
    try {
      final token = ref.read(authProvider).value?.token;
      if (token == null) return;

      final uri = Uri.parse('$baseUrl/api/Letters/dayofftypes');
      final res =
          await http.get(uri, headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _dayOffTypes = data.map((e) {
            final map = Map<String, dynamic>.from(e);
            final dynamicId = map['id'];
            map['id'] = (dynamicId is int)
                ? dynamicId
                : int.tryParse(dynamicId.toString());
            return map;
          }).toList();

          if (_dayOffTypes.isNotEmpty) {
            if (_selectedDayOffTypeId != null) {
              // 👉 sửa nháp: kiểm tra id có tồn tại trong danh sách không
              final exists =
                  _dayOffTypes.any((t) => t['id'] == _selectedDayOffTypeId);
              if (!exists) {
                _selectedDayOffTypeId =
                    null; // fallback về "Vui lòng chọn loại ngày nghỉ"
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading dayofftypes: $e');
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _showDialog(String title, String message, {VoidCallback? onOk}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.indigo.shade50,
        title: Row(
          children: [
            const Icon(Icons.info, color: Colors.indigo),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo)),
          ],
        ),
        content: Text(message,
            style: const TextStyle(fontSize: 16, color: Colors.black87)),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('OK',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(context);
              if (onOk != null) onOk();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDayOffTypeId == null) {
      _showDialog('Thông báo', 'Vui lòng chọn loại ngày nghỉ');
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      _showDialog('Thông báo', 'Vui lòng nhập lý do');
      return;
    }

    final today = DateTime.now();
    if (_startDate.isBefore(today) || _endDate.isBefore(today)) {
      _showDialog('Thông báo', 'Ngày đã qua không thể chọn để tạo đơn nghỉ');
      return;
    }

    if (_endDate.isBefore(_startDate)) {
      _showDialog(
        'Thông báo',
        'Ngày kết thúc không thể trước ngày bắt đầu',
      );
      return;
    }

    if (_startDate.weekday == DateTime.sunday ||
        _endDate.weekday == DateTime.sunday) {
      _showDialog(
        'Thông báo',
        'Không thể tạo đơn nghỉ vào Chủ Nhật',
      );
      return;
    }

    if (_startDate != _endDate &&
        (_selectedOffType == 'Morning' || _selectedOffType == 'Afternoon')) {
      _showDialog('Thông báo',
          'Không thể tạo đơn buổi sáng/chiều cho nhiều ngày liên tiếp. Vui lòng chọn Cả ngày');
      return;
    }

    if (_selectedDayOffTypeId == 1 && _remainingDays != null) {
      double totalDays;
      if (_selectedOffType == 'Morning' || _selectedOffType == 'Afternoon') {
        totalDays = 0.5;
      } else {
        totalDays = _endDate.difference(_startDate).inDays + 1;
      }
      if (_remainingDays! < totalDays) {
        _showDialog('Thông báo',
            '${'Bạn không đủ ngày phép để tạo đơn này. Ngày phép còn lại'}: $_remainingDays');
        return;
      }
    }

    setState(() => _submitting = true);

    try {
      final token = ref.read(authProvider).value?.token;
      if (token == null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('No token found'),
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

      // Map offTypeId: Full Day=3, Afternoon=2, Morning=1
      final offTypeId = switch (_selectedOffType) {
        'Full Day' => 3,
        'Afternoon' => 2,
        'Morning' => 1,
        _ => 3,
      };

      final body = {
        'fromDate': _startDate.toIso8601String(),
        'toDate': _endDate.toIso8601String(),
        'dayOffTypeId': _selectedDayOffTypeId,
        'offTypeId': offTypeId,
        'reason': _reasonController.text,
        'replacePerson': _replaceController.text,
        'statusId': 2
      };

      final uri = Uri.parse('$baseUrl/api/Letters');
      final res = await http.post(uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(body));

      if (res.statusCode == 200) {
        // ✅ Thành công
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.indigo.shade50,
            title: Row(
              children: [
                const Icon(Icons.info, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  'Thông báo',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
            content: Text(
              'Bạn đã tạo đơn nghỉ thành công',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            actionsAlignment: MainAxisAlignment.end,
            actions: [
              ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text(
                    'OK',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => {
                        Navigator.pop(context),
                        Navigator.pop(context),
                      }),
            ],
          ),
        );
      } else {
        String message;
        try {
          final data = jsonDecode(res.body);
          message = data['title'] ?? data['message'] ?? res.body;
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
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Thông báo'),
          content: Text('Unexpected error: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editingId == null ? 'Tạo đơn nghỉ phép' : 'Sửa đơn nghỉ phép',
          style: const TextStyle(
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
          ),
        ),
        backgroundColor: Colors.indigo,
        elevation: 3,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 6,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_note, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Text(
                        'Thông tin đơn nghỉ',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  //OffType drop
                  DropdownButtonFormField<String>(
                    initialValue: _selectedOffType,
                    items: [
                      DropdownMenuItem(
                          value: null, child: Text('Vui lòng chọn buổi nghỉ')),
                      DropdownMenuItem(
                          value: 'Full Day', child: Text('Cả ngày')),
                      DropdownMenuItem(
                          value: 'Morning', child: Text('Buổi sáng')),
                      DropdownMenuItem(
                          value: 'Afternoon', child: Text('Buổi chiều')),
                    ],
                    onChanged: (val) => setState(() => _selectedOffType = val),
                    validator: (v) =>
                        v == null ? 'Vui lòng chọn buổi nghỉ' : null,
                    decoration: InputDecoration(
                      labelText: 'Buổi nghỉ',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // DayOffType dropdown
                  _dayOffTypes.isEmpty
                      ? const LinearProgressIndicator(minHeight: 4)
                      : DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: _selectedDayOffTypeId,
                          items: [
                            DropdownMenuItem(
                                value: null,
                                child: Text('Vui lòng chọn loại ngày nghỉ')),
                            ..._dayOffTypes.map((type) {
                              return DropdownMenuItem<int>(
                                value: type['id'],
                                child: Text(type['name']),
                              );
                            }),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedDayOffTypeId = val),
                          validator: (v) =>
                              v == null ? 'Vui lòng chọn loại ngày nghỉ' : null,
                          decoration: InputDecoration(
                            labelText: 'Loại ngày nghỉ',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _pickDate(isStart: true),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Ngày bắt đầu',
                              prefixIcon: const Icon(Icons.calendar_today,
                                  color: Colors.indigo),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(_formatDate(_startDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _pickDate(isStart: false),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Ngày kết thúc',
                              prefixIcon: const Icon(Icons.calendar_today,
                                  color: Colors.indigo),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(_formatDate(_endDate)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Reason
                  TextFormField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      labelText: 'Lý do',
                      hintText: 'Ví dụ: Khám bệnh',
                      prefixIcon: const Icon(Icons.notes, color: Colors.indigo),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 3,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Vui lòng nhập lý do xin nghỉ'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Replace Person
                  TextFormField(
                    controller: _replaceController,
                    decoration: InputDecoration(
                      labelText: 'Người bàn giao',
                      hintText: 'Tên người bàn giao',
                      prefixIcon: const Icon(Icons.person_outline,
                          color: Colors.indigo),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _submitting ? null : _save,
                          icon: const Icon(Icons.save),
                          label: Text(
                            'Lưu nháp',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                        ),
                      ),
                      if (widget.args == null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _submitting ? null : _submit,
                            icon: const Icon(Icons.send),
                            label: Text(
                              'Gửi đơn nghỉ',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),

                  const SizedBox(height: 20),
                  if (_remainingDays != null || _compensationDays != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          if (_remainingDays != null)
                            Card(
                              color: Colors.green.shade50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.calendar_today,
                                    color: Colors.green),
                                title: Text(
                                  'Ngày phép còn lại',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                trailing: Text(
                                  '$_remainingDays',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ),
                          if (_compensationDays != null)
                            Card(
                              color: Colors.orange.shade50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.access_time,
                                    color: Colors.orange),
                                title: Text(
                                  'Ngày bù còn lại',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                trailing: Text(
                                  '$_compensationDays',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
