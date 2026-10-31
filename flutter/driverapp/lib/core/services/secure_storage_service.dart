import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyJwtToken = 'hamha_driver_jwt_token';
  static const String _keyDriverId = 'hamha_driver_id';
  static const String _keyDriverName = 'hamha_driver_name';
  static const String _keyDriverPhone = 'hamha_driver_phone';
  static const String _keyVehicleType = 'hamha_driver_vehicle_type';
  static const String _keyVehiclePlate = 'hamha_driver_vehicle_plate';
  static const String _keyIsOnboarded = 'hamha_driver_is_onboarded';

  Future<void> saveSession({
    required String token,
    required String driverId,
    required String name,
    required String phone,
  }) async {
    await _storage.write(key: _keyJwtToken, value: token);
    await _storage.write(key: _keyDriverId, value: driverId);
    await _storage.write(key: _keyDriverName, value: name);
    await _storage.write(key: _keyDriverPhone, value: phone);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyJwtToken);
  }

  Future<String?> getDriverId() async {
    return await _storage.read(key: _keyDriverId);
  }

  Future<String?> getDriverName() async {
    return await _storage.read(key: _keyDriverName);
  }

  Future<String?> getDriverPhone() async {
    return await _storage.read(key: _keyDriverPhone);
  }

  Future<void> saveVehicleDetails({
    required String vehicleType,
    required String plateNumber,
  }) async {
    await _storage.write(key: _keyVehicleType, value: vehicleType);
    await _storage.write(key: _keyVehiclePlate, value: plateNumber);
    await _storage.write(key: _keyIsOnboarded, value: 'true');
  }

  Future<String?> getVehicleType() async {
    return await _storage.read(key: _keyVehicleType);
  }

  Future<String?> getVehiclePlate() async {
    return await _storage.read(key: _keyVehiclePlate);
  }

  Future<bool> isOnboarded() async {
    final val = await _storage.read(key: _keyIsOnboarded);
    return val == 'true';
  }

  Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}
