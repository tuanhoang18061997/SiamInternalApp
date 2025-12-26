import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  String _selectedOffType = 'Full Day';
  int? _selectedDayOffTypeId;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _submitting = false;
  List<Map<String, dynamic>> _dayOffTypes = [];

  static const String baseUrl = "http://localhost:5204";

  @override
  void initState() {
    super.initState();
    _loadDayOffTypes();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDayOffTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please select Day Off Type"),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("No token found"), backgroundColor: Colors.red),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Request submitted successfully"),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed: ${res.statusCode}"),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
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
        title: const Text(
          'New Leave Request',
          style: TextStyle(
            color: Colors.white,
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
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.event_note, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Text(
                        "Leave details",
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
                    items: ['Full Day', 'Morning', 'Afternoon']
                        .map((type) =>
                            DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedOffType = val!),
                    decoration: const InputDecoration(
                      labelText: 'Off Type',
                      prefixIcon:
                          const Icon(Icons.access_time, color: Colors.indigo),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // DayOffType dropdown
                  _dayOffTypes.isEmpty
                      ? const LinearProgressIndicator(minHeight: 4)
                      : DropdownButtonFormField<int>(
                          value: _selectedDayOffTypeId,
                          items: _dayOffTypes.map((type) {
                            return DropdownMenuItem<int>(
                              value: type["id"],
                              child: Text(type["name"]),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedDayOffTypeId = val),
                          decoration: InputDecoration(
                            labelText: 'Day off type',
                            prefixIcon: const Icon(Icons.work_outline,
                                color: Colors.indigo),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) =>
                              v == null ? "Please select day off type" : null,
                        ),
                  const SizedBox(height: 20),

                  // Start / End date
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _pickDate(isStart: true),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Start date',
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
                              labelText: 'End date',
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
                      labelText: 'Reason',
                      hintText: 'Ví dụ: Khám bệnh',
                      prefixIcon: const Icon(Icons.notes, color: Colors.indigo),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 3,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? "Please enter reason"
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Replace Person
                  TextFormField(
                    controller: _replaceController,
                    decoration: InputDecoration(
                      labelText: 'Replace person (optional)',
                      hintText: 'Tên người thay thế',
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
                        _submitting ? "Submitting..." : "Submit request",
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
