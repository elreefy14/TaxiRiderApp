import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../model/SettingModel.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/LiveStream.dart';
import '../utils/Extensions/app_common.dart';
import 'AboutScreen.dart';
import 'ChangePasswordScreen.dart';
import 'DeleteAccountScreen.dart';
import 'LanguageScreen.dart';
import 'TermsConditionScreen.dart';
import '../components/ModernAppBar.dart';

class SettingScreen extends StatefulWidget {
  @override
  SettingScreenState createState() => SettingScreenState();
}

class SettingScreenState extends State<SettingScreen>
    with SingleTickerProviderStateMixin {
  SettingModel settingModel = SettingModel();
  String? privacyPolicy;
  String? termsCondition;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Track which setting is being pressed
  int? _pressedSetting;

  @override
  void initState() {
    super.initState();

    // Set system UI overlay style for a more immersive experience
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Define animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();

    init();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void init() async {
    LiveStream().on(CHANGE_LANGUAGE, (p0) {
      setState(() {});
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ModernAppBar(
        title: language.settings,
      ),
      body: Stack(
        children: [
          // Background design - subtle gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    primaryColor.withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ),

          FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 24, top: 16),
              child: Column(
                children: [
                  // Profile section with car icon
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            MaterialCommunityIcons.car,
                            color: primaryColor,
                            size: 28,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appStore.userName.isEmpty
                                    ? language.guest
                                    : appStore.userName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                appStore.userEmail.isEmpty
                                    ? language.guest
                                    : appStore.userEmail,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Account settings section
                  _buildSectionTitle("Account"),

                  Visibility(
                    visible: sharedPref.getString(LOGIN_TYPE) != 'mobile' &&
                        sharedPref.getString(LOGIN_TYPE) != LoginTypeGoogle &&
                        sharedPref.getString(LOGIN_TYPE) != null,
                    child: _buildSettingItem(
                      icon: MaterialCommunityIcons.lock_outline,
                      title: language.changePassword,
                      onTap: () {
                        launchScreen(context, ChangePasswordScreen(),
                            pageRouteAnimation: PageRouteAnimation.Slide);
                      },
                      index: 0,
                    ),
                  ),

                  _buildSettingItem(
                    icon: MaterialCommunityIcons.translate,
                    title: language.language,
                    onTap: () {
                      launchScreen(context, LanguageScreen(),
                          pageRouteAnimation: PageRouteAnimation.Slide);
                    },
                    index: 1,
                  ),

                  SizedBox(height: 24),

                  // Legal section
                  _buildSectionTitle("Legal & Support"),

                  if (appStore.privacyPolicy != null)
                    _buildSettingItem(
                      icon: MaterialCommunityIcons.shield_check_outline,
                      title: language.privacyPolicy,
                      onTap: () {
                        launchScreen(
                            context,
                            TermsConditionScreen(
                                title: language.privacyPolicy,
                                subtitle: appStore.privacyPolicy),
                            pageRouteAnimation: PageRouteAnimation.Slide);
                      },
                      index: 2,
                    ),

                  if (appStore.mHelpAndSupport != null)
                    _buildSettingItem(
                      icon: MaterialCommunityIcons.help_circle_outline,
                      title: language.helpSupport,
                      onTap: () {
                        if (appStore.mHelpAndSupport != null) {
                          launchUrl(Uri.parse(appStore.mHelpAndSupport!));
                        } else {
                          toast(language.txtURLEmpty);
                        }
                      },
                      index: 3,
                    ),

                  if (appStore.termsCondition != null)
                    _buildSettingItem(
                      icon: MaterialCommunityIcons.file_document_outline,
                      title: language.termsConditions,
                      onTap: () {
                        if (appStore.termsCondition != null) {
                          launchScreen(
                              context,
                              TermsConditionScreen(
                                  title: language.termsConditions,
                                  subtitle: appStore.termsCondition),
                              pageRouteAnimation: PageRouteAnimation.Slide);
                        } else {
                          toast(language.txtURLEmpty);
                        }
                      },
                      index: 4,
                    ),

                  _buildSettingItem(
                    icon: MaterialCommunityIcons.information_outline,
                    title: language.aboutUs,
                    onTap: () {
                      launchScreen(context,
                          AboutScreen(settingModel: appStore.settingModel),
                          pageRouteAnimation: PageRouteAnimation.Slide);
                    },
                    index: 5,
                  ),

                  SizedBox(height: 24),

                  // Danger zone
                  _buildSectionTitle("Danger Zone", isDanger: true),

                  _buildSettingItem(
                    icon: MaterialCommunityIcons.delete_outline,
                    title: language.deleteAccount,
                    color: Colors.red,
                    onTap: () {
                      launchScreen(context, DeleteAccountScreen(),
                          pageRouteAnimation: PageRouteAnimation.Slide);
                    },
                    index: 6,
                  ),

                  // App version
                  SizedBox(height: 40),
                  Text(
                    "Version 1.0.0",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool isDanger = false}) {
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: isDanger ? Colors.red[700] : primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required Function() onTap,
    Color? color,
    required int index,
  }) {
    bool isPressed = _pressedSetting == index;

    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      decoration: BoxDecoration(
        color: isPressed
            ? (color != null
                ? color.withOpacity(0.1)
                : primaryColor.withOpacity(0.05))
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color != null
              ? color.withOpacity(0.5)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: isPressed
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onTapDown: (_) {
            setState(() {
              _pressedSetting = index;
            });
          },
          onTapUp: (_) {
            Future.delayed(Duration(milliseconds: 100), () {
              if (mounted) {
                setState(() {
                  _pressedSetting = null;
                });
              }
            });
          },
          onTapCancel: () {
            setState(() {
              _pressedSetting = null;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color != null
                        ? color.withOpacity(0.1)
                        : primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: color != null ? color : primaryColor,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: color != null ? color : Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  MaterialCommunityIcons.chevron_right,
                  size: 20,
                  color:
                      color != null ? color.withOpacity(0.7) : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
