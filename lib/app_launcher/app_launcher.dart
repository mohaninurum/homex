import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'dart:async';
import 'dart:ui';

class AppLauncherScreen extends StatefulWidget {
  const AppLauncherScreen({super.key});

  @override
  State<AppLauncherScreen> createState() => _AppLauncherScreenState();
}

class _AppLauncherScreenState extends State<AppLauncherScreen>
    with SingleTickerProviderStateMixin {
  List<AppInfo>? apps;
  List<AppInfo>? filteredApps;
  final TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  String currentTime = '';
  String currentDate = '';
  String currentDay = '';
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Status bar transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _fetchApps();
    searchController.addListener(_searchApps);
    _updateTime();
    Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
  }

  void _updateTime() {
    final now = DateTime.now();
    if (mounted) {
      setState(() {
        currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        currentDate = '${_getMonthName(now.month)} ${now.day}';
        currentDay = _getDayName(now.weekday);
      });
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  String _getDayName(int day) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[day - 1];
  }

  void _fetchApps() async {
    List<AppInfo> installedApps = await InstalledApps.getInstalledApps(
      excludeSystemApps: false,
      excludeNonLaunchableApps: true,
      withIcon: true,
    );

    installedApps.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    if (mounted) {
      setState(() {
        apps = installedApps;
        filteredApps = installedApps;
      });
    }
  }

  void _searchApps() {
    String query = searchController.text.toLowerCase();
    if (mounted) {
      setState(() {
        filteredApps = apps
            ?.where((app) => app.name.toLowerCase().contains(query))
            .toList();
      });
    }
  }

  void _launchApp(String packageName) async {
    HapticFeedback.lightImpact();
    bool? result = await InstalledApps.startApp(packageName);
    if (!result! && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Cannot open this app'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.red.shade600,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openAppDrawer() {
    if (mounted) {
      HapticFeedback.mediumImpact();
      _animationController.forward();
    }
  }

  void _closeAppDrawer() {
    if (mounted) {
      HapticFeedback.lightImpact();
      _animationController.reverse();
      searchController.clear();
      setState(() => isSearching = false);
      FocusScope.of(context).unfocus();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFF093FB),
              Color(0xFF4facfe),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: apps == null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Loading all apps...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        )
            : Stack(
          children: [
            // Animated Background Circles
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Home Screen
            SafeArea(
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity! < -500) {
                    _openAppDrawer();
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // Premium Clock Widget
                      Hero(
                        tag: 'clock',
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 30),
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.15),
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: BackdropFilter(
                                filter:
                                ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Column(
                                  children: [
                                    Text(
                                      currentDay,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white.withOpacity(0.9),
                                        letterSpacing: 3,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      currentTime,
                                      style: const TextStyle(
                                        fontSize: 72,
                                        fontWeight: FontWeight.w200,
                                        color: Colors.white,
                                        letterSpacing: 2,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      currentDate,
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white.withOpacity(0.85),
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const Spacer(flex: 3),

                      // Premium Swipe Indicator
                      Column(
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(seconds: 2),
                            curve: Curves.easeInOut,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, -10 * value),
                                child: Opacity(
                                  opacity: 0.5 + (0.5 * value),
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_upward,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Swipe up for apps',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      letterSpacing: 1,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // App Drawer with Smooth Animations
            SlideTransition(
              position: _slideAnimation,
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity! > 500) {
                    _closeAppDrawer();
                  }
                },
                child: Container(
                  height: screenHeight,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.25),
                              Colors.white.withOpacity(0.15),
                            ],
                          ),
                          border: const Border(
                            top: BorderSide(
                              color: Colors.white38,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: SafeArea(
                          child: Column(
                            children: [
                              // Handle Bar
                              Container(
                                margin:
                                const EdgeInsets.only(top: 16, bottom: 24),
                                width: 50,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),

                              // Search Bar
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(28),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.4),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withOpacity(0.1),
                                            blurRadius: 20,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: TextField(
                                        controller: searchController,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        onTap: () => setState(
                                                () => isSearching = true),
                                        decoration: InputDecoration(
                                          hintText: 'Search apps...',
                                          hintStyle: TextStyle(
                                            color: Colors.white
                                                .withOpacity(0.5),
                                            fontWeight: FontWeight.w300,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.search_rounded,
                                            color: Colors.white
                                                .withOpacity(0.7),
                                            size: 24,
                                          ),
                                          suffixIcon: isSearching
                                              ? IconButton(
                                            icon: Icon(
                                              Icons.close_rounded,
                                              color: Colors.white
                                                  .withOpacity(0.7),
                                            ),
                                            onPressed: () {
                                              searchController.clear();
                                              setState(() =>
                                              isSearching = false);
                                              FocusScope.of(context)
                                                  .unfocus();
                                            },
                                          )
                                              : null,
                                          border: InputBorder.none,
                                          contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 18,
                                              horizontal: 20),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // App Count
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    '${filteredApps!.length} apps',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Apps Grid
                              Expanded(
                                child: filteredApps!.isEmpty
                                    ? Center(
                                  child: FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding:
                                          const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.search_off_rounded,
                                            size: 64,
                                            color: Colors.white
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          'No apps found',
                                          style: TextStyle(
                                            color: Colors.white
                                                .withOpacity(0.7),
                                            fontSize: 18,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                    : GridView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 10),
                                  physics:
                                  const BouncingScrollPhysics(),
                                  gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: 18,
                                    mainAxisSpacing: 26,
                                  ),
                                  itemCount: filteredApps!.length,
                                  itemBuilder: (context, index) {
                                    AppInfo app = filteredApps![index];
                                    return _AppIconWidget(
                                      app: app,
                                      onTap: () =>
                                          _launchApp(app.packageName),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Separate Widget for Better Performance
class _AppIconWidget extends StatelessWidget {
  final AppInfo app;
  final VoidCallback onTap;

  const _AppIconWidget({
    required this.app,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App Icon
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: app.icon != null
                        ? Image.memory(
                      app.icon!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                        : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade300,
                            Colors.purple.shade300,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.apps_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // App Name
          Text(
            app.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              height: 1.2,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}