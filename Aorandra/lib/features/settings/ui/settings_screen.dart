import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// WIDGETS
import 'package:aorandra/core/utils/glass_container.dart';

// AUTH
import 'package:aorandra/features/auth/ui/login_screen.dart';

// SCREENS
import 'account_screen.dart';
import 'privacy_screen.dart';
import 'appearance_screen.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: theme.iconTheme.color,
        ),
      ),

      body: Container(
        color: theme.scaffoldBackgroundColor,

        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          children: [

            /// ================= TOP CARDS =================
            Row(
              children: [
                Expanded(
                  child: _topCard(
                    context,
                    "Account",
                    Icons.person,
                    const AccountScreen(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _topCard(
                    context,
                    "Privacy",
                    Icons.lock,
                    const PrivacyScreen(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// ================= APPEARANCE =================
            _sectionTitle(context, "Appearance"),
            const SizedBox(height: 8),
            _sectionContainer(children: [
              _tile(
                context,
                title: "Theme",
                icon: Icons.color_lens,
                screen: const AppearanceScreen(),
              ),
            ]),

            const SizedBox(height: 20),

            /// ================= APP =================
            _sectionTitle(context, "App"),
            const SizedBox(height: 8),
            _sectionContainer(children: [
              _tile(
                context,
                title: "Notifications",
                icon: Icons.notifications,
                onTap: () {},
              ),
              _divider(context),
              _tile(
                context,
                title: "Language",
                icon: Icons.language,
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 20),

            /// ================= LOGOUT =================
            _sectionContainer(children: [
              _tile(
                context,
                title: "Logout",
                icon: Icons.logout,
                isDanger: true,
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ================= TOP CARD =================
  Widget _topCard(
    BuildContext context,
    String title,
    IconData icon,
    Widget screen,
  ) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
      child: GlassContainer(
        height: 110,
        radius: 22,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.iconTheme.color, size: 30),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TILE =================
  Widget _tile(
    BuildContext context, {
    required String title,
    required IconData icon,
    Widget? screen,
    VoidCallback? onTap,
    bool isDanger = false,
  }) {
    final theme = Theme.of(context);

    final color = isDanger
        ? Colors.red
        : theme.textTheme.bodyLarge?.color;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      onTap: onTap ??
          () {
            if (screen != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => screen),
              );
            }
          },
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: theme.textTheme.bodyMedium?.color,
      ),
    );
  }

  // ================= SECTION TITLE =================
  Widget _sectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Text(
      title,
      style: TextStyle(
        color: theme.textTheme.bodyMedium?.color,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ================= CONTAINER =================
  Widget _sectionContainer({required List<Widget> children}) {
    return GlassContainer(
      radius: 20,
      child: Column(
        children: children,
      ),
    );
  }

  // ================= DIVIDER =================
  Widget _divider(BuildContext context) {
    final theme = Theme.of(context);

    return Divider(
      height: 1,
      thickness: 0.5,
      color: theme.dividerColor,
      indent: 14,
      endIndent: 14,
    );
  }
}