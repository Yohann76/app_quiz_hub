enum Language {
  french('fr', 'Français', 'fr_app_content', '🇫🇷'),
  english('en', 'English', 'en_app_content', '🇬🇧'),
  spanish('es', 'Español', 'es_app_content', '🇪🇸');

  const Language(this.code, this.displayName, this.contentFileName, this.flag);

  final String code;
  final String displayName;
  final String contentFileName;
  final String flag;

  static Language fromCode(String code) {
    return Language.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => Language.french, // Langue par défaut
    );
  }

  static Language fromDisplayName(String displayName) {
    return Language.values.firstWhere(
      (lang) => lang.displayName == displayName,
      orElse: () => Language.french,
    );
  }

  @override
  String toString() => displayName;
}
