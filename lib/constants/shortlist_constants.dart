import 'package:flutter/material.dart';

/// 对齐 Web `constants/favorite.ts`。
const List<String> favoriteStatuses = [
  'not_obtained',
  'email_obtained',
  'contacted',
];

class FavoriteStatusColors {
  const FavoriteStatusColors({
    required this.bg,
    required this.text,
    required this.dot,
  });

  final Color bg;
  final Color text;
  final Color dot;
}

const Map<String, FavoriteStatusColors> favoriteStatusColors = {
  'not_obtained': FavoriteStatusColors(
    bg: Color(0xFFF3F1EC),
    text: Color(0xFF8A8880),
    dot: Color(0xFFB5B3AE),
  ),
  'email_obtained': FavoriteStatusColors(
    bg: Color(0xFFEDEAE0),
    text: Color(0xFF6B6962),
    dot: Color(0xFFA5A097),
  ),
  'contacted': FavoriteStatusColors(
    bg: Color(0xFFE8EFE5),
    text: Color(0xFF4A6A4A),
    dot: Color(0xFF6E9A6E),
  ),
};

const Map<String, String> _legacyStatusMap = {
  'not_contacted': 'not_obtained',
  'email_sent': 'email_obtained',
  'interested': 'contacted',
  'not_interested': 'not_obtained',
  'interviewing': 'contacted',
  'closed': 'contacted',
};

String normalizeFavoriteStatus(String? status) {
  if (status == null || status.isEmpty) return 'not_obtained';
  if (favoriteStatusColors.containsKey(status)) return status;
  return _legacyStatusMap[status] ?? 'not_obtained';
}

const int shortlistPageSize = 20;
const int shortlistExportPageSize = 200;
const int shortlistMaxPdfExportRows = 200;
const int shortlistNewThresholdMs = 24 * 60 * 60 * 1000;

int getShortlistProjectLimit(String? plan) {
  final base = (plan ?? 'free').replaceAll(RegExp(r'_monthly|_yearly'), '');
  if (base == 'free') return 1;
  if (base == 'basic') return 5;
  return -1;
}

bool isShortlistProjectLimitReached(int projectCount, String? plan) {
  final limit = getShortlistProjectLimit(plan);
  return limit > 0 && projectCount >= limit;
}
