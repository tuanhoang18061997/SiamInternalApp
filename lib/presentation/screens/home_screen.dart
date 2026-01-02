import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '/presentation/providers/auth_provider.dart';
import '/presentation/providers/theme_provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import '/presentation/utils/language.dart';

class LeaveRequest {
  LeaveRequest({
    required this.id,
    required this.employeeName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.statusId,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    final rawStatusId = json['statusId'];
    final statusId = rawStatusId is int
        ? rawStatusId
        : int.tryParse(rawStatusId?.toString() ?? '') ?? 0;

    return LeaveRequest(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      employeeName: json['creatorName']?.toString() ?? '',
      leaveType: json['dayOffTypeName']?.toString() ?? '',
      startDate: _parseDate(json['fromDate']),
      endDate: _parseDate(json['toDate']),
      reason: json['reason']?.toString() ?? '',
      statusId: statusId,
    );
  }
  final int id;
  final String employeeName;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final int statusId;

  String get statusText {
    switch (statusId) {
      case 1:
        return lang('status_pending', 'Đang chờ duyệt');
      case 3:
        return lang('status_approved', 'Đã duyệt');
      case 4:
        return lang('status_rejected', 'Không duyệt');
      default:
        return '';
    }
  }

  static DateTime _parseDate(dynamic v) {
    final s = v?.toString();
    final d = s != null ? DateTime.tryParse(s) : null;
    return d ?? DateTime.now();
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<LeaveRequest> _all = [];
  bool _initialLoading = true;
  String? _error;
  String _searchQuery = '';
  bool _showSearch = false;
  String? _displayName;
  late final TabController _tabController;
  late final ScrollController _scrollController;
  bool _loadingMore = false;
  final bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 50;
  int? _totalDays;
  double? _usedDays;
  double? _remainingDays;
  bool _loadingBalance = true;
  int? _groupId;

  static const String baseUrl = 'http://localhost:5204';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadUserInfo();
    _loadData();
  }

  Future<void> _exportReport(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final uri =
        Uri.parse('$baseUrl/api/Letters/export?year=$year&month=$month');
    final res =
        await http.get(uri, headers: {'Authorization': 'Bearer $token'});

    if (res.statusCode == 200) {
      if (kIsWeb) {
        final bytes = res.bodyBytes;
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "LeaveReport_${year}_${month}.csv")
          ..click();
        html.Url.revokeObjectUrl(url);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Export thành công")),
          );
        }
      } else {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/LeaveReport_${year}_${month}.csv';
        final file = File(filePath);
        await file.writeAsBytes(res.bodyBytes);
        await OpenFile.open(filePath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${lang('export_success', 'Export thành công')}: ${year}_${month}.csv'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${lang('export_failed', 'Export thất bại')}: ${res.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    setState(() {
      _currentPage++;
      _loadingMore = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_loadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _displayName = prefs.getString('displayName') ?? 'User';
      _groupId = prefs.getInt('groupId');
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _initialLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        setState(() => _error = 'No token found');
        return;
      }

      final uri = Uri.parse('$baseUrl/api/Letters');
      final res =
          await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        List<dynamic> data;
        if (body is Map<String, dynamic>) {
          data = (body['items'] as List?) ?? [];
        } else if (body is List) {
          data = body;
        } else {
          data = [];
        }
        final newItems = data
            .whereType<Map<String, dynamic>>()
            .map((e) => LeaveRequest.fromJson(e))
            .where((r) => r.statusId != 0)
            .toList();

        setState(() => _all = newItems);
      } else {
        setState(() => _error = 'Failed: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _initialLoading = false);
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final filtered = _searchQuery.isEmpty
        ? _all
        : _all.where((r) {
            final q = _searchQuery.toLowerCase();
            return r.employeeName.toLowerCase().contains(q) ||
                r.reason.toLowerCase().contains(q) ||
                r.leaveType.toLowerCase().contains(q);
          }).toList();

    final pending = filtered.where((r) => r.statusId == 1).toList();
    final approved = filtered.where((r) => r.statusId == 3).toList();
    final rejected = filtered.where((r) => r.statusId == 4).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang('title_list', 'Danh sách đơn'),
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: lang('status_pending', 'Đang chờ duyệt')),
            Tab(text: lang('status_approved', 'Đã duyệt')),
            Tab(text: lang('status_rejected', 'Không duyệt')),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'Language',
            onPressed: () {
              setState(() {
                currentLanguage = currentLanguage == "vi" ? "en" : "vi";
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'export':
                  final now = DateTime.now();
                  int selectedMonth = now.month;
                  int selectedYear = now.year;
                  await showDialog(
                    context: context,
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (context, setState) {
                          return AlertDialog(
                            title:
                                Text(lang('export_report', 'Xuất danh sách ')),
                            content: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                DropdownButton<int>(
                                  value: selectedMonth,
                                  items: List.generate(12, (i) {
                                    final month = i + 1;
                                    return DropdownMenuItem(
                                      value: month,
                                      child: Text(
                                          '${lang('month', 'Tháng')} $month'),
                                    );
                                  }),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => selectedMonth = val);
                                    }
                                  },
                                ),
                                DropdownButton<int>(
                                  value: selectedYear,
                                  items: List.generate(5, (i) {
                                    final year = now.year - 2 + i;
                                    return DropdownMenuItem(
                                      value: year,
                                      child:
                                          Text('${lang('year', 'Năm')} $year'),
                                    );
                                  }),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => selectedYear = val);
                                    }
                                  },
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                child: Text(lang('cancel', 'Hủy')),
                                onPressed: () => Navigator.pop(context),
                              ),
                              ElevatedButton(
                                child: Text(
                                    lang('export_report', 'Xuất danh sách ')),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await _exportReport(
                                      selectedYear, selectedMonth);
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                  break;
                case 'refresh':
                  _loadData();
                  break;
                case 'theme':
                  final mode = ref.read(themeModeProvider);
                  final notifier = ref.read(themeModeProvider.notifier);
                  notifier.state =
                      mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                  break;
                case 'logout':
                  await ref.read(authProvider.notifier).logout();
                  if (!mounted) return;
                  GoRouter.of(context).refresh();
                  context.go('/');
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text('$_displayName'),
                ),
              ),
              if (_groupId == 1 || _groupId == 2)
                PopupMenuItem(
                  value: 'export',
                  child: ListTile(
                    leading: const Icon(Icons.download),
                    title: Text(lang('export_report', 'Xuất danh sách')),
                  ),
                ),
              PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text(lang('refresh', 'Làm mới')),
                ),
              ),
              PopupMenuItem(
                value: 'theme',
                child: ListTile(
                  leading: Icon(Icons.brightness_6),
                  title: Text(lang('theme', 'Sáng/tối')),
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: lang(
                      'search_hint', 'Tìm theo tên, lý do hoặc loại nghỉ...'),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                onSubmitted: (value) {
                  setState(() {
                    _searchQuery = value;
                    _showSearch = false;
                  });
                },
              ),
            ),
          Expanded(
            child: _initialLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('${lang('error', 'Lỗi')}: $_error'))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildList(pending),
                          _buildList(approved),
                          _buildList(rejected),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-leave-request'),
        icon: const Icon(Icons.add),
        label: Text(lang('create_new', 'Tạo đơn mới')),
      ),
    );
  }

  Widget _buildList(List<LeaveRequest> requests) {
    return requests.isEmpty
        ? Center(child: Text(lang('no_data', 'Không có dữ liệu')))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            controller: _scrollController,
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];

              // Lấy chuỗi trạng thái
              final statusColor = switch (request.statusId) {
                3 => Colors.green,
                4 => Colors.red,
                _ => Colors.orange,
              };

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => context.push('/leave-request/${request.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              request.employeeName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Chip(
                              label: Text(request.statusText.toUpperCase()),
                              backgroundColor: statusColor.withOpacity(0.2),
                              labelStyle: TextStyle(color: statusColor),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.work,
                                size: 16, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Text(request.leaveType),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Text(
                                '${_formatDate(request.startDate)} - ${_formatDate(request.endDate)}'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.notes,
                                size: 16, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Expanded(child: Text(request.reason)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }
}
