import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/constant/app_colors.dart';
import 'utils/constant/styles/app_font_family.dart';
import 'utils/Extensions/app_common.dart';

class AppTheme {
  //
  AppTheme._();

  static final ThemeData lightTheme = ThemeData(
    textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionHandleColor: AppColors.primary,
        selectionColor: AppColors.primary.withOpacity(0.3)),
    primarySwatch: createMaterialColor(AppColors.primary),
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.white,
    fontFamily: AppFontFamilies.sfRoboto,
    bottomNavigationBarTheme:
        BottomNavigationBarThemeData(backgroundColor: AppColors.white),
    iconTheme: IconThemeData(color: AppColors.black),
    textTheme: TextTheme(titleLarge: TextStyle()),
    dialogBackgroundColor: AppColors.white,
    unselectedWidgetColor: AppColors.black,
    dividerColor: AppColors.lightGray,
    cardColor: AppColors.white,
    listTileTheme: ListTileThemeData(iconColor: AppColors.white),
    dialogTheme: DialogTheme(shape: dialogShape()),
    appBarTheme: AppBarTheme(
      color: AppColors.primary,
      iconTheme: IconThemeData(color: AppColors.white),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
    ),
  ).copyWith(
    pageTransitionsTheme: PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    primarySwatch: createMaterialColor(AppColors.primary),
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.black,
    fontFamily: AppFontFamilies.sfRoboto,
    bottomNavigationBarTheme:
        BottomNavigationBarThemeData(backgroundColor: AppColors.black),
    iconTheme: IconThemeData(color: AppColors.white),
    textTheme: TextTheme(titleLarge: TextStyle(color: AppColors.gray)),
    dialogBackgroundColor: AppColors.black,
    unselectedWidgetColor: AppColors.white.withOpacity(0.6),
    dividerColor: AppColors.white.withOpacity(0.12),
    cardColor: AppColors.black,
    dialogTheme: DialogTheme(shape: dialogShape()),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),
  ).copyWith(
    pageTransitionsTheme: PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
