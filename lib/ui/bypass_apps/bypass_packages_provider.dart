import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BypassPackagesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    // Load initial state asynchronously
    _loadFromPreferences();
    return [];
  }

  static const String _prefsKey = 'bypass_packages';

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? packages = prefs.getStringList(_prefsKey);
      if (packages != null) {
        // Update state after loading
        state = packages;
      }
    } catch (e) {
      // Handle error silently
      state = [];
    }
  }

  Future<void> setBypassPackages(List<String> packages) async {
    state = packages;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, packages);
  }

  Future<void> addBypassPackage(String packageName) async {
    if (!state.contains(packageName)) {
      final newPackages = List<String>.from(state)..add(packageName);
      await setBypassPackages(newPackages);
    }
  }

  Future<void> removeBypassPackage(String packageName) async {
    if (state.contains(packageName)) {
      final newPackages = List<String>.from(state)..remove(packageName);
      await setBypassPackages(newPackages);
    }
  }
}

final bypassPackagesProvider =
    NotifierProvider<BypassPackagesNotifier, List<String>>(
      BypassPackagesNotifier.new,
    );
