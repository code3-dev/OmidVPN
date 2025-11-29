import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omidvpn/api/api/api.dart';
import 'package:omidvpn/ui/bypass_apps/bypass_packages_provider.dart';

class BypassAppsScreen extends ConsumerStatefulWidget {
  const BypassAppsScreen({super.key});

  @override
  ConsumerState<BypassAppsScreen> createState() => _BypassAppsScreenState();
}

class _BypassAppsScreenState extends ConsumerState<BypassAppsScreen> {
  final MethodChannel _appListChannel = MethodChannel('com.pira.imid/app_list');
  List<Map<String, dynamic>> _allApps = [];
  List<String> _selectedPackages = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
    _loadSelectedPackages();
  }

  Future<void> _loadInstalledApps() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final List<dynamic> apps = await _appListChannel.invokeMethod(
        'getInstalledApps',
      );

      setState(() {
        // Convert dynamic list to List<Map<String, dynamic>>
        _allApps = apps.map<Map<String, dynamic>>((app) {
          // Cast each app item to Map<String, dynamic>
          return {
            'name': app['name'] as String,
            'packageName': app['packageName'] as String,
            'icon': app['icon'] as String,
            'isSystemApp': app['isSystemApp'] as bool,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load apps: $e';
      });
      debugPrint('Error loading apps: $e');
    }
  }

  void _loadSelectedPackages() {
    final selectedPackages = ref.read(bypassPackagesProvider);
    setState(() {
      _selectedPackages = List<String>.from(selectedPackages);
    });
  }

  List<Map<String, dynamic>> get _filteredApps {
    if (_searchQuery.isEmpty) {
      return _allApps;
    }
    return _allApps.where((app) {
      return app['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          app['packageName'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  bool _isAppSelected(String packageName) {
    return _selectedPackages.contains(packageName);
  }

  void _toggleAppSelection(String packageName) {
    setState(() {
      if (_selectedPackages.contains(packageName)) {
        _selectedPackages.remove(packageName);
      } else {
        _selectedPackages.add(packageName);
      }
    });
  }

  void _saveSelectedPackages() async {
    // Save the selected packages
    await ref
        .read(bypassPackagesProvider.notifier)
        .setBypassPackages(_selectedPackages);

    // Show toast message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(langProvider);
    final filteredApps = _filteredApps;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bypass Apps'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveSelectedPackages,
            tooltip: 'Save Selected Apps',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search apps...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
            ),
          ),
          // Loading indicator, error message, or app list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage))
                : filteredApps.isEmpty
                ? Center(child: Text('No apps found'))
                : ListView.builder(
                    itemCount: filteredApps.length,
                    itemBuilder: (context, index) {
                      final app = filteredApps[index];
                      final isSelected = _isAppSelected(app['packageName']);

                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: app['icon'].isNotEmpty
                              ? Image.memory(
                                  base64Decode(app['icon']),
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.contain,
                                )
                              : Icon(Icons.android, size: 48),
                          title: Text(app['name']),
                          subtitle: Text(app['packageName']),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (_) {
                              _toggleAppSelection(app['packageName']);
                            },
                          ),
                          onTap: () {
                            _toggleAppSelection(app['packageName']);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
