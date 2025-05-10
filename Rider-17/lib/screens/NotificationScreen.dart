import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../main.dart';
import '../../network/RestApis.dart';
import '../../utils/constant/app_colors.dart';
import '../../utils/Common.dart';
import '../../utils/Extensions/app_common.dart';
import '../model/NotificationListModel.dart';
import '../screens/ComplaintListScreen.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import 'RideDetailScreen.dart';

class NotificationScreen extends StatefulWidget {
  @override
  NotificationScreenState createState() => NotificationScreenState();
}

class NotificationScreenState extends State<NotificationScreen>
    with TickerProviderStateMixin {
  ScrollController scrollController = ScrollController();
  int currentPage = 1;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool mIsLastPage = false;
  List<NotificationData> notificationData = [];
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();

    // Setup fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );

    _fadeController.forward();

    init();
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        if (!mIsLastPage) {
          appStore.setLoading(true);

          currentPage++;
          setState(() {});

          init();
        }
      }
    });
    afterBuildCreated(() => appStore.setLoading(true));
  }

  Future<void> refresh() async {
    setState(() {
      isRefreshing = true;
      currentPage = 1;
      notificationData.clear();
    });

    init();

    // Wait a moment to simulate network delay if needed
    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      isRefreshing = false;
    });

    return;
  }

  void init() async {
    getNotification(page: currentPage).then((value) {
      appStore.setLoading(false);
      mIsLastPage = value.notificationData!.length < currentPage;
      if (currentPage == 1) {
        notificationData.clear();
      }
      notificationData.addAll(value.notificationData!);
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);
      log(error);
    });
  }

  void markAsRead(NotificationData notification) {
    setState(() {
      notification.readAt = DateTime.now().toString();
    });

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    // Here you would call your API to update the notification status
    // markNotificationAsRead(notification.id).then((_) {
    //   // Handle success
    // }).catchError((error) {
    //   // Handle error
    // });
  }

  Color getNotificationColor(NotificationData data) {
    if (data.readAt == null) {
      return AppColors.lightGray.withOpacity(0.3);
    }
    return Colors.transparent;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/assets/images/backgroundFrame.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(language.notification,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          actions: [
            if (notificationData.isNotEmpty)
              IconButton(
                icon: Icon(Icons.done_all, color: Colors.white),
                onPressed: () {
                  // Mark all as read functionality
                  setState(() {
                    for (var notification in notificationData) {
                      if (notification.readAt == null) {
                        notification.readAt = DateTime.now().toString();
                      }
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("All notifications marked as read"),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      body: Observer(builder: (context) {
        return Stack(
          children: [
            // Curved background extension from AppBar
            Container(
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
            ),

            FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: refresh,
                color: AppColors.primary,
                child: notificationData.isNotEmpty
                    ? AnimationLimiter(
                        child: ListView.separated(
                          controller: scrollController,
                          padding: EdgeInsets.only(
                              top: 30, left: 16, right: 16, bottom: 16),
                          itemCount: notificationData.length,
                          physics: AlwaysScrollableScrollPhysics(),
                          itemBuilder: (_, index) {
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: Duration(milliseconds: 500),
                              child: SlideAnimation(
                                horizontalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: _buildNotificationItem(
                                      notificationData[index]),
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (context, index) {
                            return Divider(
                                height: 20,
                                thickness: 1,
                                color: Colors.grey.withOpacity(0.1));
                          },
                        ),
                      )
                    : !appStore.isLoading
                        ? _buildEmptyState()
                        : SizedBox(),
              ),
            ),

            Visibility(
              visible: appStore.isLoading && !isRefreshing,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildNotificationItem(NotificationData data) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              setState(() {
                notificationData.remove(data);
              });
              // Show a snackbar with option to undo
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Notification removed"),
                  backgroundColor: AppColors.primary,
                  action: SnackBarAction(
                    label: "UNDO",
                    onPressed: () {
                      setState(() {
                        notificationData.add(data);
                      });
                    },
                  ),
                ),
              );
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
          if (data.readAt == null)
            SlidableAction(
              onPressed: (context) {
                markAsRead(data);
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: Icons.done,
              label: 'Read',
            ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          if (data.readAt == null) {
            markAsRead(data);
          }

          if (data.data!.type == COMPLAIN_COMMENT) {
            launchScreen(context,
                ComplaintListScreen(complaint: data.data!.complaintId!));
          } else if (data.data!.subject! == 'Completed') {
            launchScreen(context, RideDetailScreen(orderId: data.data!.id!));
          }
        },
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: getNotificationColor(data),
            borderRadius: BorderRadius.circular(12),
            boxShadow: data.readAt == null
                ? [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.data != null && data.data!.type != "push_notification")
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ImageIcon(
                      AssetImage(statusTypeIcon(type: data.data!.type)),
                      color: AppColors.primary,
                      size: 22),
                ),
              if (data.data != null && data.data!.type != "push_notification")
                SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        data.data != null &&
                                data.data!.type != "push_notification" &&
                                data.data!.id != null
                            ? Expanded(
                                child: Text(
                                    '${language.rideId} #${data.data!.id} ${data.data!.subject}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: data.readAt == null
                                          ? AppColors.textColor
                                          : Colors.grey[600],
                                    )))
                            : Expanded(
                                child: Text("${data.data!.subject}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: data.readAt == null
                                          ? AppColors.textColor
                                          : Colors.grey[600],
                                    ))),
                        SizedBox(width: 8),
                        Text(data.createdAt.validate(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            )),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text('${data.data!.message}',
                        style: TextStyle(
                          fontSize: 14,
                          color: data.readAt == null
                              ? AppColors.textColor
                              : Colors.grey[600],
                        )),
                    if (data.readAt == null)
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          margin: EdgeInsets.only(top: 8),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey[350],
          ),
          SizedBox(height: 16),
          Text(
            "No notifications yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            "We'll notify you when something arrives!",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 24),
          TextButton.icon(
            onPressed: () {
              refresh();
            },
            icon: Icon(Icons.refresh, color: AppColors.primary),
            label: Text(
              "Refresh",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
