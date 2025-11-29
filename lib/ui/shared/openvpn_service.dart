import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:omidvpn/api/domain/entity/server_info.dart';
import 'package:omidvpn/api/domain/entity/vpn_stage.dart';
import 'package:omidvpn/api/domain/repository/vpn_service.dart';
import 'package:omidvpn/ui/shared/one_day_cache.dart';

class OpenvpnService implements VpnService {
  OpenVPN openvpn = OpenVPN();
  VpnStage _vpnStage = VpnService.defaultVpnStage;
  bool configCipherFix;
  String? _serverName;
  ServerInfo? _cachedServerInfo;
  final String serverNameCacheKey;
  final String serverInfoCacheKey;
  final StreamController<VpnStage> stageSC =
      StreamController<VpnStage>.broadcast();
  late MethodChannel _platform;

  final OneDayFileCacheManager cacheManager;

  @override
  Stream<VpnStage> get stageStream => stageSC.stream;

  @override
  VpnStage get vpnstage => _vpnStage;

  @override
  String? get serverName => _serverName;

  ServerInfo? get cachedServerInfo => _cachedServerInfo;

  OpenvpnService({
    required this.cacheManager,
    required this.configCipherFix,
    required this.serverNameCacheKey,
    required this.serverInfoCacheKey,
  }) {
    if (Platform.isAndroid) {
      _platform = MethodChannel('vpn_notification');
      _platform.setMethodCallHandler(_handleMethod);
    }
  }

  Future<void> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'disconnectVpn':
        disconnect();
        break;
      default:
        throw MissingPluginException('Not implemented');
    }
  }

  Future<void> ensureInitialized() async {
    if (openvpn.initialized) {
      return;
    }

    openvpn = OpenVPN(
      onVpnStatusChanged: _onVpnStatusChanged,
      onVpnStageChanged: _onVpnStageChanged,
    );

    await openvpn.initialize(localizedDescription: 'OmidVPN');

    _vpnStage = _VPNstageToDomain(await openvpn.stage());
    stageSC.add(_vpnStage);

    // Initialize cached server info if connection is still established
    if (_vpnStage != VpnStage.disconnected) {
      _serverName = await cacheManager.read(key: serverNameCacheKey);
      // Try to load full server info from cache
      await _loadCachedServerInfo();

      // Start notification service if we're on Android and connected
      if (Platform.isAndroid && _serverName != null) {
        _startNotificationService(_serverName!);
      }
    }
  }

  Future<void> _loadCachedServerInfo() async {
    try {
      final cachedServerInfoJson = await cacheManager.read(
        key: serverInfoCacheKey,
      );
      if (cachedServerInfoJson != null && cachedServerInfoJson.isNotEmpty) {
        final serverInfoMap = jsonDecode(cachedServerInfoJson);
        _cachedServerInfo = ServerInfo(
          hostName: serverInfoMap['hostName'],
          ip: serverInfoMap['ip'],
          score: serverInfoMap['score'],
          ping: serverInfoMap['ping'],
          speed: serverInfoMap['speed'],
          countryShort: serverInfoMap['countryShort'],
          countryLong: serverInfoMap['countryLong'],
          numVpnSessions: serverInfoMap['numVpnSessions'],
          uptime: serverInfoMap['uptime'],
          totalUsers: serverInfoMap['totalUsers'],
          totalTraffic: serverInfoMap['totalTraffic'],
          logType: serverInfoMap['logType'],
          operator: serverInfoMap['operator'],
          message: serverInfoMap['message'],
          vpnConfig: serverInfoMap['vpnConfig'],
        );
      }
    } catch (e) {
      debugPrint('Error loading cached server info: $e');
    }
  }

  // Start the Android notification service
  Future<void> _startNotificationService(String serverName) async {
    if (!Platform.isAndroid) return;

    try {
      await _platform.invokeMethod('startNotificationService', {
        'serverName': serverName,
      });
    } catch (e) {
      debugPrint('Error starting notification service: $e');
    }
  }

  // Stop the Android notification service
  Future<void> _stopNotificationService() async {
    if (!Platform.isAndroid) return;

    try {
      await _platform.invokeMethod('stopNotificationService');
    } catch (e) {
      debugPrint('Error stopping notification service: $e');
    }
  }

  void _onVpnStatusChanged(VpnStatus? vpnStatus) {}

  void _onVpnStageChanged(VPNStage stage, String rawStage) {
    debugPrint('DEBUG: $rawStage');
    _vpnStage = _VPNstageToDomain(stage);
    stageSC.add(_vpnStage);

    // Handle notification service based on VPN state
    if (Platform.isAndroid) {
      if (_vpnStage == VpnStage.connected && _serverName != null) {
        _startNotificationService(_serverName!);
      } else if (_vpnStage == VpnStage.disconnected) {
        _stopNotificationService();
      }
    }
  }

  // ignore: non_constant_identifier_names
  VpnStage _VPNstageToDomain(VPNStage stage) {
    return VpnStage.values.byName(stage.name);
  }

  String _configPatches(String ovpnConfig) {
    if (configCipherFix) {
      final result = ovpnConfig.replaceAll(RegExp(r'cipher '), 'data-ciphers ');
      return result;
    }
    return ovpnConfig;
  }

  @override
  void connect({required String serverName, required String config, List<String>? bypassPackages}) {
    openvpn.connect(
      _configPatches(config),
      serverName,
      // username: username,
      // password: password,
      bypassPackages: bypassPackages ?? [],
      certIsRequired: true,
    );

    _serverName = serverName;
    cacheManager.save(key: serverNameCacheKey, content: serverName);
  }

  // Connect with full server info
  void connectWithServerInfo({required ServerInfo serverInfo, List<String>? bypassPackages}) {
    openvpn.connect(
      _configPatches(serverInfo.vpnConfig),
      serverInfo.hostName,
      // username: username,
      // password: password,
      bypassPackages: bypassPackages ?? [],
      certIsRequired: true,
    );

    _serverName = serverInfo.hostName;
    _cachedServerInfo = serverInfo;
    cacheManager.save(key: serverNameCacheKey, content: serverInfo.hostName);

    // Save the full server info as JSON
    final serverInfoJson = {
      'hostName': serverInfo.hostName,
      'ip': serverInfo.ip,
      'score': serverInfo.score,
      'ping': serverInfo.ping,
      'speed': serverInfo.speed,
      'countryShort': serverInfo.countryShort,
      'countryLong': serverInfo.countryLong,
      'numVpnSessions': serverInfo.numVpnSessions,
      'uptime': serverInfo.uptime,
      'totalUsers': serverInfo.totalUsers,
      'totalTraffic': serverInfo.totalTraffic,
      'logType': serverInfo.logType,
      'operator': serverInfo.operator,
      'message': serverInfo.message,
      'vpnConfig': serverInfo.vpnConfig,
    };

    cacheManager.save(
      key: serverInfoCacheKey,
      content: jsonEncode(serverInfoJson),
    );

    // Start notification service on Android
    if (Platform.isAndroid) {
      _startNotificationService(serverInfo.hostName);
    }
  }

  @override
  void disconnect() {
    switch (_vpnStage) {
      case VpnStage.disconnected:
      case VpnStage.disconnecting:
        return;
      default:
        _serverName = null;
        _cachedServerInfo = null;
        openvpn.disconnect();

        // Stop notification service on Android
        if (Platform.isAndroid) {
          _stopNotificationService();
        }
    }
  }
}