import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BypassPackagesNotifier extends Notifier<Future<List<String>>> {
  @override
  Future<List<String>> build() async {
    // Load initial state asynchronously
    state = _loadFromPreferences();
    return await state;
  }

  static const String _prefsKey = 'bypass_packages';

  Future<List<String>> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? packages = prefs.getStringList(_prefsKey);
      if (packages != null) {
        return packages;
      }
      return [];
    } catch (e) {
      // Handle error silently
      return [];
    }
  }

  Future<void> setBypassPackages(List<String> packages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, packages);
    state = Future.value(packages);
  }

  Future<void> addBypassPackage(String packageName) async {
    final currentPackages = await state;
    if (!currentPackages.contains(packageName)) {
      final newPackages = List<String>.from(currentPackages)..add(packageName);
      await setBypassPackages(newPackages);
    }
  }

  Future<void> removeBypassPackage(String packageName) async {
    final currentPackages = await state;
    if (currentPackages.contains(packageName)) {
      final newPackages = List<String>.from(currentPackages)..remove(packageName);
      await setBypassPackages(newPackages);
    }
  }
}

final bypassPackagesProvider =
    NotifierProvider<BypassPackagesNotifier, Future<List<String>>>(
      BypassPackagesNotifier.new,
    );