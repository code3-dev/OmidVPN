import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omidvpn/ui/server_list/controller/server_list_controller.dart';
import 'package:omidvpn/ui/server_list/providers/selected_country_provider.dart';

class CountrySelectorWidget extends ConsumerWidget {
  const CountrySelectorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverList = ref.watch(serverListAsyncNotifier);
    final selectedCountry = ref.watch(selectedCountryProvider);

    return serverList.when(
      data: (servers) {
        final countryMap = <String, String>{};
        for (final server in servers) {
          if (server.countryShort.isNotEmpty && server.countryLong.isNotEmpty) {
            countryMap[server.countryShort] = server.countryLong;
          }
        }

        final sortedCountries = countryMap.keys.toList()..sort();

        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sortedCountries.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return FilterChip(
                  label: const Text('All Countries'),
                  selected: selectedCountry == null,
                  onSelected: (_) {
                    ref
                        .read(serverListAsyncNotifier.notifier)
                        .filterByCountry(null);
                  },
                );
              }
              final countryShort = sortedCountries[index - 1];
              final countryLong = countryMap[countryShort] ?? countryShort;
              return FilterChip(
                label: Text(countryLong),
                selected:
                    selectedCountry?.toLowerCase() == countryShort.toLowerCase(),
                onSelected: (_) {
                  ref
                      .read(serverListAsyncNotifier.notifier)
                      .filterByCountry(countryShort);
                },
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }
}