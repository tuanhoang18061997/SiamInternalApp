import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siam_internal_app/presentation/utils/language.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? resume;
  Map<String, dynamic>? profile;
  Map<String, dynamic>? config;
  bool loading = true;
  String? error;
  late TabController _tabController;

  static const String baseUrl = "http://localhost:5204";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _loadProfile();
    _loadResume();
    _loadConfig();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) {
        setState(() => error = "No token found");
        return;
      }

      final uri = Uri.parse("$baseUrl/api/Profile/config");
      final res =
          await http.get(uri, headers: {"Authorization": "Bearer $token"});
      if (res.statusCode == 200) {
        setState(() => config = jsonDecode(res.body));
      } else {
        setState(() => error = "Failed: ${res.statusCode}");
      }
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) {
        setState(() => error = "No token found");
        return;
      }

      // Gọi API Profile/profile
      final uri = Uri.parse("$baseUrl/api/Profile/profile");
      final res =
          await http.get(uri, headers: {"Authorization": "Bearer $token"});
      if (res.statusCode == 200) {
        setState(() => profile = jsonDecode(res.body));
      } else {
        setState(() => error = "Failed: ${res.statusCode}");
      }
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  Future<void> _loadResume() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) {
        setState(() => error = "No token found");
        return;
      }

      // Gọi API Profile/resume
      final uri = Uri.parse("$baseUrl/api/Profile/resume");
      final res =
          await http.get(uri, headers: {"Authorization": "Bearer $token"});
      if (res.statusCode == 200) {
        setState(() => resume = jsonDecode(res.body));
      } else {
        setState(() => error = "Failed: ${res.statusCode}");
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    return "${dt.day}/${dt.month}/${dt.year}";
  }

  String _genderText(dynamic gender) {
    if (gender == null) return '';
    if (gender.toString() == "1") return lang("male", "Nam");
    if (gender.toString() == "2") return lang("female", "Nữ");
    return '';
  }

  String _OnSaturdaySunday(dynamic status) {
    switch (status?.toString()) {
      case "0":
        return "Nghỉ";
      case "1":
        return "Buổi sáng";
      case "2":
        return "Cả ngày";
      default:
        return "";
    }
  }

  String _Phicongdoan(dynamic status) {
    switch (status?.toString()) {
      case "0":
        return "Chưa cấu hình";
      case "1":
        return "Không đóng";
      case "2":
        return "Có đóng";
      default:
        return "";
    }
  }

  String _BHTN(dynamic status) {
    switch (status?.toString()) {
      case "0":
        return "Chưa cấu hình";
      case "1":
        return "Không đóng";
      case "2":
        return "Có đóng";
      default:
        return "";
    }
  }

  String _MealSupport(dynamic status) {
    switch (status?.toString()) {
      case "0":
        return "Chưa cấu hình";
      case "1":
        return "Không hỗ trợ";
      case "2":
        return "Hỗ trợ";
      default:
        return "";
    }
  }

  String _maritalStatusText(dynamic status) {
    switch (status?.toString()) {
      case "1":
        return "Đã kết hôn";
      case "2":
        return "Độc thân";
      case "3":
        return "Ly hôn";
      case "4":
        return "Ở góa";
      default:
        return "";
    }
  }

  String _employeeStatusText(dynamic status) {
    switch (status?.toString()) {
      case "1":
        return "Thử việc";
      case "2":
        return "Nhân viên chính thức";
      case "3":
        return "Thôi việc";
      case "4":
        return "Hợp tác";
      case "5":
        return "Học Nghề - Học Việc";
      case "6":
        return "Tư vấn";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.language),
                  tooltip: 'Language',
                  onPressed: () {
                    setState(() {
                      currentLanguage = currentLanguage == "vi" ? "en" : "vi";
                    });
                  },
                ),
              ],
              bottom: TabBar(
                tabs: [
                  Tab(
                      icon: Icon(Icons.assignment),
                      text: lang("resume", "Sơ yếu lý lịch")),
                  Tab(icon: Icon(Icons.person), text: lang("profile", "Hồ sơ")),
                  Tab(
                      icon: Icon(Icons.settings),
                      text: lang("config", "Cấu hình")),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _buildResumeTab(),
              _buildProfileTab(),
              _buildConfigTab(),
            ],
          ),
        ),
      ),
    );
  }

  /// Tab 1: Sơ yếu lý lịch (Profile hiện tại)
  Widget _buildResumeTab() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text("Lỗi: $error"));
    if (resume == null)
      return Center(child: Text(lang("no_data", "Không có dữ liệu")));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade200,
                    child:
                        const Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resume!['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          resume!['code'] ?? '',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section: Thông tin cá nhân
          _buildSection(lang("personal_info", "Thông tin cá nhân"), [
            _buildInfoRow(Icons.badge, lang("attendance_code", "Mã chấm công"),
                resume!['attendanceCode']?.toString()),
            _buildInfoRow(Icons.transgender, lang("gender", "Giới tính"),
                _genderText(resume!['gender'])),
            _buildInfoRow(Icons.cake, lang("birthday", "Ngày sinh"),
                _formatDate(resume!['dateOfBirth'])),
            _buildInfoRow(
                Icons.people,
                lang("marital_status", "Tình trạng hôn nhân"),
                _maritalStatusText(resume!['maritalStatus']?.toString())),
            _buildInfoRow(Icons.flag, lang("ethnic", "Dân tộc"),
                resume!['ethnic']?.toString()),
            _buildInfoRow(Icons.church, lang("religion", "Tôn giáo"),
                resume!['religon']?.toString()),
            _buildInfoRow(
                Icons.location_city,
                lang("place_of_birth", "Nơi sinh"),
                resume!['placeOfBirth']?.toString()),
            _buildInfoRow(Icons.public, lang("country", "Quốc gia"),
                resume!['country']?.toString()),
            _buildInfoRow(Icons.email, "Email", resume!['email']),
            _buildInfoRow(
                Icons.email_outlined,
                lang("company_email", "Email công ty"),
                resume!['companyEmail']),
            _buildInfoRow(Icons.phone, lang("phone", "Di động cá nhân"),
                (resume!['mobileNumber'])),
            _buildInfoRow(
                Icons.phone,
                lang("company_phone", "Điện thoại công ty"),
                (resume!['phoneNumber'])),
            _buildInfoRow(
                Icons.home,
                lang("permanent_address", "Địa chỉ thường trú"),
                resume!['permanentAddress']),
            _buildInfoRow(
                Icons.home_work,
                lang("temporary_address", "Địa chỉ tạm trú"),
                resume!['temporaryAddress']),
            _buildInfoRow(Icons.info, lang("status", "Trạng thái"),
                _employeeStatusText(resume!['status']?.toString())),
            _buildInfoRow(
                Icons.calendar_today,
                lang("vacation_day", "Ngày phép còn lại"),
                resume!['vacationDay'].toString()),
          ]),
        ],
      ),
    );
  }

  /// Tab 2: Hồ sơ
  Widget _buildProfileTab() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text("Lỗi: $error"));
    if (profile == null) {
      return Center(child: Text(lang("no_data", "Không có dữ liệu")));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade200,
                    child:
                        const Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resume!['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          resume!['code'] ?? '',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(lang("profile_info", "Thông tin hồ sơ"), [
            _buildInfoRow(
              Icons.star,
              lang("primary", "Khoa chính"),
              (profile!['primary']?.toString() == "1") ? "Có" : "Không",
            ),
            _buildInfoRow(Icons.apartment, lang("department", "Phòng ban"),
                profile!['department']),
            _buildInfoRow(
                Icons.work, lang("position", "Chức vụ"), profile!['position']),
            _buildInfoRow(Icons.business, lang("branch", "Chi nhánh"),
                profile!['branch']),
            _buildInfoRow(
                Icons.layers, lang("block", "Khối"), profile!['block']),
          ]),
        ],
      ),
    );
  }

  /// Tab 3: Cấu hình
  Widget _buildConfigTab() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text("Lỗi: $error"));
    if (config == null) {
      return Center(child: Text(lang("no_data", "Không có dữ liệu")));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade200,
                    child:
                        const Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resume!['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          resume!['code'] ?? '',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(lang("work_config", "Cấu hình tính lương nhân viên"), [
            _buildInfoRow(Icons.fastfood, lang("meal_support", "Hỗ trợ bữa ăn"),
                _MealSupport(config!['mealSupport']?.toString())),
            _buildInfoRow(Icons.groups, lang("phi_cong_doan", "Phí công đoàn"),
                _Phicongdoan(config!['phiCongDoan']?.toString())),
            _buildInfoRow(Icons.security, lang("bhtn", "BHTN"),
                _BHTN(config!['bhtn']?.toString())),
            _buildInfoRow(
                Icons.calendar_today,
                lang("on_saturday", "Làm việc thứ 7"),
                _OnSaturdaySunday(config!['onSaturday']?.toString())),
            _buildInfoRow(
                Icons.calendar_today,
                lang("on_sunday", "Làm việc chủ nhật"),
                _OnSaturdaySunday(config!['onSunday']?.toString())),
            _buildInfoRow(
              Icons.access_time,
              lang("morning", "Buổi sáng"),
              "${config!['morningIn']} đến ${config!['morningOut']}",
            ),
            _buildInfoRow(Icons.access_time, lang("afternoon", "Buổi chiều"),
                "${config!['afternoonIn']} đến ${config!['afternoonOut']}"),
            _buildInfoRow(Icons.work, lang("work_hours", "Giờ làm việc"),
                "${config!['workHours']} giờ / ngày"),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.blue),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(value ?? ''),
    );
  }
}
