import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../components/SearchLocationComponent.dart';
import '../main.dart';
import '../model/ServiceModel.dart';
import '../model/AppSettingModel.dart';
import '../network/RestApis.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/context_extension.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import '../utils/Common.dart';
import '../utils/constant/app_colors.dart';
import 'NewEstimateRideListWidget.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<ServiceList> serviceList = [];
  bool isLoading = false;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Set status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    init();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void init() async {
    isLoading = true;
    setState(() {});

    await getServices().then((value) {
      if (value.data != null && value.data!.isNotEmpty) {
        serviceList = value.data!;
      }
      setState(() {});
    }).catchError((error) {
      log(error.toString());
    });

    isLoading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Content
                    SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Spacer for AppBar
                          SizedBox(
                              height:
                                  180), // Adjusted height to accommodate AppBar and search bar

                          // Service Categories
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 20),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'اقتراحات',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'الجميع',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),

                                // Horizontal Service List
                                serviceList.isEmpty
                                    ? Center(
                                        child: Text(
                                          'لا توجد خدمات متاحة',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      )
                                    : SizedBox(
                                        height: 110,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: serviceList.length,
                                          itemBuilder: (context, index) {
                                            ServiceList service =
                                                serviceList[index];
                                            return Container(
                                              width: 100,
                                              margin:
                                                  EdgeInsets.only(right: 12),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    height: 70,
                                                    width: 70,
                                                    padding: EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: Color(0xFFE8F5E9),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(
                                                                  0.05),
                                                          blurRadius: 8,
                                                          offset: Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: service
                                                                .serviceImage !=
                                                            null
                                                        ? Image.network(
                                                            service
                                                                .serviceImage!,
                                                            fit: BoxFit.contain,
                                                            errorBuilder: (context,
                                                                    error,
                                                                    stackTrace) =>
                                                                SvgPicture
                                                                    .asset(
                                                              'assets/assets/icons/sedan.svg',
                                                              color: Color(
                                                                  0xFF4CAF50),
                                                            ),
                                                          )
                                                        : SvgPicture.asset(
                                                            'assets/assets/icons/sedan.svg',
                                                            color: Color(
                                                                0xFF4CAF50),
                                                          ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    service.name ?? 'خدمة',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          Colors.grey.shade800,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                              ],
                            ),
                          ),

                          // Welcome Message Image
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 20),
                            child: Image.asset(
                              'assets/assets/images/home_welcome_message.png',
                              fit: BoxFit.fitWidth,
                            ),
                          ),

                          SizedBox(
                              height: 80), // Extra space for bottom navigation
                        ],
                      ),
                    ),

                    // Modern AppBar with floating search bar
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          // Custom AppBar
                          Container(
                            height:
                                140, // Increased height to accommodate the floating search bar
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF4CAF50), // Primary green
                                  Color(0xFF43A047), // Slightly darker green
                                ],
                              ),
                              image: DecorationImage(
                                image: AssetImage(
                                    'assets/assets/images/app_bar_background.png'),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Color(0xFF4CAF50).withOpacity(0.8),
                                  BlendMode.srcATop,
                                ),
                              ),
                            ),
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).padding.top,
                              left: 16,
                              right: 16,
                              bottom:
                                  30, // Extra padding at bottom for the search bar overlap
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Notification Bell
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.notifications_none_outlined,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),

                                // Welcome Text (Right to Left)
                                Row(
                                  children: [
                                    // Profile image
                                    Container(
                                      width: 45,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        image: DecorationImage(
                                          image: NetworkImage(
                                              appStore.userProfile),
                                          fit: BoxFit.cover,
                                          onError: (error, stackTrace) =>
                                              AssetImage(
                                                  'assets/placeholder.jpg'),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    // Welcome text (right aligned for Arabic)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'أهلا بك في مسارك',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'يوسف محمد',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Floating Search Bar - positioned to be half outside the AppBar
                    Positioned(
                      top:
                          115, // Precisely positioned to be half inside and half outside AppBar
                      left: 24,
                      right: 24,
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                            ),
                            builder: (_) => SearchLocationComponent(
                              title: sourceLocationTitle,
                            ),
                          );
                        },
                        child: Container(
                          height: 56,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 12,
                                spreadRadius: 0,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search,
                                color: Colors.grey.shade600,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'ابحث عن ما تريد',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildNavItem(
      {required IconData icon,
      required String label,
      bool isSelected = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected ? Color(0xFF4CAF50) : Colors.grey,
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Color(0xFF4CAF50) : Colors.grey,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
