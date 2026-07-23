import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      icon: Icons.settings_remote,
      title: 'Remote Control\nvia SMS',
      description:
          'Control any Android device remotely by sending SMS commands from authorized numbers.',
      color: AppConstants.accentColor,
    ),
    _OnboardingPage(
      icon: Icons.shield,
      title: 'Secure &\nPrivate',
      description:
          'Only whitelisted numbers can send commands. All actions are logged and auditable.',
      color: AppConstants.successColor,
    ),
    _OnboardingPage(
      icon: Icons.bolt,
      title: '40+ Commands\nat Your Fingertips',
      description:
          'Location, camera, WiFi, Bluetooth, SMS, calls, files, clipboard, and more.',
      color: AppConstants.accentColor,
    ),
    _OnboardingPage(
      icon: Icons.dashboard_customize,
      title: 'Ready to\ntake control?',
      description:
          'Grant permissions, add authorized numbers, and start commanding your device.',
      color: AppConstants.accentColor,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppConstants.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    _currentPage < _pages.length - 1 ? 'Skip' : '',
                    style: const TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _PageContent(
                      page: _pages[index],
                      isActive: index == _currentPage,
                    );
                  },
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(
              _pages.length,
              (i) => _PageIndicator(isActive: i == _currentPage),
            ),
          ),
          FloatingActionButton(
            backgroundColor: AppConstants.accentColor,
            elevation: 0,
            onPressed: () {
              if (_currentPage < _pages.length - 1) {
                _controller.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                );
              } else {
                _completeOnboarding();
              }
            },
            child: Icon(
              _currentPage < _pages.length - 1
                  ? Icons.arrow_forward
                  : Icons.check,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

class _PageContent extends StatefulWidget {
  final _OnboardingPage page;
  final bool isActive;

  const _PageContent({required this.page, required this.isActive});

  @override
  State<_PageContent> createState() => _PageContentState();
}

class _PageContentState extends State<_PageContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    if (widget.isActive) _animController.forward();
  }

  @override
  void didUpdateWidget(covariant _PageContent old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _animController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.page.color.withValues(alpha: 0.3),
                    widget.page.color.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: widget.page.color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                widget.page.icon,
                color: widget.page.color,
                size: 56,
              ),
            ),
            const SizedBox(height: 48),
            Text(
              widget.page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppConstants.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.page.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppConstants.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final bool isActive;
  const _PageIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: isActive ? AppConstants.accentGradient : null,
        color: isActive ? null : AppConstants.lightBorder,
      ),
    );
  }
}
