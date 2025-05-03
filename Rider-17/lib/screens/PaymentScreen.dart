import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../main.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';

class PaymentScreen extends StatefulWidget {
  final num? amount;

  PaymentScreen({this.amount});

  @override
  PaymentScreenState createState() => PaymentScreenState();
}

class PaymentScreenState extends State<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically return success after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pop(context, true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Payment", style: boldTextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.amount != null)
              Text(
                "Processing payment of \$${widget.amount}",
                style: boldTextStyle(size: 18),
                textAlign: TextAlign.center,
              ),
            SizedBox(height: 30),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  SizedBox(height: 20),
                  Text(
                    "Payment is being processed...\nPlease wait",
                    style: primaryTextStyle(),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Payment will be automatically marked as successful\nfor testing purposes",
              style: secondaryTextStyle(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
