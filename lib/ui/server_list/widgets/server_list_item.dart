import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omidvpn/api/api/api.dart';
import 'package:omidvpn/api/domain/entity/server_info.dart';

class ServerListItem extends ConsumerWidget {
  final ServerInfo server;
  final void Function()? onSelect;

  const ServerListItem({super.key, required this.server, this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);

    // Convert country code to lowercase for asset path
    final countryCode = server.countryShort.toLowerCase();
    final flagAssetPath = 'assets/CountryFlags/$countryCode.png';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: SizedBox(
          width: 60,
          height: 45,
          child: Image.asset(
            flagAssetPath,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Text(
                  server.countryShort,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
            fit: BoxFit.contain,
          ),
        ),
        title: Text(
          server.hostName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, size: 16),
                const SizedBox(width: 4),
                Text('${server.numVpnSessions} ${lang.sessions}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text('${server.uptime} ${lang.days}'),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            server.countryShort,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: onSelect,
      ),
    );
  }
}