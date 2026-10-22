import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../account/presentation/account_tab.dart';
import '../../gallery/presentation/gallery_tab.dart';
import '../../timeline/presentation/timeline_tab.dart';
import 'home_tab.dart';
import 'widgets/puvi_bottom_nav_bar.dart';

/// Main navigation shell holding the bottom navigation bar and active tab views.
class MainNavScreen extends StatefulWidget {
  final String userName;
  final int initialIndex;

  const MainNavScreen({
    super.key,
    this.userName = 'Vicky',
    this.initialIndex = 0,
  });

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeTab(userName: widget.userName),
          const TimelineTab(),
          const GalleryTab(),
          AccountTab(userName: widget.userName),
        ],
      ),
      bottomNavigationBar: PuviBottomNavBar(
        currentIndex: _currentIndex,
        onTabSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
