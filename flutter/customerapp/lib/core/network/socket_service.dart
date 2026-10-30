import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/app_constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final _driverLocationController = StreamController<Map<String, dynamic>>.broadcast();
  final _orderStatusController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get driverLocationStream => _driverLocationController.stream;
  Stream<Map<String, dynamic>> get orderStatusStream => _orderStatusController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String token) {
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(
      AppConstants.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      print('🟢 [SocketService] Customer connected to HAMHA Real-time Dispatch');
    });

    _socket!.on('order:driver_location', (data) {
      if (data != null && data is Map) {
        _driverLocationController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('order:status_changed', (data) {
      if (data != null && data is Map) {
        _orderStatusController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('order:assigned', (data) {
      if (data != null && data is Map) {
        _orderStatusController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.onDisconnect((_) {
      print('🔴 [SocketService] Disconnected from server');
    });
  }

  void joinOrderRoom(String orderId) {
    if (_socket == null) return;
    _socket!.emit('order:join', {'orderId': orderId});
    print('📍 Joined order room: order:$orderId');
  }

  void leaveOrderRoom(String orderId) {
    if (_socket == null) return;
    _socket!.emit('order:leave', {'orderId': orderId});
    print('🚪 Left order room: order:$orderId');
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _driverLocationController.close();
    _orderStatusController.close();
  }
}

