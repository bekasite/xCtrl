import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _numberController = TextEditingController();
  final _searchController = TextEditingController();
  final _tgTokenController = TextEditingController();
  final _tgLinkCodeController = TextEditingController();
  String _searchQuery = '';
  String _tgTestResult = '';
  String _tgLinkResult = '';
  bool _showCustomBot = false;
  bool _tgLinking = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.read<AppState>();
    _tgTokenController.text = state.tgToken;
  }

  @override
  void dispose() {
    _numberController.dispose();
    _searchController.dispose();
    _tgTokenController.dispose();
    _tgLinkCodeController.dispose();
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
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildPermissionsCard(state),
                  const SizedBox(height: 16),
                  _buildTelegramCard(state),
                  const SizedBox(height: 16),
                  _buildFavoritesCard(state),
                  const SizedBox(height: 16),
                  _buildWhitelistCard(state),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: AppConstants.accentGradient,
          ),
          child: const Icon(Icons.settings, color: Colors.black, size: 22),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppConstants.textPrimary,
              ),
            ),
            Text(
              'Permissions & Authorized Numbers',
              style: TextStyle(
                fontSize: 11,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPermissionsCard(AppState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppConstants.cardBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.security,
                    color: AppConstants.accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Permissions',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPermissionTile(
            icon: Icons.admin_panel_settings,
            title: 'Device Admin',
            subtitle: state.deviceAdminEnabled
                ? 'Enabled - Lock, Wipe, Password available'
                : 'Required for LOCK, WIPE, PASSWORD',
            value: state.deviceAdminEnabled,
            onTap: () => state.requestDeviceAdmin(),
          ),
          const SizedBox(height: 8),
          _buildPermissionTile(
            icon: Icons.tune,
            title: 'Write Settings',
            subtitle: 'Required for brightness, timeout, airplane mode',
            value: null,
            onTap: () => state.requestWriteSettings(),
          ),
          const SizedBox(height: 8),
          _buildPermissionTile(
            icon: Icons.battery_charging_full,
            title: 'Battery Optimization',
            subtitle: 'Disable to prevent service from being killed',
            value: null,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFF0F0F4),
          border: Border.all(
            color: AppConstants.lightBorder.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppConstants.accentColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppConstants.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppConstants.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            if (value != null)
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value
                      ? AppConstants.successColor
                      : AppConstants.errorColor,
                ),
              )
            else
              Icon(Icons.chevron_right,
                  color: AppConstants.textSecondary.withValues(alpha: 0.5),
                  size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTelegramCard(AppState state) {
    final bool connected = state.tgChatId.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppConstants.cardBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.telegram, color: AppConstants.accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Telegram Auto-Upload',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.textPrimary),
                ),
              ),
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state.tgEnabled && connected
                      ? AppConstants.successColor : AppConstants.errorColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(state.tgEnabled ? 'ON' : 'OFF',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: state.tgEnabled
                          ? AppConstants.successColor : AppConstants.errorColor)),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _showCustomBot = !_showCustomBot),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFF0F0F4),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: AppConstants.textSecondary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bot: @xctlbot_bot (shared)',
                      style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showCustomBot ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, color: AppConstants.textSecondary, size: 18),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextFormField(
                controller: _tgTokenController,
                style: const TextStyle(color: AppConstants.textPrimary, fontSize: 13),
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Custom Bot Token',
                  hintText: '123456:ABC-DEF1234',
                  prefixIcon: Icon(Icons.key, color: AppConstants.accentColor, size: 18),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            crossFadeState: _showCustomBot ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          const SizedBox(height: 16),
          if (_tgLinking)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.accentColor),
                ),
              ),
            )
          else if (connected) ...[
            Row(
              children: [
                Icon(Icons.check_circle, color: AppConstants.successColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✓ Connected as ${state.tgLinkedInfo.isNotEmpty ? state.tgLinkedInfo : state.tgChatId}',
                    style: const TextStyle(color: AppConstants.successColor, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await state.saveTelegramConfig(
                      token: _tgTokenController.text.trim(),
                      chatId: '',
                      enabled: false,
                    );
                    if (mounted) setState(() {});
                  },
                  child: Icon(Icons.link_off, color: AppConstants.errorColor, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Send /start to @xctlbot_bot on Telegram, then enter the code below:',
              style: TextStyle(
                color: AppConstants.textSecondary.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tgLinkCodeController,
                    style: const TextStyle(color: AppConstants.textPrimary, fontSize: 14),
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'Linking code',
                      prefixIcon: Icon(Icons.vpn_key, color: AppConstants.accentColor, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _tgLinking ? null : _linkWithCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _tgLinking
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Link', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
            if (_tgLinkResult.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppConstants.errorColor.withValues(alpha: 0.1),
                  border: Border.all(color: AppConstants.errorColor.withValues(alpha: 0.2)),
                ),
                child: Text('Link failed: $_tgLinkResult',
                    style: const TextStyle(color: AppConstants.errorColor, fontSize: 12)),
              ),
            ],
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              if (connected) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      setState(() => _tgTestResult = 'testing...');
                      final res = await state.testTelegram();
                      setState(() => _tgTestResult = res);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppConstants.accentColor.withValues(alpha: 0.15),
                        border: Border.all(color: AppConstants.accentColor.withValues(alpha: 0.3)),
                      ),
                      child: const Text('Test',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppConstants.accentColor, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await state.saveTelegramConfig(
                        token: _tgTokenController.text.trim(),
                        chatId: state.tgChatId,
                        enabled: !state.tgEnabled,
                      );
                      if (mounted) setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: (state.tgEnabled ? AppConstants.errorColor : AppConstants.successColor).withValues(alpha: 0.15),
                        border: Border.all(color: (state.tgEnabled ? AppConstants.errorColor : AppConstants.successColor).withValues(alpha: 0.3)),
                      ),
                      child: Text(state.tgEnabled ? 'Disable' : 'Enable',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: state.tgEnabled ? AppConstants.errorColor : AppConstants.successColor,
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_tgTestResult.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFF0F0F4),
              ),
              child: Text('Test: $_tgTestResult',
                  style: TextStyle(
                      fontSize: 12,
                      color: _tgTestResult == 'OK'
                          ? AppConstants.successColor : AppConstants.textSecondary)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tgActionButton(String label, Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Future<void> _linkWithCode() async {
    final code = _tgLinkCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter the code from the Telegram bot'),
          backgroundColor: AppConstants.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    setState(() { _tgLinking = true; _tgLinkResult = ''; });
    final state = context.read<AppState>();
    final result = await state.linkWithCode(code);
    if (mounted) {
      setState(() => _tgLinking = false);
      if (result.contains('|')) {
        _tgLinkCodeController.clear();
        setState(() => _tgLinkResult = '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Linked as ${state.tgLinkedInfo}'),
            backgroundColor: AppConstants.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        setState(() => _tgLinkResult = result);
      }
    }
  }

  Widget _buildFavoritesCard(AppState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppConstants.cardBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.star, color: AppConstants.accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Quick Actions (up to 4)',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(4, (i) {
            final current = i < state.favorites.length ? state.favorites[i] : '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DropdownButtonFormField<String>(
                value: current.isNotEmpty && AppConstants.allCommands.contains(current)
                    ? current : null,
                dropdownColor: AppConstants.lightSurface,
                style: const TextStyle(
                    color: AppConstants.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Slot ${i + 1}',
                  prefixIcon: Icon(Icons.code, color: AppConstants.accentColor, size: 18),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('(none)')),
                  ...AppConstants.allCommands.map((cmd) =>
                      DropdownMenuItem(value: cmd, child: Text(cmd))),
                ],
                onChanged: (val) {
                  final favs = List<String>.from(state.favorites);
                  while (favs.length <= i) favs.add('');
                  if (val == null) {
                    favs.removeAt(i);
                  } else {
                    favs[i] = val;
                  }
                  state.saveFavorites(favs.where((x) => x.isNotEmpty).take(4).toList());
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWhitelistCard(AppState state) {
    final filtered = _searchQuery.isEmpty
        ? state.whitelist
        : state.whitelist
            .where((e) => e.number.contains(_searchQuery))
            .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppConstants.cardBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.people, color: AppConstants.accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Authorized Numbers',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.textPrimary),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: AppConstants.accentGradient,
                ),
                child: Text('${state.whitelistCount}',
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _numberController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                      color: AppConstants.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: '+1234567890',
                    prefixIcon: Icon(Icons.phone,
                        color: AppConstants.accentColor, size: 18),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: AppConstants.accentGradient,
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    final number = _numberController.text.trim();
                    if (number.isNotEmpty) {
                      final added = await state.addToWhitelist(number);
                      if (mounted) {
                        _numberController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(added
                                ? 'Number added to whitelist'
                                : 'Number already in whitelist'),
                            backgroundColor: added
                                ? AppConstants.successColor
                                : AppConstants.accentColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.black,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                  ),
                  child: const Text('Add',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
          if (state.whitelist.isNotEmpty) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _searchController,
              style: const TextStyle(
                  color: AppConstants.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Search numbers...',
                prefixIcon: Icon(Icons.search,
                    color: AppConstants.accentColor, size: 18),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ],
          const SizedBox(height: 10),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.people_outline,
                        color: AppConstants.textSecondary.withValues(alpha: 0.5),
                        size: 48),
                    const SizedBox(height: 12),
                    const Text('No authorized numbers',
                        style: TextStyle(
                            color: AppConstants.textSecondary, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('Add a phone number above',
                        style: TextStyle(
                            color: AppConstants.textSecondary.withValues(alpha: 0.7),
                            fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            ...filtered.map((entry) => _buildWhitelistItem(state, entry.number)),
        ],
      ),
    );
  }

  Widget _buildWhitelistItem(AppState state, String number) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.lightBorder.withValues(alpha: 0.3),
        ),
        color: const Color(0xFFF0F0F4),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppConstants.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person,
                color: AppConstants.accentColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(number,
                style: const TextStyle(
                    color: AppConstants.textPrimary, fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ),
          GestureDetector(
            onTap: () => state.removeFromWhitelist(number),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppConstants.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.remove_circle_outline,
                  color: AppConstants.errorColor, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
