import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/glass_container.dart';
import '../logic/edit_profile_controller.dart';
import 'add_links_screen.dart';

class LinksScreen extends StatelessWidget {
  const LinksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ctrl = Get.find<EditProfileController>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: theme.iconTheme.color),
        title: Text(
          'Links',
          style: TextStyle(fontSize: 18, color: theme.textTheme.bodyLarge?.color),
        ),
      ),
      body: Obx(() => ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _AddLinkTile(ctrl: ctrl),
          ...ctrl.links.asMap().entries.map(
            (e) => _LinkTile(ctrl: ctrl, index: e.key, link: e.value),
          ),
        ],
      )),
    );
  }
}

// ─── Add link row ─────────────────────────────────────────────────────────────

class _AddLinkTile extends StatelessWidget {
  final EditProfileController ctrl;

  const _AddLinkTile({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(builder: (_) => const AddLinkScreen()),
          );
          if (result != null) ctrl.links.add(result);
        },
        child: GlassContainer(
          height: 65,
          radius: 25,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                _CircleIcon(
                  theme: theme,
                  child: Icon(
                    Icons.add,
                    size: 20,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Add link',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Existing link row ────────────────────────────────────────────────────────

class _LinkTile extends StatelessWidget {
  final EditProfileController ctrl;
  final int index;
  final Map<String, dynamic> link;

  const _LinkTile({required this.ctrl, required this.index, required this.link});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = (link['title'] as String?)?.isNotEmpty == true ? link['title'] as String : null;
    final url = link['url'] as String;
    final displayUrl = url.replaceFirst(RegExp(r'^https?://'), '');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(builder: (_) => AddLinkScreen(existingLink: link)),
          );
          if (result == null) return;
          if (result['action'] == 'remove') {
            ctrl.links.removeAt(index);
          } else {
            ctrl.links[index] = result;
          }
        },
        child: GlassContainer(
          height: 65,
          radius: 25,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                _CircleIcon(
                  theme: theme,
                  opacity: 0.3,
                  child: Icon(Icons.link, size: 18, color: theme.textTheme.bodyLarge?.color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        displayUrl,
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared circle icon container ─────────────────────────────────────────────

class _CircleIcon extends StatelessWidget {
  final Widget child;
  final ThemeData theme;
  final double opacity;

  const _CircleIcon({required this.child, required this.theme, this.opacity = 0.5});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.textTheme.bodyLarge?.color?.withValues(alpha: opacity) ?? Colors.white54,
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}
