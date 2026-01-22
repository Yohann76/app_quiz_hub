import '../models/language.dart';

/// Modèle représentant le profil utilisateur
class UserProfile {
  final String id;
  final String? email;
  final String? username;
  final Language? language;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    this.email,
    this.username,
    this.language,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Vérifier si le profil est complet (a un username et une langue)
  bool get isComplete => username != null && username!.isNotEmpty && language != null;

  /// Créer un UserProfile depuis un Map (depuis Supabase)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String?,
      username: json['username'] as String?,
      language: json['language'] != null 
          ? Language.fromCode(json['language'] as String)
          : null,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convertir en Map pour Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (email != null) 'email': email,
      if (username != null) 'username': username,
      if (language != null) 'language': language!.code,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Créer une copie avec des valeurs modifiées
  UserProfile copyWith({
    String? id,
    String? email,
    String? username,
    Language? language,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      language: language ?? this.language,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

