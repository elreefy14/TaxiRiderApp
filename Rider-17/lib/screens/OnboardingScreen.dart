import 'package:flutter/material.dart';
import '../model/OnboardingEntity.dart';
import '../components/OnboardingPage.dart';
import '../utils/constant/app_colors.dart';
import '../utils/images.dart';
import 'SignInScreen.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import '../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  final List<OnboardingEntity> _pages = [
    OnboardingEntity(
      title: language.walkthrough_title_1,
      subtitle: language.walkthrough_subtitle_1,
      image: ic_walk1,
      buttonText: 'Next',
    ),
    OnboardingEntity(
      title: language.walkthrough_title_2,
      subtitle: language.walkthrough_subtitle_2,
      image: ic_walk2,
      buttonText: 'Next',
    ),
    OnboardingEntity(
      title: language.walkthrough_title_3,
      subtitle: language.walkthrough_subtitle_3,
      image: ic_walk3,
      buttonText: 'Get Started',
    ),
  ];

  @override
  void initState() {
    super.initState();
    print("OnboardingScreen initialized");
  }

  @override
  Widget build(BuildContext context) {
    print("OnboardingScreen building...");
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (BuildContext context, int index) {
              return OnboardingPage(
                onboardingEntity: _pages[index],
                onPressed: () {
                  if (index == _pages.length - 1) {
                    // Navigate to sign in screen for the last page
                    launchScreen(context, SignInScreen(), isNewTask: true);
                    sharedPref.setBool(IS_FIRST_TIME, false);
                  } else {
                    // Navigate to next page for other pages
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              );
            },
          ),
          // Skip button
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: () {
                launchScreen(context, SignInScreen(), isNewTask: true);
                sharedPref.setBool(IS_FIRST_TIME, false);
              },
              child: Text(
                language.skip,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          // Page indicators
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildPageIndicator(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageIndicator() {
    List<Widget> indicators = [];
    for (int i = 0; i < _pages.length; i++) {
      indicators.add(i == _currentPage ? _indicator(true) : _indicator(false));
    }
    return indicators;
  }

  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 4.0,
      width: isActive ? 22.0 : 20.0,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.lightGray,
        borderRadius: BorderRadius.circular(isActive ? 2.0 : 0),
      ),
    );
  }
}
