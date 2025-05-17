import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/BottomNavBar.dart';
import '../utils/constant/app_colors.dart';
import 'DashBoardScreen.dart';
import 'HomeScreen.dart';
import 'RideListScreen.dart';
import 'WalletScreen.dart';
import 'SettingScreen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  MainScreen({this.initialIndex = 0});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    _screens = [
      HomeScreen(),
      DashBoardScreen(),
      RideListScreen(),
      WalletScreen(),
      SettingScreen(),
    ];

    // Set the initial page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    // Add haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      _currentIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: _screens,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                // Handle my location button tap
              },
              backgroundColor: AppColors.primary,
              elevation: 4,
              child: Icon(Icons.my_location, color: Colors.white),
            )
          : null,
    );
  }
}
