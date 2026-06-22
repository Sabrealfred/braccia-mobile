import 'package:intl/intl.dart';

/// Compact currency, e.g. $24M, $121.3M, $1.24B — matches the prototype figures.
String formatCompactCurrency(num? value) {
  final v = value ?? 0;
  final neg = v < 0;
  final a = v.abs();
  String out;
  if (a >= 1e9) {
    out = '\$${_trim(a / 1e9)}B';
  } else if (a >= 1e6) {
    out = '\$${_trim(a / 1e6)}M';
  } else if (a >= 1e3) {
    out = '\$${_trim(a / 1e3)}K';
  } else {
    out = '\$${a.toStringAsFixed(0)}';
  }
  return neg ? '-$out' : out;
}

String _trim(double v) {
  // 1 decimal, drop trailing .0
  final s = v.toStringAsFixed(v >= 100 ? 0 : 1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

String formatCurrencyFull(num? value) {
  final f = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  return f.format(value ?? 0);
}

String formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final d = DateTime.tryParse(iso);
  if (d == null) return '—';
  return DateFormat('MMM d, yyyy').format(d.toLocal());
}

/// Relative time, e.g. "20m ago", "2h ago", "yesterday".
String timeAgo(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final d = DateTime.tryParse(iso);
  if (d == null) return '';
  final diff = DateTime.now().difference(d.toLocal());
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  return formatDate(iso);
}

String initialsOf(String? name) {
  if (name == null || name.trim().isEmpty) return '?';
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length == 1) {
    return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
  }
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

String greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}
