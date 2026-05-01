import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/glass_container.dart';
import '../logic/edit_profile_controller.dart';
import 'links_screen.dart';

// ================================
// EDIT PROFILE SCREEN
// ================================
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final EditProfileController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(EditProfileController());
  }

  @override
  void dispose() {
    Get.delete<EditProfileController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 6),
                  _buildProfileSection(),
                  const SizedBox(height: 12),
                  _buildFieldsSection(),
                  const SizedBox(height: 14),
                  _buildSaveButton(),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


Widget _buildLinksSection() {
  final theme = Theme.of(context);

  return Obx(() {
    final count = _ctrl.links.length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LinksScreen()),
        ),
        child: GlassContainer(
          height: 70,
          radius: 25,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Links',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        count == 0 ? 'Add links' : '$count ${count == 1 ? 'link' : 'links'}',
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  });
}
  // ================================
  // HEADER
  // ================================
  Widget _buildHeader() {
    final theme = Theme.of(context);

    return Row(
      children: [
        BackButton(color: theme.iconTheme.color),
        const Expanded(
          child: Center(
            child: Text(
              'Edit Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  // ================================
  // PROFILE SECTION (avatar)
  // ================================
  Widget _buildProfileSection() {
    final theme = Theme.of(context);

    return GlassContainer(
      radius: 25,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _ctrl.changeProfileImage,
              child: Obx(() => Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundImage: _ctrl.imageUrl.value.isNotEmpty
                        ? NetworkImage(_ctrl.imageUrl.value)
                        : null,
                  ),
                  if (_ctrl.isUploadingImage.value)
                    const CircularProgressIndicator(),
                  if (_ctrl.imageUrl.value.isEmpty)
                    Icon(Icons.camera_alt, color: theme.iconTheme.color),
                ],
              )),
            ),
            const SizedBox(height: 10),
            Text(
              'Edit photo',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================
  // FIELDS SECTION
  // ================================
  Widget _buildFieldsSection() {
    return Column(
      children: [
        _buildGlassTile('Name', _ctrl.nameController),
        _buildGlassTile('Username', _ctrl.usernameController),
        _buildGlassTile('Bio', _ctrl.bioController),
        _buildLinksSection(),
      ],
    );
  }

  Widget _buildGlassTile(String title, TextEditingController controller) {
    final theme = Theme.of(context);
    final isBio = title == 'Bio';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () => _openFieldEditor(title, controller),
        child: GlassContainer(
          // Bio uses auto height to avoid overflow on long text
          height: isBio ? null : 70,
          radius: 25,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 15,
              vertical: isBio ? 14 : 0,
            ),
            child: Row(
              crossAxisAlignment: isBio ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: isBio ? MainAxisSize.min : MainAxisSize.max,
                    mainAxisAlignment: isBio ? MainAxisAlignment.start : MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        controller.text.isEmpty ? 'Add $title' : controller.text,
                        maxLines: isBio ? 3 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontSize: 14,
                        ),
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

  Future<void> _openFieldEditor(String title, TextEditingController controller) async {
    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _EditFieldScreen(title: title, controller: controller),
      ),
    );

    if (result == true && mounted) setState(() {});
  }

  // ================================
  // SAVE BUTTON
  // ================================
  Widget _buildSaveButton() {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () async {
        final error = await _ctrl.trySaveProfile();
        if (!mounted) return;

        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        } else {
          Navigator.pop(context, true);
        }
      },
      child: Obx(() => GlassContainer(
        height: 60,
        radius: 25,
        child: Center(
          child: _ctrl.isLoading.value
              ? const CircularProgressIndicator()
              : Text(
                  'Save',
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                ),
        ),
      )),
    );
  }
}

// ================================
// FIELD EDITOR SCREEN (PRIVATE)
// ================================
class _EditFieldScreen extends StatelessWidget {
  final String title;
  final TextEditingController controller;

  const _EditFieldScreen({required this.title, required this.controller});

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
        leadingWidth: 100,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 18, color: theme.textTheme.bodyLarge?.color),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () async {
                final error = await ctrl.validateAndCleanField(title);
                if (!context.mounted) return;

                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                  return;
                }

                Navigator.pop(context, true);
              },
              child: Text(
                'Save',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GlassContainer(
              // Auto height for Bio so the counter fits inside
              height: title == 'Bio' ? null : 70,
              radius: 25,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: title == 'Bio' ? 14 : 0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Field label + text input
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: controller,
                          autofocus: true,
                          maxLines: title == 'Bio' ? null : 1,
                          // 200-char hard limit on Bio
                          maxLength: title == 'Bio' ? 200 : null,
                          // Hide the default Flutter counter — we draw our own
                          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: 'Add $title',
                            hintStyle: TextStyle(
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                            ),
                          ),
                          onChanged: (value) {
                            if (title == 'Username') {
                              final clean = ctrl.cleanUsername(value);
                              if (clean != value) {
                                controller.value = TextEditingValue(
                                  text: clean,
                                  selection: TextSelection.collapsed(offset: clean.length),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),

                    // Character counter — Bio only, bottom-right inside the glass box
                    if (title == 'Bio') ...[
                      const SizedBox(height: 6),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: controller,
                        builder: (_, value, __) => Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${value.text.length}/200',
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (title == 'Name')
              const Text(
                'You can change your name every 5 days',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            if (title == 'Username')
              const Text(
                'You can change your username every 10 days',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}