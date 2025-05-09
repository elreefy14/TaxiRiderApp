import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart' as lt;
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../components/SearchLocationComponent.dart';
import '../main.dart';
import '../model/CurrentRequestModel.dart';
import '../model/NearByDriverListModel.dart';
import '../network/RestApis.dart';
import '../screens/ReviewScreen.dart';
import '../screens/RidePaymentDetailScreen.dart';
import '../service/RideService.dart';
import '../service/VersionServices.dart';
import '../utils/constant/app_colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/LiveStream.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/app_textfield.dart';
import '../utils/Extensions/context_extension.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import '../utils/images.dart';
import 'BidingScreen.dart';
import 'LocationPermissionScreen.dart';
import 'NewEstimateRideListWidget.dart';
import 'NotificationScreen.dart';
import 'ScheduleRideListScreen.dart';

class DashBoardScreen extends StatefulWidget {
  @override
  DashBoardScreenState createState() => DashBoardScreenState();
  String? cancelReason;

  DashBoardScreen({this.cancelReason});
}

class DashBoardScreenState extends State<DashBoardScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  RideService rideService = RideService();
  List<Marker> markers = [];
  Set<Polyline> _polyLines = Set<Polyline>();
  List<LatLng> polylineCoordinates = [];
  late PolylinePoints polylinePoints;
  OnRideRequest? servicesListData;
  double cameraZoom = 17.0, cameraTilt = 0;
  double cameraBearing = 30;
  int onTapIndex = 0;
  int selectIndex = 0;
  late StreamSubscription<ServiceStatus> serviceStatusStream;
  LocationPermission? permissionData;
  late BitmapDescriptor driverIcon;
  List<NearByDriverListModel>? nearDriverModel;
  GoogleMapController? mapController;
  PanelController panelController = PanelController();

  // Animation controllers
  late AnimationController _mapElementsAnimationController;
  late Animation<double> _mapElementsFadeAnimation;

  late AnimationController _panelAnimationController;
  late Animation<double> _panelScaleAnimation;

  late AnimationController _quickActionAnimationController;
  late Animation<Offset> _quickActionSlideAnimation;

  bool isMapReady = false;
  bool isFirstLoad = true;
  bool isSearchBarFocused = false;

  List<OnRideRequest> schedule_ride_request = [];

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _mapElementsAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _mapElementsFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _mapElementsAnimationController,
        curve: Curves.easeIn,
      ),
    );

    _panelAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    _panelScaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _panelAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _quickActionAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _quickActionSlideAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _quickActionAnimationController,
        curve: Interval(0.3, 1.0, curve: Curves.fastOutSlowIn),
      ),
    );

    // Start animations
    Future.delayed(Duration(milliseconds: 150), () {
      _mapElementsAnimationController.forward();
    });

    Future.delayed(Duration(milliseconds: 600), () {
      _panelAnimationController.forward();
      _quickActionAnimationController.forward();
    });

    locationPermission();
    if (app_update_check != null) {
      VersionService().getVersionData(context, app_update_check);
    }
    if (widget.cancelReason != null) {
      afterBuildCreated(() {
        _triggerCanceledPopup();
      });
    } else {
      getCurrentRequest();
    }
    afterBuildCreated(() {
      init();
    });
  }

  void init() async {
    getCurrentUserLocation();
    riderIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(
          devicePixelRatio: 2.5,
        ),
        Platform.isIOS ? SourceIOSIcon : SourceIcon);
    driverIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5),
        Platform.isIOS ? DriverIOSIcon : MultipleDriver);
    await getAppSettingsData();

    polylinePoints = PolylinePoints();
  }

  Future<void> getCurrentUserLocation() async {
    if (permissionData != LocationPermission.denied) {
      if (sourceLocation != null) {
        polylineSource =
            LatLng(sourceLocation!.latitude, sourceLocation!.longitude);
        addMarker();
        startLocationTracking();
        await getNearByDriver();
        return;
      }
      final geoPosition = await Geolocator.getCurrentPosition(
              timeLimit: Duration(seconds: 30),
              desiredAccuracy: LocationAccuracy.high)
          .catchError((error) {
        launchScreen(navigatorKey.currentState!.overlay!.context,
            LocationPermissionScreen());
      });
      sourceLocation = LatLng(geoPosition.latitude, geoPosition.longitude);
      try {
        List<Placemark>? placemarks = await placemarkFromCoordinates(
            geoPosition.latitude, geoPosition.longitude);
        await getNearByDriver();

        //set Country
        sharedPref.setString(COUNTRY,
            placemarks[0].isoCountryCode.validate(value: defaultCountry));

        Placemark place = placemarks[0];
        if (place != null) {
          sourceLocationTitle =
              "${place.name != null ? place.name : place.subThoroughfare}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea} ${place.postalCode}, ${place.country}";
          polylineSource = LatLng(geoPosition.latitude, geoPosition.longitude);
        }
      } catch (e) {
        throw e;
      }
      addMarker();
      startLocationTracking();

      setState(() {});
    } else {
      launchScreen(navigatorKey.currentState!.overlay!.context,
          LocationPermissionScreen());
    }
  }

  Future<void> getCurrentRequest() async {
    await getCurrentRideRequest().then((value) async {
      servicesListData = value.rideRequest ?? value.onRideRequest;
      print("CHecking140");
      schedule_ride_request = value.schedule_ride_request ?? [];
      print("CHecking142");
      print("CHecking142::${schedule_ride_request.length}");
      if (servicesListData == null && schedule_ride_request.isNotEmpty) {
        schedule_ride_request.map(
          (e) => e.schedule_datetime,
        );

        var d1 = DateTime.parse(
            DateTime.now().toUtc().toString().replaceAll("Z", ""));
        var d2 = DateTime.parse(
            schedule_ride_request.first.schedule_datetime.toString());

        print("CheckBothDate:::D1:::$d1 ===>D2: $d2");
        print("CHecking148");
        print("CHecking148.2");
        if (d1.isAfter(d2)) {
          print("CHecking150::}");
          servicesListData = schedule_ride_request.first;
          print("CHecking161:::${servicesListData!.toJson()}");
        } else {
          scheduleFunction(
              scheduledTime: d2.add(Duration(seconds: 5)),
              function: () => getCurrentRequest());
        }
      }
      if (servicesListData == null) {
        sharedPref.remove(REMAINING_TIME);
        sharedPref.remove(IS_TIME);
        setState(() {});
      }
      print("169");
      if (servicesListData != null) {
        print("171");
        if ((value.ride_has_bids == 1) &&
            (servicesListData!.status == NEW_RIDE_REQUESTED ||
                servicesListData!.status == "bid_rejected")) {
          launchScreen(
            context,
            isNewTask: true,
            Bidingscreen(
              dt: servicesListData!.isSchedule == 1
                  ? servicesListData!.schedule_datetime
                  : servicesListData!.datetime,
              ride_id: servicesListData!.id!,
              source: {},
              endLocation: {},
              multiDropObj: {},
              multiDropLocationNamesObj: {},
            ),
            pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
          );
        } else if (servicesListData!.status != COMPLETED &&
            servicesListData!.status != CANCELED) {
          int x = 0;
          if (value.rideRequest == null && value.onRideRequest == null) {
            x = servicesListData!.id!;
          } else {
            x = value.rideRequest != null
                ? value.rideRequest!.id!
                : value.onRideRequest!.id!;
          }
          QuerySnapshot<Object?> b =
              await rideService.checkIsRideExist(rideId: x);
          if (b.docs.length > 0) {
            //   Check Condition so screen looping issue not occur
            //   if Ride Not exist in firebase than don't navigate to next screen
            launchScreen(
              getContext,
              NewEstimateRideListWidget(
                dt: servicesListData!.isSchedule == 1
                    ? servicesListData!.schedule_datetime
                    : servicesListData!.datetime,
                sourceLatLog: LatLng(
                    double.parse(servicesListData!.startLatitude!),
                    double.parse(servicesListData!.startLongitude!)),
                destinationLatLog: LatLng(
                    double.parse(servicesListData!.endLatitude!),
                    double.parse(servicesListData!.endLongitude!)),
                sourceTitle: servicesListData!.startAddress!,
                destinationTitle: servicesListData!.endAddress!,
                isCurrentRequest: true,
                servicesId: servicesListData!.serviceId,
                id: servicesListData!.id,
              ),
              pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
            );
          } else {
            if (value.schedule_ride_request != null &&
                value.schedule_ride_request!.isNotEmpty) {
              if (value.schedule_ride_request!.first.id == x) {
                return;
              }
            }
            return toast(rideNotFound);
          }
        } else if (servicesListData!.status == COMPLETED &&
            servicesListData!.isRiderRated == 0) {
          Future.delayed(
            Duration(seconds: 1),
            () {
              launchScreen(
                  getContext,
                  ReviewScreen(
                      rideRequest: servicesListData!, driverData: value.driver),
                  pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
                  isNewTask: true);
            },
          );
        }
      } else if (value.payment != null &&
          value.payment!.paymentStatus != "paid") {
        print("222");
        launchScreen(getContext,
            RidePaymentDetailScreen(rideId: value.payment!.rideRequestId),
            pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
            isNewTask: true);
      }
    }).catchError((error, s) {
      log(error.toString() + "::$s");
      print("CHecking200:::$error ===$s");
    });
  }

  Future<void> locationPermission() async {
    serviceStatusStream =
        Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      if (status == ServiceStatus.disabled) {
        launchScreen(navigatorKey.currentState!.overlay!.context,
            LocationPermissionScreen());
      } else if (status == ServiceStatus.enabled) {
        getCurrentUserLocation();
        if (locationScreenKey.currentContext != null) {
          if (Navigator.canPop(navigatorKey.currentState!.overlay!.context)) {
            Navigator.pop(navigatorKey.currentState!.overlay!.context);
          }
        }
      }
    }, onError: (error) {
      //
    });
  }

  addMarker() {
    markers.add(
      Marker(
        markerId: MarkerId('Order Detail'),
        position: sourceLocation!,
        draggable: true,
        infoWindow: InfoWindow(title: sourceLocationTitle, snippet: ''),
        icon: riderIcon,
      ),
    );
  }

  Future<void> startLocationTracking() async {
    Map req = {
      "latitude": sourceLocation!.latitude.toString(),
      "longitude": sourceLocation!.longitude.toString(),
    };
    await updateStatus(req).then((value) {}).catchError((error) {
      log(error);
    });
  }

  Future<BitmapDescriptor> getNetworkImageMarker(String imageUrl) async {
    print("OPERATION111");
    final http.Response response = await http.get(Uri.parse(imageUrl));
    final Uint8List bytes = response.bodyBytes;

    // Load the image as a codec (which includes its dimensions)
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    print("OPERATION222");
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    print("OPERATION232");
    final ByteData? byteData =
        await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
    print("OPERATION232");
    final Uint8List resizedBytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(resizedBytes);
  }

  Future<void> getNearByDriver() async {
    await getNearByDriverList(latLng: sourceLocation).then((value) async {
      value.data!.forEach((element) async {
        print("CHECKIMAGE:::${element}");
        try {
          var driverIcon1 =
              await getNetworkImageMarker(element.service_marker.validate());
          markers.add(
            Marker(
              markerId: MarkerId('Driver${element.id}'),
              position: LatLng(double.parse(element.latitude!.toString()),
                  double.parse(element.longitude!.toString())),
              infoWindow: InfoWindow(
                  title: '${element.firstName} ${element.lastName}',
                  snippet: ''),
              icon: driverIcon1,
            ),
          );
          setState(() {});
        } catch (e, s) {
          markers.add(
            Marker(
              markerId: MarkerId('Driver${element.id}'),
              position: LatLng(double.parse(element.latitude!.toString()),
                  double.parse(element.longitude!.toString())),
              infoWindow: InfoWindow(
                  title: '${element.firstName} ${element.lastName}',
                  snippet: ''),
              icon: driverIcon,
            ),
          );
          setState(() {});
        }
      });
    }).catchError((e, s) {
      print("ERROR  FOUND:::$e ++++>$s");
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    LiveStream().on(CHANGE_LANGUAGE, (p0) {
      setState(() {});
    });
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Map
          GoogleMap(
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: sourceLocation ?? LatLng(0.00, 0.00),
              zoom: cameraZoom,
              bearing: cameraBearing,
              tilt: cameraTilt,
            ),
            markers: markers.map((e) => e).toSet(),
            polylines: _polyLines,
            compassEnabled: false,
            onMapCreated: (GoogleMapController controller) async {
              mapController = controller;
              setState(() {
                isMapReady = true;
              });
            },
          ),

          // Status bar space with semi-transparent gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: context.statusBarHeight + 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Top bar with search and notification button
          FadeTransition(
            opacity: _mapElementsFadeAnimation,
            child: Positioned(
              top: context.statusBarHeight + 16,
              right: 16,
              left: 16,
              child: Row(
                children: [
                  // Search/location button
                  Expanded(
                    child: InkWell(
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
                              title: sourceLocationTitle),
                        );
                      },
                      child: Container(
                        height: 50,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 0,
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(MaterialCommunityIcons.magnify,
                                color: AppColors.primary),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                sourceLocationTitle != null &&
                                        sourceLocationTitle.isNotEmpty
                                    ? sourceLocationTitle.length > 30
                                        ? '${sourceLocationTitle.substring(0, 30)}...'
                                        : sourceLocationTitle
                                    : 'where to',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  // Notification button
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(MaterialCommunityIcons.bell_outline,
                          color: AppColors.primary),
                      onPressed: () {
                        launchScreen(context, NotificationScreen());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick action buttons (my location)
          SlideTransition(
            position: _quickActionSlideAnimation,
            child: Positioned(
              bottom: 150,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(MaterialCommunityIcons.crosshairs_gps,
                      color: AppColors.primary),
                  onPressed: () async {
                    final geoPosition = await Geolocator.getCurrentPosition(
                            timeLimit: Duration(seconds: 30),
                            desiredAccuracy: LocationAccuracy.high)
                        .catchError((error) {
                      launchScreen(navigatorKey.currentState!.overlay!.context,
                          LocationPermissionScreen());
                    });

                    if (mapController != null) {
                      mapController!.animateCamera(CameraUpdate.newLatLng(
                          LatLng(geoPosition.latitude, geoPosition.longitude)));
                    }
                  },
                ),
              ),
            ),
          ),

          // Scheduled rides button
          if (appStore.isScheduleRide == "1" &&
              schedule_ride_request.isNotEmpty)
            SlideTransition(
              position: _quickActionSlideAnimation,
              child: Positioned(
                bottom: 216,
                right: 16,
                child: InkWell(
                  onTap: () {
                    launchScreen(context, ScheduleRideListScreen());
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        lt.Lottie.asset(
                          taxiAnim,
                          height: 30,
                          width: 30,
                          fit: BoxFit.cover,
                        ),
                        SizedBox(width: 8),
                        Text(
                          language.schedule_list_title ??
                              "Your Scheduled Rides",
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Loading indicator
          Observer(
            builder: (context) => Visibility(
              visible: appStore.isLoading,
              child: Container(
                color: Colors.black26,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
          ),

          // Bottom sliding panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _panelScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _panelScaleAnimation.value,
                  alignment: Alignment.bottomCenter,
                  child: SlidingUpPanel(
                    controller: panelController,
                    padding: EdgeInsets.all(16),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    minHeight: 140,
                    maxHeight: 140,
                    backdropTapClosesPanel: true,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                    panel: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            margin: EdgeInsets.only(bottom: 16),
                            height: 5,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        Text(
                          language.whatWouldYouLikeToGo.capitalizeFirstLetter(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 16),
                        InkWell(
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
                                  title: sourceLocationTitle),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.search, color: AppColors.primary),
                                SizedBox(width: 12),
                                Text(
                                  language.enterYourDestination,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _triggerCanceledPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "${language.rideCanceledByDriver}",
                  maxLines: 2,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.close, size: 20, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${language.cancelledReason}",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.cancelReason.validate(),
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  minimumSize: Size(double.infinity, 48),
                ),
                child: Text(
                  "OK",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          contentPadding: EdgeInsets.fromLTRB(24, 16, 24, 24),
        );
      },
    );
  }

  Future<void> cancelRequest(String reason, {int? ride_id}) async {
    Map req = {
      "id": ride_id,
      "cancel_by": RIDER,
      "status": CANCELED,
      "reason": reason,
    };
    await rideRequestUpdate(request: req, rideId: ride_id).then((value) async {
      getCurrentRequest();
      toast(value.message);
    }).catchError((error) {});
  }

  @override
  void dispose() {
    _mapElementsAnimationController.dispose();
    _panelAnimationController.dispose();
    _quickActionAnimationController.dispose();
    if (serviceStatusStream != null) {
      serviceStatusStream.cancel();
    }
    super.dispose();
  }
}
