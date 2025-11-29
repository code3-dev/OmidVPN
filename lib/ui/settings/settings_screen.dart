import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omidvpn/api/api/api.dart';
import 'package:omidvpn/ui/about/about_screen.dart';
import 'package:omidvpn/ui/bypass_apps/bypass_apps_screen.dart';
import 'package:omidvpn/ui/privacy/privacy_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io' show exit;
import 'package:omidvpn/api/lang/lang.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // Show theme selection bottom sheet
  void _showThemeSelectionSheet(BuildContext context, WidgetRef ref) {
    final lang = ref.read(langProvider);
    final themeMode = ref.read(themeModeProvider);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ThemeSelectionSheet(currentTheme: themeMode, lang: lang);
      },
    );
  }

  // Show exit confirmation dialog
  Future<void> _showExitConfirmationDialog(BuildContext context, Lang lang) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(lang.areYouSureYouWantToContinue),
          content: Text(lang.yourCurrentSessionWillBeTerminated),
          actions: <Widget>[
            TextButton(
              child: Text(lang.no),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
            ),
            TextButton(
              child: Text(lang.yes),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                exit(0); // Exit the app
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.settings),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(lang.theme),
              subtitle: Text(_getThemeModeText(themeMode, lang)),
              leading: Icon(Icons.color_lens),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showThemeSelectionSheet(context, ref);
              },
            ),
            Divider(),
            ListTile(
              title: Text('Bypass Apps'),
              subtitle: Text('Select apps to exclude from VPN'),
              leading: Icon(Icons.apps),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BypassAppsScreen(),
                  ),
                );
                
                if (result != null && result is List<String>) {
                  // Handle the selected bypass packages
                  // This would typically be stored in shared preferences or passed to the VPN connection
                  debugPrint('Selected bypass packages: $result');
                }
              },
            ),
            ListTile(
              title: Text(lang.privacyPolicy),
              leading: Icon(Icons.privacy_tip),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyScreen()),
                );
              },
            ),
            ListTile(
              title: Text(lang.about),
              leading: Icon(Icons.info_outline),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListTile(
                    title: Text('${lang.appVersion}: ${snapshot.data!.version}'),
                    subtitle: Text(snapshot.data!.packageName),
                  );
                } else {
                  return ListTile(
                    title: Text(lang.appVersion),
                    subtitle: Text('Loading...'),
                  );
                }
              },
            ),
            Divider(),
            ListTile(
              title: Text(
                lang.exitApp,
                style: TextStyle(color: Colors.red),
              ),
              leading: Icon(
                Icons.exit_to_app,
                color: Colors.red,
              ),
              onTap: () {
                _showExitConfirmationDialog(context, lang);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  String _getThemeModeText(ThemeMode themeMode, Lang lang) {
    switch (themeMode) {
      case ThemeMode.light:
        return lang.lightTheme;
      case ThemeMode.dark:
        return lang.darkTheme;
      default:
        return lang.systemTheme;
    }
  }
}

class ThemeSelectionSheet extends ConsumerWidget {
  final ThemeMode currentTheme;
  final Lang lang;

  const ThemeSelectionSheet({
    super.key,
    required this.currentTheme,
    required this.lang,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.only(top: 10, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang.theme,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text(lang.systemTheme),
                  value: ThemeMode.system,
                  groupValue: currentTheme,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      ref.read(themeModeProvider.notifier).setThemeMode(value);
                      Navigator.pop(context);
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: Text(lang.lightTheme),
                  value: ThemeMode.light,
                  groupValue: currentTheme,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      ref.read(themeModeProvider.notifier).setThemeMode(value);
                      Navigator.pop(context);
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: Text(lang.darkTheme),
                  value: ThemeMode.dark,
                  groupValue: currentTheme,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      ref.read(themeModeProvider.notifier).setThemeMode(value);
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}