import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omidvpn/api/api/api.dart';
import 'package:omidvpn/api/domain/entity/server_info.dart';
import 'package:omidvpn/api/domain/entity/vpn_stage.dart';
import 'package:omidvpn/api/domain/repository/vpn_service.dart';
import 'package:omidvpn/ui/bypass_apps/bypass_packages_provider.dart';
import 'package:omidvpn/ui/server_list/server_list_screen.dart';
import 'package:omidvpn/ui/shared/widgets/notification_permission_dialog.dart';

part 'home_state.dart';
part 'home_handler.dart';
part 'server_info_async_notifier.dart';