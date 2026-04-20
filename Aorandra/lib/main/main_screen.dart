import 'package:flutter/material.dart';

// SCREENS
import '../features/home/ui/home_screen.dart';
import '../features/aoris/ui/aoris_screen.dart';
import '../features/chat/ui/chat_list_screen.dart';
import '../features/profile/ui/profile_screen.dart';

/// ===============================
/// MAIN SCREEN (ROOT NAVIGATION)
/// ===============================
///
/// Controls bottom navigation between:
/// - Home
/// - Aoris (Reels)
/// - Camera (placeholder)
/// - Chat
/// - Profile
///
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// Current selected tab index
  int currentIndex = 0;

  /// ===============================
  /// SHARE HANDLER (GLOBAL)
  /// ===============================
  ///
  /// This function will be passed to AorisScreen
  /// so it can trigger share actions
  ///
  void _handleShare(Map video) {
    // 🔥 Temporary logic (you can replace later)
    debugPrint("Sharing video: ${video['id']}");
  }

  /// ===============================
  /// PAGES LIST
  /// ===============================
  ///
  /// Each index corresponds to a tab
  ///
  late final List<Widget> pages = [
    const HomeScreen(),

    /// AORIS SCREEN (Reels)
    /// NOTE: we pass onShare function here
    AorisScreen(
      videos: const [],
      onShare: _handleShare,
    ),

    /// Placeholder (Camera or middle button)
    const SizedBox(),

    /// Chat Screen
    const ChatListScreen(currentUserId: ""),

    /// Profile Screen
    const ProfileScreen(
      username: "User",
      userId: "",
    ),
  ];

  /// ===============================
  /// BUILD
  /// ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],

      /// ===============================
      /// BOTTOM NAVIGATION
      /// ===============================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_arrow),
            label: "Aoris",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: "Create",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}