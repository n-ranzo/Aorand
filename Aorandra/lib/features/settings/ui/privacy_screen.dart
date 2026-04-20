import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// WIDGETS
import 'package:aorandra/core/utils/glass_container.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {

  final supabase = Supabase.instance.client;

  bool isPrivate = false;
  bool showLiked = true;
  bool showSaved = true;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    final data = await supabase
        .from("users")
        .select()
        .eq("id", user.id)
        .single();

    setState(() {
      isPrivate = data["isPrivate"] ?? false;
      showLiked = data["showLikedVideos"] ?? true;
      showSaved = data["showSavedVideos"] ?? true;
      isLoading = false;
    });
  }

  Future<void> _update(String key, bool value) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from("users")
        .update({key: value})
        .eq("id", user.id);
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text(
          "Privacy",
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: theme.iconTheme.color,
        ),
      ),

      body: Container(
        /// 🔥 حذفنا gradient
        color: theme.scaffoldBackgroundColor,

        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: theme.textTheme.bodyLarge?.color,
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [

                  /// 🔒 PRIVATE ACCOUNT
                  _sectionTitle(context, "Account"),
                  const SizedBox(height: 8),

                  _sectionContainer(children: [
                    _switchTile(
                      context: context,
                      title: "Private Account",
                      subtitle: "Only followers can see your content",
                      value: isPrivate,
                      onChanged: (val) {
                        setState(() => isPrivate = val);
                        _update("isPrivate", val);
                      },
                    ),
                  ]),

                  const SizedBox(height: 20),

                  /// 👀 CONTENT VISIBILITY
                  _sectionTitle(context, "Content"),
                  const SizedBox(height: 8),

                  _sectionContainer(children: [
                    _switchTile(
                      context: context,
                      title: "Show Liked Videos",
                      subtitle: "Others can see your likes",
                      value: showLiked,
                      onChanged: (val) {
                        setState(() => showLiked = val);
                        _update("showLikedVideos", val);
                      },
                    ),
                    _divider(context),
                    _switchTile(
                      context: context,
                      title: "Show Saved Videos",
                      subtitle: "Others can see your saved",
                      value: showSaved,
                      onChanged: (val) {
                        setState(() => showSaved = val);
                        _update("showSavedVideos", val);
                      },
                    ),
                  ]),
                ],
              ),
      ),
    );
  }

  // ================= SWITCH TILE =================
  Widget _switchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final theme = Theme.of(context);

    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.redAccent,
      title: Text(
        title,
        style: TextStyle(
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: theme.textTheme.bodyMedium?.color,
          fontSize: 12,
        ),
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
      child: Column(children: children),
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