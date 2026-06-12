import 'package:flutter/material.dart';

class LocalEvent {
  int? id;
  String title;
  String description;
  String date;
  String time;
  String location;
  String category;
  bool isFavorite;

  LocalEvent({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.category,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'location': location,
      'category': category,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory LocalEvent.fromMap(Map<String, dynamic> map) {
    return LocalEvent(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      date: map['date'] as String,
      time: map['time'] as String,
      location: map['location'] as String,
      category: map['category'] as String,
      isFavorite: (map['isFavorite'] ?? 0) == 1,
    );
  }

  LocalEvent copyWith({
    int? id,
    String? title,
    String? description,
    String? date,
    String? time,
    String? location,
    String? category,
    bool? isFavorite,
  }) {
    return LocalEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

// ── Category metadata: icon + accent color ──────────────────────────────────
class CategoryMeta {
  final IconData icon;
  final Color color;
  const CategoryMeta(this.icon, this.color);
}

const Map<String, CategoryMeta> kCategoryMeta = {
  'Concert': CategoryMeta(Icons.music_note_rounded, Color(0xFF8B5CF6)),
  'Sports': CategoryMeta(Icons.sports_soccer_rounded, Color(0xFF10B981)),
  'Festival': CategoryMeta(Icons.celebration_rounded, Color(0xFFF59E0B)),
  'Conference': CategoryMeta(Icons.business_center_rounded, Color(0xFF3B82F6)),
  'Exhibition': CategoryMeta(Icons.palette_rounded, Color(0xFFEF4444)),
};

CategoryMeta categoryMeta(String cat) =>
    kCategoryMeta[cat] ??
    const CategoryMeta(Icons.event_rounded, Color(0xFFD4AF37));
