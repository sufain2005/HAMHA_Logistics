import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/admin_constants.dart';
import '../services/admin_auth_service.dart';

class AdminSocketService {
  static final AdminSocketService _instance = AdminSocketService._internal();
  factory AdminSocketService() => _instance;
  AdminSocketService._internal();

  io.Socket? _socket;
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);
  final ValueNotifier<int> livePacketCount = ValueNotifier<int>(0);

  // Callbacks for live fleet events
  Function(Map<String, dynamic>)? onDriverLocation;
  Function(Map<String, dynamic>)? onDriverStatus;
  Function(Map<String, dynamic>)? onOrderUpdate;

  void connect() {
    if (_socket != null && _socket!.connected) return;

    final token = AdminAuthService().currentAdmin?.token;

    try {
      _socket = io.io(
        AdminConstants.socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .setAuth({'token': token, 'role': 'admin'})
            .setQuery({'role': 'admin'})
            .enableReconnection()
            .setReconnectionDelay(2000)
            .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('👑 [Admin Socket] Connected to Central Command Server (${AdminConstants.socketUrl})');
        isConnected.value = true;
        // Explicitly join admin:fleet room
        _socket!.emit('admin:join', {'role': 'admin'});
        _socket!.emit('fleet:join', {'channel': 'admin:fleet'});
      });

      _socket!.onDisconnect((_) {
        debugPrint('🔌 [Admin Socket] Disconnected from Command Server');
        isConnected.value = false;
      });

      _socket!.onConnectError((err) {
        debugPrint('⚠️ [Admin Socket] Connection Error: $err');
        isConnected.value = false;
      });

      // Real-time GPS location telemetry from drivers
      _socket!.on('fleet:driver_location', (data) {
        if (data is Map<String, dynamic>) {
          livePacketCount.value++;
          onDriverLocation?.call(data);
        } else if (data is Map) {
          livePacketCount.value++;
          onDriverLocation?.call(Map<String, dynamic>.from(data));
        }
      });

      // Online / Offline driver status changes
      _socket!.on('fleet:driver_status', (data) {
        if (data is Map) {
          onDriverStatus?.call(Map<String, dynamic>.from(data));
        }
      });

      // Driver status change from driver controller
      _socket!.on('driver:status_changed', (data) {
        if (data is Map) {
          onDriverStatus?.call(Map<String, dynamic>.from(data));
        }
      });

      // Order created / updated
      _socket!.on('order:created', (data) {
        if (data is Map) onOrderUpdate?.call(Map<String, dynamic>.from(data));
      });
      _socket!.on('order:updated', (data) {
        if (data is Map) onOrderUpdate?.call(Map<String, dynamic>.from(data));
      });
      _socket!.on('order:status_changed', (data) {
        if (data is Map) onOrderUpdate?.call(Map<String, dynamic>.from(data));
      });

      _socket!.connect();
    } catch (e) {
      debugPrint('❌ [Admin Socket] Initialization Exception: $e');
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    isConnected.value = false;
  }
}

