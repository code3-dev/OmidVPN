part of 'home_controller.dart';

mixin HomeHandler {
  void selectServerUsecase(WidgetRef ref) async {
    final ServerInfo? server = await Navigator.push(
      ref.context,
      MaterialPageRoute(builder: (context) => const ServerListScreen()),
    );
    if (server != null) {
      ref.read(_serverInfoNotifier.notifier).setServerInfo(server);
    }
  }

  void connectUsecase(WidgetRef ref, {required ServerInfo? server}) async {
    if (server == null) return;

    // Check and request notification permission on Android
    if (Platform.isAndroid) {
      final openvpnService = await ref.read(openvpnServiceProvider.future);

      // Check if notification permission is granted
      final MethodChannel platform = MethodChannel('vpn_notification');
      bool hasPermission = false;

      try {
        hasPermission =
            await platform.invokeMethod('checkNotificationPermission') as bool;
      } catch (e) {
        // If method is not implemented, assume permission is needed
        hasPermission = false;
      }

      // If no permission, request it
      if (!hasPermission) {
        // Show a dialog to inform the user
        if (ref.context.mounted) {
          final shouldRequest = await showDialog<bool>(
            context: ref.context,
            builder: (context) => const NotificationPermissionDialog(),
          );

          // If user didn't approve or cancelled, don't continue
          if (shouldRequest != true) {
            return;
          }
          
          // Check permission again after dialog
          try {
            hasPermission =
                await platform.invokeMethod('checkNotificationPermission') as bool;
          } catch (e) {
            hasPermission = false;
          }
          
          // If still no permission, return
          if (!hasPermission) {
            return;
          }
        }
      }
    }

    // Get bypass packages
    final bypassPackages = ref.read(bypassPackagesProvider);
    
    // Connect to VPN with bypass packages
    (await ref.read(
      openvpnServiceProvider.future,
    )).connectWithServerInfo(serverInfo: server, bypassPackages: bypassPackages);
  }

  void disconnectUsecase(WidgetRef ref) async {
    (await ref.read(openvpnServiceProvider.future)).disconnect();
  }
}