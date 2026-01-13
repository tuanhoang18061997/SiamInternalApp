import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/presentation/utils/language.dart';
import 'home_screen.dart';

class ManagedLettersScreen extends StatefulWidget {
  final List<LeaveRequest> managedLetters;
  const ManagedLettersScreen({super.key, required this.managedLetters});

  @override
  State<ManagedLettersScreen> createState() => _ManagedLettersScreenState();
}

class _ManagedLettersScreenState extends State<ManagedLettersScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  bool _showSearch = false;

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final filtered = _searchQuery.isEmpty
        ? widget.managedLetters
        : widget.managedLetters.where((r) {
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
        title: Text(lang('managed_letters', 'Đơn cần duyệt')),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) _searchQuery = '';
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
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
                  setState(() => _searchQuery = value);
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
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(text: lang('status_pending', 'Đang chờ duyệt')),
                      Tab(text: lang('status_approved', 'Đã duyệt')),
                      Tab(text: lang('status_rejected', 'Không duyệt')),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<LeaveRequest> requests) {
    return requests.isEmpty
        ? Center(child: Text(lang('no_data', 'Không có dữ liệu')))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final r = requests[index];
              final statusColor = switch (r.statusId) {
                3 => Colors.green,
                4 => Colors.red,
                _ => Colors.orange,
              };
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () async {
                    final result = await context.push('/leave-request/${r.id}');
                    if (result == true) {
                      setState(() {});
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              r.employeeName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Chip(
                              label: Text(r.statusText.toUpperCase()),
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
                            Text(r.leaveType),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Text(
                                '${_formatDate(r.startDate)} - ${_formatDate(r.endDate)}'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.notes,
                                size: 16, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Expanded(child: Text(r.reason)),
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
