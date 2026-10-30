class AuditLogModel {
  final String id;
  final DateTime timestamp;
  final String adminUser;
  final String actionType;
  final String targetEntity;
  final String details;
  final String ipAddress;
  final String securityHash;

  const AuditLogModel({
    required this.id,
    required this.timestamp,
    required this.adminUser,
    required this.actionType,
    required this.targetEntity,
    required this.details,
    required this.ipAddress,
    required this.securityHash,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: (json['id'] ?? 'AUD-000').toString(),
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      adminUser: (json['admin_user'] ?? 'SYSTEM').toString(),
      actionType: (json['action_type'] ?? 'EVENT').toString(),
      targetEntity: (json['target_entity'] ?? '').toString(),
      details: (json['details'] ?? '').toString(),
      ipAddress: (json['ip_address'] ?? '127.0.0.1').toString(),
      securityHash: (json['security_hash'] ?? 'SHA256:00000000000000000000').toString(),
    );
  }
}

