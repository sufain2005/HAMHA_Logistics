import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';

enum AdminScope {
  fullAdmin,
  dispatcher,
  support,
}

enum AdminPermission {
  viewFleet,
  manualDispatch,
  approveDrivers,
  viewFinancialLedgers,
  resolveDisputes,
  viewAnalytics,
  manageAdmins,
}

class AdminUserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? companyName;
  final String? gstNumber;
  final String? govtIdType;
  final String? govtIdNumber;
  final int vehiclesCount;
  final String role; // strictly 'admin'
  final AdminScope scope;
  final String? avatar;
  final String token;
  final bool isMfaVerified;
  final DateTime lastLogin;

  const AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.companyName,
    this.gstNumber,
    this.govtIdType,
    this.govtIdNumber,
    this.vehiclesCount = 0,
    required this.role,
    required this.scope,
    this.avatar,
    required this.token,
    this.isMfaVerified = true,
    required this.lastLogin,
  });

  bool hasPermission(AdminPermission permission) {
    switch (scope) {
      case AdminScope.fullAdmin:
        return true; // Fleet Owner possesses unrestricted permissions
      case AdminScope.dispatcher:
        return [
          AdminPermission.viewFleet,
          AdminPermission.manualDispatch,
          AdminPermission.viewAnalytics,
        ].contains(permission);
      case AdminScope.support:
        return [
          AdminPermission.approveDrivers,
          AdminPermission.resolveDisputes,
          AdminPermission.viewFleet,
        ].contains(permission);
    }
  }

  String get scopeTitle {
    switch (scope) {
      case AdminScope.fullAdmin:
        return 'OWNER';
      case AdminScope.dispatcher:
        return 'FLEET DISPATCHER';
      case AdminScope.support:
        return 'OPERATIONS & COMPLIANCE';
    }
  }

  Color get scopeColor {
    switch (scope) {
      case AdminScope.fullAdmin:
        return AdminTheme.crimsonRed;
      case AdminScope.dispatcher:
        return const Color(0xFF2563EB); // Royal Blue
      case AdminScope.support:
        return AdminTheme.statusOnline; // Emerald Green
    }
  }

  factory AdminUserModel.fromJson(Map<String, dynamic> json, {String? token, AdminScope? overrideScope}) {
    final roleStr = (json['role'] ?? 'admin').toString().toLowerCase();
    
    // Strict RBAC gate: verify user has 'admin' role
    if (roleStr != 'admin') {
      throw Exception("Access Denied: Account role is '$roleStr'. Only registered 'admin' / Fleet Owner accounts are authorized for the Owner Panel.");
    }

    AdminScope parsedScope = overrideScope ?? AdminScope.fullAdmin;

    return AdminUserModel(
      id: json['id'] ?? 'adm-root-01',
      name: json['name'] ?? 'Fleet Owner',
      email: json['email'] ?? 'owner@hamha.com',
      phone: json['phone'],
      companyName: json['company_name'] ?? json['companyName'],
      gstNumber: json['gst_number'] ?? json['gstNumber'],
      govtIdType: json['govt_id_type'] ?? json['govtIdType'],
      govtIdNumber: json['govt_id_number'] ?? json['govtIdNumber'],
      vehiclesCount: json['vehiclesCount'] ?? json['vehicles_count'] ?? 0,
      role: 'admin',
      scope: parsedScope,
      avatar: json['avatar'],
      token: token ?? json['token'] ?? 'mock-admin-jwt-2026',
      isMfaVerified: json['is_mfa_verified'] ?? true,
      lastLogin: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'company_name': companyName,
    'gst_number': gstNumber,
    'govt_id_type': govtIdType,
    'govt_id_number': govtIdNumber,
    'vehicles_count': vehiclesCount,
    'role': role,
    'scope': scope.name,
    'token': token,
    'is_mfa_verified': isMfaVerified,
    'last_login': lastLogin.toIso8601String(),
  };
}

