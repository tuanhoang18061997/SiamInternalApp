import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siam_internal_app/presentation/utils/language.dart';

class CreateLeaveRequestScreen extends StatefulWidget {
  const CreateLeaveRequestScreen({super.key});

  @override
  State<CreateLeaveRequestScreen> createState() =>
      _CreateLeaveRequestScreenState();
}

class _CreateLeaveRequestScreenState extends State<CreateLeaveRequestScreen> {
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
  String? _error;

  static const String baseUrl = "http://localhost:5204";

  @override
  void initState() {
    super.initState();
    _loadDayOffTypes();
    _loadVacationBalance();
  }

  Future<void> _loadVacationBalance() async {
    setState(() => _loadingBalance = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) return;

      final uri = Uri.parse("$baseUrl/api/Letters/balance");
      final res =
          await http.get(uri, headers: {"Authorization": "Bearer $token"});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _remainingDays = (data["vacationDay"] as num).toDouble();
        });
      } else {
        setState(() {
          _error = "Failed to load balance: ${res.statusCode}";
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) return;

      final uri = Uri.parse("$baseUrl/api/Letters/dayofftypes");
      final res =
          await http.get(uri, headers: {"Authorization": "Bearer $token"});
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _dayOffTypes = data.cast<Map<String, dynamic>>();
          if (_dayOffTypes.isNotEmpty) {
            _selectedDayOffTypeId = _dayOffTypes.first["id"];
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading dayofftypes: $e");
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
            label: const Text("OK",
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

    final today = DateTime.now();
    if (_startDate.isBefore(today) || _endDate.isBefore(today)) {
      _showDialog(
          lang('notification', 'Thông báo'),
          lang(
              'past_date_error', 'Ngày đã qua không thể chọn để tạo đơn nghỉ'));
      return;
    }

    if (_startDate != _endDate &&
        (_selectedOffType == "Morning" || _selectedOffType == "Afternoon")) {
      _showDialog(
          lang('notification', 'Thông báo'),
          lang('cannot_create_session',
              'Không thể tạo đơn buổi sáng/chiều cho nhiều ngày liên tiếp. Vui lòng chọn Cả ngày'));
      return;
    }
    if (_selectedDayOffTypeId == 1 && _remainingDays != null) {
      double totalDays;
      if (_selectedOffType == "Morning" || _selectedOffType == "Afternoon") {
        totalDays = 0.5;
      } else {
        totalDays = _endDate.difference(_startDate).inDays + 1;
      }
      if (_remainingDays! < totalDays) {
        _showDialog(lang('notification', 'Thông báo'),
            '${lang('not_enough_days', 'Bạn không đủ ngày phép để tạo đơn này. Ngày phép còn lại')}: $_remainingDays');
        return;
      }
    }
    setState(() => _submitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error"),
            content: const Text("No token found"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
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
        "fromDate": _startDate.toIso8601String(),
        "toDate": _endDate.toIso8601String(),
        "dayOffTypeId": _selectedDayOffTypeId,
        "offTypeId": offTypeId,
        "reason": _reasonController.text,
        "replacePerson": _replaceController.text
      };

      final uri = Uri.parse("$baseUrl/api/Letters");
      final res = await http.post(uri,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json"
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
                Icon(Icons.info, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  lang('notification', 'Thông báo'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
            content: Text(
              lang('create_success', 'Bạn đã tạo đơn nghỉ thành công'),
              style: TextStyle(
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
                    "OK",
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
          message = data["title"] ?? data["message"] ?? res.body;
        } catch (_) {
          message = res.body;
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(lang('notification', 'Thông báo')),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(lang('notification', 'Thông báo')),
          content: Text("Unexpected error: $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  String _formatDate(DateTime d) => "${d.day}/${d.month}/${d.year}";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang('create_leave_request', 'Tạo đơn nghỉ phép'),
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
            )),
        backgroundColor: Colors.indigo,
        elevation: 3,
        foregroundColor: Colors.white,
        actions: [
          if (_loadingBalance)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else if (_remainingDays != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${lang('remaining_days', 'Ngày phép còn lại')}: $_remainingDays ',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
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
                        lang('leave_request_detail', 'Thông tin đơn nghỉ'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  //OffType drop
                  DropdownButtonFormField<String>(
                    value: _selectedOffType,
                    items: [
                      DropdownMenuItem(
                          value: null,
                          child: Text(lang(
                              'select_session', 'Vui lòng chọn buổi nghỉ'))),
                      DropdownMenuItem(
                          value: "Full Day",
                          child: Text(lang('full_day', 'Cả ngày'))),
                      DropdownMenuItem(
                          value: "Morning",
                          child: Text(lang('morning', 'Buổi sáng'))),
                      DropdownMenuItem(
                          value: "Afternoon",
                          child: Text(lang('afternoon', 'Buổi chiều'))),
                    ],
                    onChanged: (val) => setState(() => _selectedOffType = val),
                    validator: (v) => v == null
                        ? lang('select_session', 'Vui lòng chọn buổi nghỉ')
                        : null,
                    decoration: InputDecoration(
                      labelText: lang('session', 'Buổi nghỉ'),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // DayOffType dropdown
                  _dayOffTypes.isEmpty
                      ? const LinearProgressIndicator(minHeight: 4)
                      : DropdownButtonFormField<int>(
                          items: [
                            DropdownMenuItem(
                                value: null,
                                child: Text(lang('select_leave_type',
                                    'Vui lòng chọn loại ngày nghỉ'))),
                            ..._dayOffTypes.map((type) {
                              return DropdownMenuItem<int>(
                                value: type["id"],
                                child: Text(type["name"]),
                              );
                            }).toList(),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedDayOffTypeId = val),
                          validator: (v) => v == null
                              ? lang('select_leave_type',
                                  'Vui lòng chọn loại ngày nghỉ')
                              : null,
                          decoration: InputDecoration(
                            labelText: lang('leave_type', 'Loại ngày nghỉ'),
                            border: OutlineInputBorder(),
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
                              labelText: lang('start_date', 'Ngày bắt đầu'),
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
                              labelText: lang('end_date', 'Ngày kết thúc'),
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
                      labelText: lang('reason', 'Lý do'),
                      hintText: lang('reason_hint', 'Ví dụ: Khám bệnh'),
                      prefixIcon: const Icon(Icons.notes, color: Colors.indigo),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 3,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? lang('enter_reason', 'Vui lòng nhập lý do xin nghỉ')
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Replace Person
                  TextFormField(
                    controller: _replaceController,
                    decoration: InputDecoration(
                      labelText: lang('replace', 'Người bàn giao'),
                      hintText: lang('replace_hint', 'Tên người bàn giao'),
                      prefixIcon: const Icon(Icons.person_outline,
                          color: Colors.indigo),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        _submitting
                            ? lang('submitting', 'Đang gửi...')
                            : lang('submit_leave', 'Gửi đơn nghỉ'),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
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
