import 'package:flutter/material.dart';
import '../../../core/utils/glass_container.dart';

class AddLinkScreen extends StatefulWidget {
  final Map<String, dynamic>? existingLink;

  const AddLinkScreen({super.key, this.existingLink});

  @override
  State<AddLinkScreen> createState() => _AddLinkScreenState();
}

class _AddLinkScreenState extends State<AddLinkScreen> {
  late final TextEditingController _urlController;
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.existingLink?['url'] ?? '');
    _titleController = TextEditingController(text: widget.existingLink?['title'] ?? '');
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existingLink != null;

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
              style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
            ),
          ),
        ),
        title: Text(
          isEdit ? 'Edit link' : 'Add link',
          style: TextStyle(fontSize: 18, color: theme.textTheme.bodyLarge?.color),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () {
                final url = _urlController.text.trim();
                if (url.isNotEmpty) {
                  Navigator.pop(context, {
                    'url': url,
                    'title': _titleController.text.trim(),
                  });
                }
              },
              child: Text(
                'Done',
                style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
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
              height: 70,
              radius: 25,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'URL',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TextField(
                      controller: _urlController,
                      autofocus: true,
                      keyboardType: TextInputType.url,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'https://...',
                        hintStyle: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GlassContainer(
              height: 70,
              radius: 25,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Title',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TextField(
                      controller: _titleController,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Optional',
                        hintStyle: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isEdit
          ? Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context, {'action': 'remove'}),
                child: const Text(
                  'Remove link',
                  style: TextStyle(color: Colors.red, fontSize: 15),
                ),
              ),
            )
          : null,
    );
  }
}
