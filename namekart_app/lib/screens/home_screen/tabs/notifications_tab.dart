import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../activity_helpers/FirestoreHelper.dart';
import '../../../activity_helpers/UIHelpers.dart';
import '../../../change_notifiers/AllDatabaseChangeNotifiers.dart';
import '../../../change_notifiers/WebSocketService.dart';
import '../../../cutsom_widget/SuperAnimatedWidget.dart';
import '../../../database/HiveHelper.dart';
import '../../../fcm/FcmHelper.dart';
import '../../live_screens/live_details_screen.dart';


class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> with WidgetsBindingObserver {
  late Future<List<Map<String, dynamic>>> data;
  List<Map<String, dynamic>> dataList = [];

  static bool databaseRefresh = false;
  late ScrollController _scrollController;

  late FCMHelper _fcmHelper;
  late StreamSubscription<void> _notificationSubscription;

  List<String> subCollections = [];
  Map<String, String> subCollectionsWithNotificationsCount = {};
  Map<String, bool> isExpandedMap = {};
  Map<String, List<String>> parsedMap = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController = ScrollController();
    _fcmHelper = FCMHelper();

    getSubCollections();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationDatabaseChange =
      Provider.of<NotificationDatabaseChange>(context, listen: false);
      notificationDatabaseChange.addListener(getAllData);
    });

    getAllData();

  }

  void getAllData() async {
    WebSocketService w = WebSocketService();
    final response = await w.sendMessageGetResponse({
      "query": "firebase-allsubsubcollections",
      "path": "notifications"
    }, "user",expectedQuery: 'firebase-allsubsubcollections');

    final decoded = jsonDecode(response["data"]);
    final Map<String, dynamic> rawMap = decoded["response"];

    final sortedMap = Map.fromEntries(
      rawMap.entries.toList()
        ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase())),
    );

    setState(() {
      parsedMap = sortedMap.map(
            (key, value) => MapEntry(key, List<String>.from(value)),
      );
      isExpandedMap = {
        for (var key in parsedMap.keys) key: true,
      };
    });
  }

  void getSubCollections() async {
    subCollections = await getSubCollectionNames("notifications");
    setState(() {
      for (String subCollection in subCollections) {
        int s = HiveHelper.getUnreadCountFlexible("notifications~$subCollection");
        subCollectionsWithNotificationsCount[subCollection] = s.toString();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _notificationSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if (databaseRefresh) {
      databaseRefresh = false;
    }

    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      color: Colors.white,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Search Bar
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12, width: 1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: TextField(
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.black45,
                      fontSize: 10,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Search",
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (parsedMap.isNotEmpty)
                ListView.builder(
                  itemCount: parsedMap.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    String subCollection = parsedMap.keys.elementAt(index);
                    bool isExpanded = isExpandedMap[subCollection] ?? false;
                    List<String> responseList = parsedMap[subCollection] ?? [];

                    haptic();

                    return SuperAnimatedWidget(
                      effects: [AnimationEffect.fade, AnimationEffect.slide],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        child: Bounceable(
                          onTap: () {
                            setState(() {
                              isExpandedMap[subCollection] = !isExpanded;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: const Color(0xfff2f2f2),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Shimmer.fromColors(
                                        baseColor: Colors.black87,
                                        highlightColor: Colors.white,
                                        child: Text(
                                          subCollection,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      AnimatedRotation(
                                        turns: isExpanded ? 0.5 : 0.0,
                                        duration: const Duration(milliseconds: 300),
                                        child: const Icon(Icons.keyboard_arrow_down, size: 18),
                                      ),
                                    ],
                                  ),
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    alignment: Alignment.topCenter,
                                    child: (isExpanded && responseList.isNotEmpty)
                                        ? Column(
                                      children: responseList.map((item) {
                                        return Padding(
                                          padding: responseList.indexOf(item) == 0
                                              ? const EdgeInsets.only(top: 20)
                                              : const EdgeInsets.only(top: 10),
                                          child: Bounceable(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                PageRouteBuilder(
                                                  pageBuilder: (context, animation, secondaryAnimation) {
                                                    return LiveDetailsScreen(
                                                      mainCollection: "notifications",
                                                      subCollection: subCollection.trim(),
                                                      subSubCollection: item.trim(),
                                                      showHighlightsButton: false,
                                                      img: "assets/images/home_screen_images/appbar_images/notification.png",
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(15),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(30),
                                                color: Colors.white,
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item.trim(),
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.only(right: 80),
                                                    child: Text(
                                                      "${HiveHelper.getUnreadCountFlexible("notifications~$subCollection~${item.trim()}")} New Notification",
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 8,
                                                        fontWeight: FontWeight.bold,
                                                        color: (HiveHelper.getUnreadCountFlexible(
                                                            "notifications~$subCollection~${item.trim()}") ==
                                                            0)
                                                            ? Colors.black45
                                                            : const Color(0xff80B71C1C),
                                                      ),
                                                    ),
                                                  ),
                                                  const Icon(CupertinoIcons.arrow_right, size: 12),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

              if (parsedMap.isEmpty)
                const CircularProgressIndicator(),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
