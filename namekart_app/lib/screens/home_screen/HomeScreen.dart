import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flashy_tab_bar2/flashy_tab_bar2.dart';
import 'package:namekart_app/screens/home_screen/tabs/ProfileTab.dart';
import 'package:namekart_app/screens/home_screen/tabs/home_tab.dart';
import 'package:namekart_app/screens/home_screen/tabs/notifications_tab.dart';

import '../../cutsom_widget/customSyncWidget.dart';
import '../notifications_screen/NotificationScreen.dart';
import 'helpdesk/HelpDesk.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const HomeTab(),
    const NotificationsTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.black,
        title: Image.asset(
          "assets/images/login_screen_images/loginpagenamekartlogo.png",
          width: 120.sp,
        ),
        actions: [
          Icon(
            Icons.refresh_rounded,
            color: Color(0xff717171),
          ),
          SizedBox(
            width: 10,
          ),Bounceable(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HelpDesk()),
                );
              },
              child: Icon(
                Icons.help_center,
                color: Color(0xff717171),
              )),
          SizedBox(
            width: 10,
          )
        ],
      ),
      body: AlertWidget(
      onReconnectSuccess: () {},
    path: '',
    child: _tabs[_selectedIndex]),
      bottomNavigationBar: FlashyTabBar(
        selectedIndex: _selectedIndex,
        showElevation: false,
        backgroundColor: Colors.transparent,
        onItemSelected: (index) => setState(() => _selectedIndex = index),

        items: [
          FlashyTabBarItem(
            icon: const Icon(Icons.home_outlined),
            title: const Text("Home"),
          ),
          FlashyTabBarItem(
            icon: const Icon(Icons.live_tv_rounded),
            title: const Text("Channels"),
          ),
          FlashyTabBarItem(
            icon: const Icon(Icons.person_2_outlined),
            title: const Text("Profile"),
          ),
        ],
      ),
    );
  }
}
