import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/quote_model.dart';
import '../models/order_model.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _authToken;
  UserModel? currentUser;

  void setToken(String token) {
    _authToken = token;
  }

  void clearToken() {
    _authToken = null;
    currentUser = null;
  }

  bool get isAuthenticated => _authToken != null;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // ==========================================
  // AUTHENTICATION FLOWS (CUSTOMER)
  // ==========================================

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': 'customer',
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (data['token'] != null) setToken(data['token']);
      if (data['user'] != null) currentUser = UserModel.fromJson(data['user']);
      return data;
    } else {
      throw Exception(data['message'] ?? 'Registration failed.');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'expectedRole': 'customer',
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (data['token'] != null) setToken(data['token']);
      if (data['user'] != null) currentUser = UserModel.fromJson(data['user']);
      return data;
    } else {
      throw Exception(data['message'] ?? 'Login failed.');
    }
  }

  Future<void> verifyOtp({required String phone, required String otpCode}) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'otpCode': otpCode}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (currentUser != null) {
        currentUser = UserModel(
          id: currentUser!.id,
          name: currentUser!.name,
          email: currentUser!.email,
          phone: currentUser!.phone,
          role: currentUser!.role,
          isVerified: true,
        );
      }
    } else {
      throw Exception(data['message'] ?? 'OTP verification failed.');
    }
  }

  // ==========================================
  // SHIPMENT & COST CALCULATOR FLOWS
  // ==========================================

  Future<QuoteModel> calculateQuote({
    required double weightKg,
    required double pickupLon,
    required double pickupLat,
    required double dropoffLon,
    required double dropoffLat,
    String cargoType = 'Standard Package',
  }) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/customer/calculate-quote'),
      headers: _headers,
      body: jsonEncode({
        'weightKg': weightKg,
        'pickupLon': pickupLon,
        'pickupLat': pickupLat,
        'dropoffLon': dropoffLon,
        'dropoffLat': dropoffLat,
        'cargoType': cargoType,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return QuoteModel.fromJson(data['quote']);
    } else {
      throw Exception(data['message'] ?? 'Failed to compute shipment quote.');
    }
  }

  Future<Map<String, dynamic>> createOrder({
    required String cargoType,
    required double weightKg,
    String? packageDescription,
    required String pickupAddress,
    required double pickupLon,
    required double pickupLat,
    required String dropoffAddress,
    required double dropoffLon,
    required double dropoffLat,
    String? dropoffContactName,
    String? dropoffContactPhone,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/customer/orders'),
      headers: _headers,
      body: jsonEncode({
        'cargoType': cargoType,
        'weightKg': weightKg,
        'packageDescription': packageDescription,
        'pickupAddress': pickupAddress,
        'pickupLon': pickupLon,
        'pickupLat': pickupLat,
        'dropoffAddress': dropoffAddress,
        'dropoffLon': dropoffLon,
        'dropoffLat': dropoffLat,
        'dropoffContactName': dropoffContactName,
        'dropoffContactPhone': dropoffContactPhone,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to create shipment.');
    }
  }

  Future<List<OrderModel>> getMyOrders() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/customer/orders'),
      headers: _headers,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['orders'] != null) {
      final list = data['orders'] as List;
      return list.map((item) => OrderModel.fromJson(item)).toList();
    } else {
      throw Exception(data['message'] ?? 'Failed to load orders.');
    }
  }

  Future<OrderModel> getOrderTracking(String orderId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/customer/orders/$orderId/track'),
      headers: _headers,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['order'] != null) {
      return OrderModel.fromJson(data['order']);
    } else {
      throw Exception(data['message'] ?? 'Failed to load tracking data.');
    }
  }

  Future<Map<String, dynamic>> getOrderInvoice(String orderId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/customer/orders/$orderId/invoice'),
      headers: _headers,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['invoice'] != null) {
      return data['invoice'];
    } else {
      throw Exception(data['message'] ?? 'Failed to retrieve invoice.');
    }
  }
}

