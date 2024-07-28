import 'package:cinemate/screens/chatbot.dart';
import 'package:flutter/material.dart';
import 'package:cinemate/widgets/options.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class NaviBar extends StatefulWidget {
  const NaviBar({super.key});

  @override
  State<NaviBar> createState() => _NaviBarState();
}

class _NaviBarState extends State<NaviBar> {
  int selindex = 0;
  void selectindex(int index) {
    setState(() {
      selindex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: option.elementAt(selindex),
      ),
      bottomNavigationBar: Container(
        color: Colors.black87,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          child: GNav(
            onTabChange: selectindex,
            color: Colors.white,
            activeColor: Colors.amber[700],
            tabBackgroundColor: Colors.transparent,
            gap: 8,
            tabs: [
              GButton(
                icon: Icons.home,
                text: "Home",
                textColor: Colors.amber[700],
              ),
              GButton(
                icon: Icons.search,
                text: "Search",
                textColor: Colors.amber[700],
              ),
              GButton(
                icon: Icons.favorite,
                text: "Favorite",
                textColor: Colors.amber[700],
              ),
              GButton(
                icon: Icons.person,
                text: "Profile",
                textColor: Colors.amber[700],
              )
            ],
          ),
        ),
      ),
      floatingActionButton: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(
                  bottom:
                      72.0), // FAB'nin alt gezinme çubuğuna olan mesafesini ayarlar
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const ChatBotPage()));
                },
                backgroundColor: Colors.amber[700],
                shape: const CircleBorder(),
                tooltip: "ChatBot",
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
