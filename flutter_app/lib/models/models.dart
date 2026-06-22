// Lightweight data models mapping the matwal-premium Supabase schema
// (the same tables the web staff portal reads). Only the fields the mobile
// app surfaces are typed; everything else stays in [raw] for forward-compat.

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

bool _toBool(dynamic v, {bool fallback = false}) {
  if (v == null) return fallback;
  if (v is bool) return v;
  final s = v.toString().toLowerCase();
  return s == 'true' || s == 't' || s == '1';
}

class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? firstName;
  final String? lastName;
  final String role;
  final String? avatarUrl;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.firstName,
    this.lastName,
    this.role = 'user',
    this.avatarUrl,
  });

  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) return fullName!;
    if (firstName != null && firstName!.trim().isNotEmpty) {
      return '${firstName!} ${lastName ?? ''}'.trim();
    }
    return email.split('@').first;
  }

  String get firstNameOrEmail {
    if (firstName != null && firstName!.trim().isNotEmpty) return firstName!;
    if (fullName != null && fullName!.trim().isNotEmpty) {
      return fullName!.split(' ').first;
    }
    return email.split('@').first;
  }

  bool get isAdmin => role.toLowerCase() == 'admin';

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id: j['id'] as String,
        email: (j['email'] ?? '') as String,
        fullName: j['full_name'] as String?,
        firstName: j['first_name'] as String?,
        lastName: j['last_name'] as String?,
        role: (j['role'] ?? 'user') as String,
        avatarUrl: j['avatar_url'] as String?,
      );
}

class Client {
  final String id;
  final String name;
  final String? clientType; // individual | entity
  final String? status; // prospect | active | inactive | archived
  final String? company;
  final String? industry;
  final double? totalAum;
  final String? complianceStatus;
  final String? updatedAt;
  final Map<String, dynamic> raw;

  Client({
    required this.id,
    required this.name,
    this.clientType,
    this.status,
    this.company,
    this.industry,
    this.totalAum,
    this.complianceStatus,
    this.updatedAt,
    this.raw = const {},
  });

  factory Client.fromJson(Map<String, dynamic> j) => Client(
        id: j['id'].toString(),
        name: (j['name'] ?? j['full_name'] ?? j['display_name'] ?? 'Unnamed')
            .toString(),
        clientType: j['client_type'] as String?,
        status: j['status'] as String?,
        company: j['company'] as String?,
        industry: j['industry'] as String?,
        totalAum: _toDouble(j['total_aum']),
        complianceStatus: j['compliance_status'] as String?,
        updatedAt: j['updated_at'] as String?,
        raw: j,
      );
}

class Deal {
  final String id;
  final String name;
  final String? clientId;
  final String stage;
  final String? status;
  final String? dealType;
  final double? dealValue;
  final double? probability;
  final String? expectedCloseDate;
  final String? ownerId;
  final String? leadConsultant;
  final String? source;
  final bool isActive;
  final String? updatedAt;
  final Map<String, dynamic> raw;

  Deal({
    required this.id,
    required this.name,
    this.clientId,
    this.stage = 'sourcing',
    this.status,
    this.dealType,
    this.dealValue,
    this.probability,
    this.expectedCloseDate,
    this.ownerId,
    this.leadConsultant,
    this.source,
    this.isActive = true,
    this.updatedAt,
    this.raw = const {},
  });

  factory Deal.fromJson(Map<String, dynamic> j) => Deal(
        id: j['id'].toString(),
        name: (j['name'] ?? 'Untitled deal').toString(),
        clientId: j['client_id']?.toString(),
        stage: (j['stage'] ?? 'sourcing').toString(),
        status: j['status'] as String?,
        dealType: j['deal_type'] as String?,
        dealValue: _toDouble(j['deal_value']),
        probability:
            _toDouble(j['probability'] ?? j['probability_percentage']),
        expectedCloseDate: j['expected_close_date'] as String?,
        ownerId: j['owner_id']?.toString(),
        leadConsultant: j['lead_consultant']?.toString(),
        source: j['source'] as String?,
        isActive: _toBool(j['is_active'], fallback: true),
        updatedAt: j['updated_at'] as String?,
        raw: j,
      );
}

class Task {
  final String id;
  final String title;
  final String? status;
  final String? priority;
  final String? dueDate;
  final String? completionDate;
  final String? dealId;
  final String? clientId;
  final String? updatedAt;
  final Map<String, dynamic> raw;

  Task({
    required this.id,
    required this.title,
    this.status,
    this.priority,
    this.dueDate,
    this.completionDate,
    this.dealId,
    this.clientId,
    this.updatedAt,
    this.raw = const {},
  });

  bool get isDone =>
      completionDate != null && completionDate!.isNotEmpty ||
      (status?.toLowerCase() == 'completed' || status?.toLowerCase() == 'done');

  bool get isOverdue {
    if (isDone || dueDate == null) return false;
    final d = DateTime.tryParse(dueDate!);
    return d != null && d.isBefore(DateTime.now());
  }

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'].toString(),
        title: (j['title'] ?? j['text'] ?? 'Untitled task').toString(),
        status: j['status'] as String?,
        priority: j['priority'] as String?,
        dueDate: j['due_date'] as String?,
        completionDate: j['completion_date'] ?? j['done_date'] as String?,
        dealId: j['deal_id']?.toString(),
        clientId: j['client_id']?.toString(),
        updatedAt: j['updated_at'] as String?,
        raw: j,
      );
}

/// Generic row used by the adaptive module list/KPI screens.
class GenericRow {
  final String id;
  final String title;
  final String? subtitle;
  final String? status;
  final double? amount;
  final String? updatedAt;

  GenericRow({
    required this.id,
    required this.title,
    this.subtitle,
    this.status,
    this.amount,
    this.updatedAt,
  });
}
