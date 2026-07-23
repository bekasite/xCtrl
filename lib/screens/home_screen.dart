import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/app_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final _commandController = TextEditingController();
  String _result = '';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _commandController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppConstants.bgGradient),
        child: SafeArea(
          child: Consumer<AppState>(
            builder: (context, state, _) {
              return RefreshIndicator(
                onRefresh: () => state.loadStatus(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    _buildHeader(state),
                    const SizedBox(height: 20),
                    _buildStatusCard(state),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    _buildQuickActions(state),
                    const SizedBox(height: 16),
                    _buildCommandTester(state),
                    if (_result.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildResultCard(),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: AppConstants.accentGradient,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset('assets/logo.png',
                  width: 42, height: 42, fit: BoxFit.cover)),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppConstants.textPrimary,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'SMS Remote Control',
                style: TextStyle(
                  fontSize: 11,
                  color: AppConstants.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppConstants.successColor,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          const Text(
            'Active',
            style: TextStyle(
              color: AppConstants.successColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(AppState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppConstants.cardBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppConstants.accentGradient,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'System Status',
                style: TextStyle(
                  color: AppConstants.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                state.loading ? 'updating...' : 'live',
                style: TextStyle(
                  color: AppConstants.textSecondary.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip(
                Icons.admin_panel_settings,
                'Device Admin',
                state.deviceAdminEnabled ? 'Active' : 'Inactive',
                state.deviceAdminEnabled
                    ? AppConstants.successColor
                    : AppConstants.errorColor,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                Icons.people,
                'Whitelist',
                '${state.whitelistCount} numbers',
                AppConstants.accentColor,
              ),
            ],
          ),
          if (state.lastResult.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppConstants.lightBorder.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.terminal,
                          color: AppConstants.accentColor.withValues(alpha: 0.7),
                          size: 14),
                      const SizedBox(width: 6),
                      const Text('Last Result',
                          style: TextStyle(
                              color: AppConstants.textSecondary, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.lastResult.replaceAll(' | ', '\n'),
                    style: const TextStyle(
                      color: AppConstants.textPrimary,
                      fontSize: 12,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          color: color.withValues(alpha: 0.06),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            Text(label,
                style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(AppState state) {
    final icons = {
      'LOCATION': Icons.location_on,
      'STATUS': Icons.info_outline,
      'CAMERA': Icons.camera_alt,
      'LOCK': Icons.lock,
      'WIFI': Icons.wifi,
      'FLASH': Icons.flash_on,
      'MUTE': Icons.volume_off,
      'SCREENSHOT': Icons.screenshot,
      'BATTERY': Icons.battery_std,
      'IP': Icons.language,
      'SMS': Icons.sms,
      'CALL': Icons.phone,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppConstants.cardBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: AppConstants.accentColor, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Favorites',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textPrimary),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => {}, // configured in Settings screen
                child: Text('Edit in Settings',
                    style: TextStyle(
                        color: AppConstants.accentColor.withValues(alpha: 0.7),
                        fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: state.favorites.take(4).map((cmd) {
              return _QuickActionChip(
                icon: icons[cmd] ?? Icons.code,
                label: cmd,
                color: AppConstants.accentColor,
                loading: state.loading,
                onTap: () async {
                  final result = await state.executeCommand('xctl $cmd');
                  if (mounted) setState(() => _result = result);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandTester(AppState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppConstants.cardBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terminal,
                  color: AppConstants.successColor.withValues(alpha: 0.9), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Command Tester',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _commandController,
            style: const TextStyle(color: AppConstants.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'xctl COMMAND [params]',
              prefixIcon:
                  Icon(Icons.terminal, color: AppConstants.accentColor, size: 20),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onFieldSubmitted: (value) async {
              if (value.trim().isNotEmpty) {
                final result = await state.executeCommand(value.trim());
                if (mounted) {
                  setState(() => _result = result);
                  _commandController.clear();
                }
              }
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: state.loading
                  ? null
                  : () async {
                      final cmd = _commandController.text.trim();
                      if (cmd.isNotEmpty) {
                        final result = await state.executeCommand(cmd);
                        if (mounted) {
                          setState(() => _result = result);
                          _commandController.clear();
                        }
                      }
                    },
              icon: state.loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ))
                  : const Icon(Icons.play_arrow, size: 20),
              label: Text(state.loading ? 'Executing...' : 'Execute Command'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.successColor.withValues(alpha: 0.3),
        ),
        color: AppConstants.successColor.withValues(alpha: 0.05),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppConstants.successColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check_circle,
                color: AppConstants.successColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_result,
                style: const TextStyle(
                    color: AppConstants.textPrimary, fontSize: 13)),
          ),
          GestureDetector(
            onTap: () => setState(() => _result = ''),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppConstants.lightBorder.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.close,
                  color: AppConstants.textSecondary, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  @override
  State<_QuickActionChip> createState() => _QuickActionChipState();
}

class _QuickActionChipState extends State<_QuickActionChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnim;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _hoverAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hoverAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + _hoverAnim.value * 0.05,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _hoverController.forward(),
        onTapUp: (_) {
          _hoverController.reverse();
          if (!widget.loading) widget.onTap();
        },
        onTapCancel: () => _hoverController.reverse(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.3),
            ),
            color: widget.color.withValues(alpha: 0.08),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: widget.color, size: 16),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
