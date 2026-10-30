import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';

typedef DispatchOfferCallback = void Function(Map<String, dynamic> offer);
typedef StatusCallback = void Function(bool isConnected);

class DriverSocketService {
  static final DriverSocketService _instance = DriverSocketService._internal();
  factory DriverSocketService() => _instance;
  DriverSocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _driverId;
  DispatchOfferCallback? _onDispatchOfferCallback;

  bool get isConnected => _isConnected;

  void initialize({
    required String driverId,
    String? token,
    StatusCallback? onStatusChange,
    DispatchOfferCallback? onDispatchOffer,
  }) {
    _driverId = driverId;
    _onDispatchOfferCallback = onDispatchOffer;

    try {
      _socket?.disconnect();
      _socket?.dispose();

      final serverUrl = ApiConstants.baseUrl.replaceAll('/api', '');

      _socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token ?? 'driver-mock-jwt-token-2026'})
            .build(),
      );

      _socket?.onConnect((_) {
        debugPrint('🚚 [DriverSocket] Connected to $serverUrl');
        _isConnected = true;
        onStatusChange?.call(true);

        // Join driver personal dispatch room
        _socket?.emit('order:join', {'driverId': _driverId});
      });

      _socket?.onDisconnect((_) {
        debugPrint('🚚 [DriverSocket] Disconnected');
        _isConnected = false;
        onStatusChange?.call(false);
      });

      _socket?.onConnectError((err) {
        debugPrint('🚚 [DriverSocket] Connection error: $err');
        _isConnected = false;
        onStatusChange?.call(false);
      });

      // Listen for incoming dispatches from dispatcher
      _socket?.on('dispatch:offer', (data) {
        debugPrint('🚚 [DriverSocket] Incoming Dispatch Offer: $data');
        if (data is Map<String, dynamic>) {
          _onDispatchOfferCallback?.call(data);
        }
      });

      _socket?.connect();
    } catch (e) {
      debugPrint('DriverSocket init exception: $e');
    }
  }

  void toggleOnline(bool isOnline) {
    if (_socket != null && _isConnected) {
      _socket?.emit('driver:toggle_online', {
        'isOnline': isOnline,
        'driverId': _driverId,
      });
      debugPrint('🚚 [DriverSocket] Emitted driver:toggle_online ($isOnline)');
    }
  }

  void streamLocation({
    String? orderId,
    required double lon,
    required double lat,
    double heading = 0.0,
    double speedKmh = 0.0,
  }) {
    if (_socket != null && _isConnected) {
      _socket?.emit('driver:location_update', {
        'orderId': orderId,
        'lon': lon,
        'lat': lat,
        'heading': heading,
        'speedKmh': speedKmh,
      });
    }
  }

  void simulateIncomingOffer(Map<String, dynamic> offer) {
    debugPrint('🚚 [DriverSocket] Simulating incoming dispatch offer: ${offer['order_code']}');
    _onDispatchOfferCallback?.call(offer);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
