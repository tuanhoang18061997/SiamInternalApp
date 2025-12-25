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
    return Scaffold(
      appBar: AppBar(title: const Text('New Leave Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 6,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // OffType
                  DropdownButtonFormField<String>(
                    value: _selectedOffType,
                    items: ['Full Day', 'Morning', 'Afternoon']
                        .map((type) =>
                            DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedOffType = val!),
                    decoration: const InputDecoration(
                      labelText: 'Off Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // DayOffType
                  DropdownButtonFormField<int>(
                    value: _selectedDayOffTypeId,
                    items: _dayOffTypes.map((type) {
                      return DropdownMenuItem<int>(
                        value: type["id"],
                        child: Text(type["name"]),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedDayOffTypeId = val),
                    decoration: const InputDecoration(
                      labelText: 'Day Off Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Start / End
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: Text("Start: ${_formatDate(_startDate)}"),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () => _pickDate(isStart: true),
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: Text("End: ${_formatDate(_endDate)}"),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () => _pickDate(isStart: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Reason
                  TextFormField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (v) =>
                        v == null || v.isEmpty ? "Please enter reason" : null,
                  ),
                  const SizedBox(height: 16),

                  // Replace Person
                  TextFormField(
                    controller: _replaceController,
                    decoration: const InputDecoration(
                      labelText: 'Replace Person (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.blue,
                        elevation: 5,
                      ),
                      child: _submitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "SUBMIT REQUEST",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
