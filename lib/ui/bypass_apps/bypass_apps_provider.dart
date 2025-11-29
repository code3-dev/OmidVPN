import 'package:flutter_riverpod/flutter_riverpod.dart';

class BypassApp {
  final String name;
  final String packageName;
  final String icon; // base64 encoded icon
  final bool isSystemApp;

  BypassApp({
    required this.name,
    required this.packageName,
    required this.icon,
    required this.isSystemApp,
  });
}

class BypassAppsState {
  final List<BypassApp> allApps;
  final List<String> selectedAppPackages;
  final bool isLoading;
  final String searchQuery;

  BypassAppsState({
    required this.allApps,
    required this.selectedAppPackages,
    required this.isLoading,
    required this.searchQuery,
  });

  BypassAppsState copyWith({
    List<BypassApp>? allApps,
    List<String>? selectedAppPackages,
    bool? isLoading,
    String? searchQuery,
  }) {
    return BypassAppsState(
      allApps: allApps ?? this.allApps,
      selectedAppPackages: selectedAppPackages ?? this.selectedAppPackages,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<BypassApp> get filteredApps {
    if (searchQuery.isEmpty) {
      return allApps;
    }
    return allApps.where((app) {
      return app.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          app.packageName.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }
}

class BypassAppsNotifier extends StateNotifier<BypassAppsState> {
  BypassAppsNotifier()
    : super(
        BypassAppsState(
          allApps: [],
          selectedAppPackages: [],
          isLoading: false,
          searchQuery: '',
        ),
      );

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleAppSelection(String packageName) {
    final isSelected = state.selectedAppPackages.contains(packageName);
    final newSelectedPackages = List<String>.from(state.selectedAppPackages);

    if (isSelected) {
      newSelectedPackages.remove(packageName);
    } else {
      newSelectedPackages.add(packageName);
    }

    state = state.copyWith(selectedAppPackages: newSelectedPackages);
  }

  void setSelectedApps(List<String> packageNames) {
    state = state.copyWith(selectedAppPackages: packageNames);
  }
}

final bypassAppsProvider =
    StateNotifierProvider<BypassAppsNotifier, BypassAppsState>(
      (ref) => BypassAppsNotifier(),
    );
