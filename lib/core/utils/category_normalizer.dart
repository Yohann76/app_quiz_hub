/// Utilitaire pour normaliser les noms de catégories entre les langues
/// Toutes les catégories sont normalisées vers les noms français
/// 
/// Les 7 catégories officielles :
/// - Histoire
/// - Géographie
/// - Cinéma
/// - Musique
/// - Sports
/// - Sciences
/// - Divers
class CategoryNormalizer {
  // Mapping exhaustif pour accepter les catégories dans les 3 langues
  static const Map<String, String> _categoryMapping = {
    // Français
    'histoire': 'histoire',
    'geographie': 'geographie',
    'cinema': 'cinema',
    'cinéma': 'cinema',
    'musique': 'musique',
    'sports': 'sports',
    'sport': 'sports',
    'sciences': 'sciences',
    'science': 'sciences',
    'divers': 'divers',
    
    // Anglais
    'history': 'histoire',
    'geography': 'geographie',
    'film': 'cinema',
    'movies': 'cinema',
    'music': 'musique',
    'misc': 'divers',
    'miscellaneous': 'divers',
    'other': 'divers',
    
    // Espagnol
    'historia': 'histoire',
    'geografia': 'geographie',
    'cine': 'cinema',
    'peliculas': 'cinema',
    'musica': 'musique',
    'deportes': 'sports',
    'deporte': 'sports',
    'ciencias': 'sciences',
    'ciencia': 'sciences',
    'otros': 'divers',
    'otro': 'divers',
    'diverso': 'divers',

    // Compatibilité
    'general': 'divers',
    'art': 'cinema',
    'arte': 'cinema',
    'mathematiques': 'sciences',
    'mathematics': 'sciences',
    'matematicas': 'sciences',
  };

  /// Normalise une catégorie vers son équivalent français
  static String normalize(String category) {
    if (category.isEmpty) return 'divers';
    final normalized = _categoryMapping[category.toLowerCase()];
    if (normalized == null) {
      // En mode debug on pourrait logger ici, mais on replie sur 'divers'
      return 'divers';
    }
    return normalized;
  }

  /// Retourne le nom d'affichage français d'une catégorie normalisée
  static String getDisplayName(String normalizedCategory) {
    const displayNames = {
      'histoire': 'Histoire',
      'geographie': 'Géographie',
      'cinema': 'Cinéma',
      'musique': 'Musique',
      'sports': 'Sports',
      'sciences': 'Sciences',
      'divers': 'Divers',
      'unknown': 'Inconnu',
    };
    return displayNames[normalizedCategory.toLowerCase()] ?? normalizedCategory;
  }

  /// Retourne toutes les catégories normalisées disponibles (dans l'ordre défini)
  static List<String> getAllNormalizedCategories() {
    return ['histoire', 'geographie', 'cinema', 'musique', 'sports', 'sciences', 'divers'];
  }
}
