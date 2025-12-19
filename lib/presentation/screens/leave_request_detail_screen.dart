import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/leave_request_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_formatter.dart';

class LeaveRequestDetailScreen extends ConsumerStatefulWidget {
  final String requestId;

  const LeaveRequestDetailScreen({
    super.key,
    required this.requestId,
  });

  @override
  ConsumerState<LeaveRequestDetailScreen> createState() => _LeaveRequestDetailScreenState();
}

class _LeaveRequestDetailScreenState extends ConsumerState<LeaveRequestDetailScreen> {
  bool _isProcessing = false;

  Future<void> _handleApprove() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      await ref.read(leaveRequestNotifierProvider.notifier).approveLeaveRequest(
            widget.requestId,
            user.name,
          );

      if (mounted) {
        ref.invalidate(leaveRequestsProvider);
        ref.invalidate(leaveRequestDetailProvider(widget.requestId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave request approved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleReject() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Leave Request'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Rejection Reason',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, reasonController.text);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      await ref.read(leaveRequestNotifierProvider.notifier).rejectLeaveRequest(
            widget.requestId,
            user.name,
            reason,
          );

      if (mounted) {
        ref.invalidate(leaveRequestsProvider);
        ref.invalidate(leaveRequestDetailProvider(widget.requestId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave request rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestAsync = ref.watch(leaveRequestDetailProvider(widget.requestId));
    final user = ref.watch(currentUserProvider);
    final isManager = user?.role == 'manager';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Request Details'),
      ),
      body: requestAsync.when(
        data: (request) {
          final statusColor = request.status == AppConstants.statusApproved
              ? Colors.green
              : request.status == AppConstants.statusRejected
                  ? Colors.red
                  : Colors.orange;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Status',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                request.status.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Employee', request.employeeName),
                        const Divider(),
                        _buildDetailRow('Leave Type', request.leaveType),
                        const Divider(),
                        _buildDetailRow(
                          'Start Date',
                          DateFormatter.formatDate(request.startDate),
                        ),
                        const Divider(),
                        _buildDetailRow(
                          'End Date',
                          DateFormatter.formatDate(request.endDate),
                        ),
                        const Divider(),
                        _buildDetailRow(
                          'Duration',
                          '${request.endDate.difference(request.startDate).inDays + 1} day(s)',
                        ),
                        const Divider(),
                        const Text(
                          'Reason',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(request.reason),
                      ],
                    ),
                  ),
                ),
                if (request.approvedBy != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Approval Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            request.status == AppConstants.statusApproved
                                ? 'Approved By'
                                : 'Rejected By',
                            request.approvedBy!,
                          ),
                          if (request.approvedAt != null) ...[
                            const Divider(),
                            _buildDetailRow(
                              'Date',
                              DateFormatter.formatDate(request.approvedAt!),
                            ),
                          ],
                          if (request.rejectionReason != null) ...[
                            const Divider(),
                            const Text(
                              'Rejection Reason',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(request.rejectionReason!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                if (isManager && request.status == AppConstants.statusPending) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _handleApprove,
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _handleReject,
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(leaveRequestDetailProvider(widget.requestId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
