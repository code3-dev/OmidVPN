import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omidvpn/api/api/api.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  // Function to launch URLs
  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);

    return Scaffold(
      appBar: AppBar(title: Text('About')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App logo
            Image.asset(
              'assets/icon.png',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.account_circle,
                  size: 100,
                  color: Colors.blue,
                );
              },
            ),
            SizedBox(height: 20),

            // App name
            Text(
              lang.homeTitle,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Developer info
            Text('Developed by Hossein Pira', style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),

            // Contact info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Information:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    ListTile(
                      leading: Icon(Icons.telegram),
                      title: Text('Telegram'),
                      subtitle: Text('h3dev'),
                      onTap: () {
                        // Open Telegram profile
                        _launchUrl('https://t.me/h3dev');
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.email),
                      title: Text('Email'),
                      subtitle: Text('h3dev.pira@gmail.com'),
                      onTap: () {
                        // Open email client
                        _launchUrl('mailto:h3dev.pira@gmail.com');
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.camera_alt),
                      title: Text('Instagram'),
                      subtitle: Text('h3dev.pira'),
                      onTap: () {
                        // Open Instagram profile
                        _launchUrl('https://instagram.com/h3dev.pira');
                      },
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Description
            Text(
              'A simple openVPN client for public VPN servers that allows users to connect to VPN services easily.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),

            Spacer(),

            // Copyright
            Text(
              '© ${DateTime.now().year} Hossein Pira. All rights reserved.',
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
