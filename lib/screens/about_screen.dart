import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/app_state.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
                  _buildLogoSection(),
                  const SizedBox(height: 24),
                  _buildInfoCard(state),
                  const SizedBox(height: 16),
                  _buildCommandsCard(context),
                  const SizedBox(height: 16),
                  _buildLegalCard(),
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
          child: const Icon(Icons.info_outline, color: Colors.black, size: 22),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppConstants.textPrimary),
            ),
            Text(
              'App information',
              style: TextStyle(fontSize: 11, color: AppConstants.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogoSection() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppConstants.accentGradient,
            ),
            child: ClipOval(
              child: Image.asset('assets/logo.png',
                  width: 100, height: 100, fit: BoxFit.cover)),
          ),
          const SizedBox(height: 16),
          const Text(
            AppConstants.appName,
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppConstants.textPrimary,
                letterSpacing: 4),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppConstants.accentColor.withValues(alpha: 0.1),
              border: Border.all(
                color: AppConstants.accentColor.withValues(alpha: 0.2),
              ),
            ),
            child: Text(AppConstants.domain,
                style: const TextStyle(
                    fontSize: 12, color: AppConstants.accentColor,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(AppState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppConstants.cardBox(),
      child: Column(
        children: [
          _buildInfoRow(
              Icons.tag, 'Version', AppConstants.version),
          const SizedBox(height: 10),
          _buildInfoRow(
              Icons.inventory_2, 'Package', AppConstants.packageName),
          if (state.deviceInfo.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildInfoRow(
                Icons.phone_android,
                'Device',
                '${state.deviceInfo['manufacturer']} ${state.deviceInfo['model']}'),
            const SizedBox(height: 10),
            _buildInfoRow(
                Icons.android,
                'Android',
                '${state.deviceInfo['version']} (SDK ${state.deviceInfo['sdk']})'),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppConstants.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppConstants.accentColor, size: 16),
        ),
        const SizedBox(width: 12),
        Text('$label: ',
            style: const TextStyle(
                color: AppConstants.textSecondary, fontSize: 13)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: AppConstants.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildCommandsCard(BuildContext context) {
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
                child: const Icon(Icons.code,
                    color: AppConstants.accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Available Commands',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...AppConstants.allCommands.take(20).map((cmd) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppConstants.accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(cmd,
                        style: const TextStyle(
                            color: AppConstants.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(AppConstants.commandDescriptions[cmd] ?? '',
                        style: const TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 11)),
                  ],
                ),
              )),
          const SizedBox(height: 10),
          Center(
            child: GestureDetector(
              onTap: () => _showAllCommands(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: AppConstants.accentGradient,
                ),
                child: Text(
                    'View all ${AppConstants.allCommands.length} commands',
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.lightBorder.withValues(alpha: 0.3),
        ),
        color: AppConstants.lightCard.withValues(alpha: 0.5),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppConstants.accentColor.withValues(alpha: 0.1),
            ),
            child: const Icon(Icons.shield_outlined,
                color: AppConstants.accentColor, size: 24),
          ),
          const SizedBox(height: 12),
          const Text(
            'SMS Remote Control',
            style: TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Use responsibly. Only authorize numbers you trust.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppConstants.textSecondary.withValues(alpha: 0.8),
                fontSize: 12),
          ),
          const SizedBox(height: 10),
          Text('${AppConstants.domain} \u00a9 ${DateTime.now().year}',
              style: TextStyle(
                  color: AppConstants.textSecondary.withValues(alpha: 0.6),
                  fontSize: 11)),
        ],
      ),
    );
  }

  void _showAllCommands(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            color: AppConstants.lightCard,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        const Spacer(),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: AppConstants.lightBorder,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'All Commands',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppConstants.textPrimary,
                          letterSpacing: 1),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      children: [
                        ...AppConstants.allCommands.map((cmd) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      color: AppConstants.accentColor
                                          .withValues(alpha: 0.1),
                                      border: Border.all(
                                        color: AppConstants.accentColor
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Text('xctl $cmd',
                                        style: const TextStyle(
                                            color: AppConstants.accentColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                          AppConstants
                                                  .commandDescriptions[cmd] ??
                                              '',
                                          style: const TextStyle(
                                              color: AppConstants.textSecondary,
                                              fontSize: 12)),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
