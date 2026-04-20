import 'package:flutter/material.dart';
import '../../../core/utils/glass_container.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text(
          "Account",
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: theme.iconTheme.color,
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GlassContainer(
          height: 120,
          radius: 20,
          child: Column(
            children: [

              ListTile(
                title: Text(
                  "Account Info",
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),

              Divider(
                color: theme.dividerColor,
              ),

              ListTile(
                title: Text(
                  "Change Password",
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}