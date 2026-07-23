import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/app_state.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppConstants.bgGradient),
        child: SafeArea(
          child: Consumer<AppState>(
            builder: (context, state, _) {
              return Column(
                children: [
                  _buildHeader(state),
                  Expanded(
                    child: state.logs.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: () => state.loadLogs(),
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              itemCount: state.logs.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final log = state.logs[index];
                                return _buildLogEntry(log);
                              },
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: AppConstants.accentGradient,
          ),
          child:
              const Icon(Icons.history, color: Colors.black, size: 22),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Command Logs',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppConstants.textPrimary,
                ),
              ),
              Text(
                'Execution history',
                style: TextStyle(
                  fontSize: 11,
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (state.logs.isNotEmpty)
            GestureDetector(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppConstants.lightSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('Clear Logs',
                        style: TextStyle(color: AppConstants.textPrimary)),
                    content: const Text('Delete all command logs?',
                        style:
                            TextStyle(color: AppConstants.textSecondary)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color:
                              AppConstants.errorColor.withValues(alpha: 0.15),
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Clear All',
                              style: TextStyle(
                                  color: AppConstants.errorColor,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await state.clearLogs();
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppConstants.errorColor.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppConstants.errorColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_sweep,
                        color: AppConstants.errorColor, size: 16),
                    const SizedBox(width: 4),
                    Text('Clear',
                        style: TextStyle(
                            color: AppConstants.errorColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppConstants.lightCard,
              border: Border.all(
                color: AppConstants.lightBorder.withValues(alpha: 0.5),
              ),
            ),
            child: Icon(Icons.history,
                color: AppConstants.textSecondary.withValues(alpha: 0.5),
                size: 36),
          ),
          const SizedBox(height: 20),
          const Text('No command logs yet',
              style: TextStyle(
                  color: AppConstants.textSecondary, fontSize: 16)),
          const SizedBox(height: 6),
          Text('Execute commands via SMS to see logs here',
              style: TextStyle(
                  color: AppConstants.textSecondary.withValues(alpha: 0.7),
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLogEntry(dynamic log) {
    final command = log.command as String? ?? '';
    final sender = log.sender as String? ?? '';
    final result = log.result as String? ?? '';
    final success = log.success as bool? ?? false;
    final time = log.formattedTime;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppConstants.lightCard,
        border: Border.all(
          color: AppConstants.lightBorder.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: (success
                          ? AppConstants.successColor
                          : AppConstants.errorColor)
                      .withValues(alpha: 0.15),
                  border: Border.all(
                    color: (success
                            ? AppConstants.successColor
                            : AppConstants.errorColor)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Text(command,
                    style: TextStyle(
                      color: success
                          ? AppConstants.successColor
                          : AppConstants.errorColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    )),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(sender,
                    style: const TextStyle(
                        color: AppConstants.textSecondary, fontSize: 12)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: AppConstants.lightBorder.withValues(alpha: 0.5),
                ),
                child: Text(time,
                    style: TextStyle(
                        color: AppConstants.textSecondary.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppConstants.lightBorder.withValues(alpha: 0.4),
            ),
            child: Text(
              result.replaceAll(' | ', '\n'),
              style: const TextStyle(
                  color: AppConstants.textPrimary, fontSize: 12),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
