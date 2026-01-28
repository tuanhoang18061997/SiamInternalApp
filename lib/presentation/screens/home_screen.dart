import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '/presentation/providers/auth_provider.dart';
import '/presentation/providers/theme_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '/presentation/utils/language.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
        return lang('status_draft', 'Đơn nháp');
      case 2:
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
  List<LeaveRequest> _myLetters = [];
  List<LeaveRequest> _managedLetters = [];
  bool _initialLoading = true;
  String? _error;
  String _searchQueryMyLetters = '';
  String _searchQueryManaged = '';
  bool _showSearchMyLetters = false;
  bool _showSearchManaged = false;
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
  final bool _loadingBalance = true;
  int? _groupId;
  bool _canApprove = false;

  final baseUrl = dotenv.env['API_BASE_URL'];
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController(initialPage: 0);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadUserInfo();
    _loadData();
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

  void _loadUserInfo() {
    final user = ref.read(authProvider).value;
    if (user != null) {
      setState(() {
        _displayName = user.displayName;
        _groupId = int.tryParse(user.role.toString());
        _canApprove = user.canApprove;
      });
      print('groupId: $_groupId');
      print('canApprove: $_canApprove');
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _initialLoading = true;
      _error = null;
    });

    try {
      final token = ref.read(authProvider).value?.token;
      if (token == null) {
        setState(() => _error = 'No token found');
        return;
      }

      final uri = Uri.parse('$baseUrl/api/Letters');
      final res =
          await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final myData = (body['myLetters'] as List?) ?? [];
        final managedData = (body['managedLetters'] as List?) ?? [];
        final myItems = myData
            .whereType<Map<String, dynamic>>()
            .map((e) => LeaveRequest.fromJson(e))
            .toList();
        final managedItems = managedData
            .whereType<Map<String, dynamic>>()
            .map((e) => LeaveRequest.fromJson(e))
            .toList();
        setState(() {
          _myLetters = myItems;
          _managedLetters = managedItems;
        });
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

  List<BottomNavigationBarItem> _buildNavItems() {
    return [
      const BottomNavigationBarItem(
          icon: Icon(Icons.list), label: 'Đơn của tôi'),
      if (_groupId == 1 || _groupId == 2 || _canApprove)
        const BottomNavigationBarItem(
            icon: Icon(Icons.assignment_ind), label: 'Quản lý'),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Đơn của tôi';
      case 1:
        return 'Đơn quản lý';
      default:
        return 'Danh sách đơn';
    }
  }

  void _onNavTap(int index) async {
    final items = _buildNavItems();
    final label = items[index].label;

    switch (label) {
      case 'Đơn của tôi':
        _loadData();
        break;

      case 'Quản lý':
        _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        break;

      case 'Profile':
        final result = await context.push('/profile');
        setState(() {
          _currentIndex = 0;
        });
        _pageController.jumpToPage(0);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Tạo đơn mới',
          onPressed: () async {
            final result = await context.push('/create-leave-request');
            if (result == true) {
              _loadData();
            }
          },
        ),
        title: Text(
          _getTitle(),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          if (_currentIndex == 0) // Đơn cá nhân
            IconButton(
              icon: Icon(_showSearchMyLetters ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _showSearchMyLetters = !_showSearchMyLetters;
                  if (!_showSearchMyLetters) _searchQueryMyLetters = '';
                });
              },
            ),
          if (_currentIndex == 1) // Đơn quản lý
            IconButton(
              icon: Icon(_showSearchManaged ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _showSearchManaged = !_showSearchManaged;
                  if (!_showSearchManaged) _searchQueryManaged = '';
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (_currentIndex == 0 && _showSearchMyLetters)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Tìm đơn cá nhân...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                onChanged: (value) {
                  setState(() => _searchQueryMyLetters = value);
                },
              ),
            ),
          if (_currentIndex == 1 && _showSearchManaged)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Tìm đơn quản lý...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                onChanged: (value) {
                  setState(() => _searchQueryManaged = value);
                },
              ),
            ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              children: [
                // Trang 0: Đơn cá nhân (có cả draft)
                _initialLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text('${'Lỗi'}: $_error'))
                        : _buildStatusTabs(_myLetters),

                // Trang 1: Đơn quản lý (chỉ hiển thị nếu có quyền)
                (_groupId == 1 || _groupId == 2 || _canApprove)
                    ? _buildManagedLetters()
                    : const Center(
                        child: Text('Bạn không có quyền xem đơn quản lý')),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          _onNavTap(index);
        },
        items: _buildNavItems(),
      ),
    );
  }

  Widget _buildManagedLetters() {
    final filtered = _searchQueryManaged.isEmpty
        ? _managedLetters
        : _managedLetters.where((r) {
            final q = _searchQueryManaged.toLowerCase();
            return r.employeeName.toLowerCase().contains(q) ||
                r.reason.toLowerCase().contains(q) ||
                r.leaveType.toLowerCase().contains(q);
          }).toList();

    final pending = filtered.where((r) => r.statusId == 2).toList();
    final approved = filtered.where((r) => r.statusId == 3).toList();
    final rejected = filtered.where((r) => r.statusId == 4).toList();

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Đang chờ duyệt'),
              Tab(text: 'Đã duyệt'),
              Tab(text: 'Không duyệt'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildList(pending),
                _buildList(approved),
                _buildList(rejected),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs(List<LeaveRequest> requests) {
    final filtered = _searchQueryMyLetters.isEmpty
        ? requests
        : requests.where((r) {
            final q = _searchQueryMyLetters.toLowerCase();
            return r.employeeName.toLowerCase().contains(q) ||
                r.reason.toLowerCase().contains(q) ||
                r.leaveType.toLowerCase().contains(q);
          }).toList();

    final drafts = filtered.where((r) => r.statusId == 1).toList();
    final pending = filtered.where((r) => r.statusId == 2).toList();
    final approved = filtered.where((r) => r.statusId == 3).toList();
    final rejected = filtered.where((r) => r.statusId == 4).toList();

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Đơn nháp'),
              Tab(text: 'Đang chờ duyệt'),
              Tab(text: 'Đã duyệt'),
              Tab(text: 'Không duyệt'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildList(drafts),
                _buildList(pending),
                _buildList(approved),
                _buildList(rejected),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<LeaveRequest> requests) {
    return requests.isEmpty
        ? Center(child: Text('Không có dữ liệu'))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            controller: _scrollController,
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];

              final statusColor = switch (request.statusId) {
                2 => Colors.orange,
                3 => Colors.green,
                4 => Colors.red,
                _ => Colors.grey,
              };

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final result =
                        await context.push('/leave-request/${request.id}');
                    if (result == true) {
                      _loadData();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                request.employeeName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                request.statusText.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Loại nghỉ
                        Row(
                          children: [
                            const Icon(Icons.work,
                                size: 16, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                request.leaveType,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Ngày nghỉ
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Text(
                              '${_formatDate(request.startDate)} - ${_formatDate(request.endDate)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Lý do
                        Row(
                          children: [
                            const Icon(Icons.notes,
                                size: 16, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                request.reason,
                                style: const TextStyle(fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
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
