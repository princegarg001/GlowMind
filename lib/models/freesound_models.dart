/// Data models for Freesound API responses
library;

/// Represents a sound from Freesound API
class FreesoundSound {
  final int id;
  final String name;
  final String url;
  final String? previewUrl;
  final String? previewUrlLq;
  final double duration;
  final String username;
  final String license;
  final List<String> tags;
  final String? description;
  final double? rating;
  final int? numRatings;
  final String attribution;

  const FreesoundSound({
    required this.id,
    required this.name,
    required this.url,
    this.previewUrl,
    this.previewUrlLq,
    required this.duration,
    required this.username,
    required this.license,
    this.tags = const [],
    this.description,
    this.rating,
    this.numRatings,
    required this.attribution,
  });

  factory FreesoundSound.fromJson(Map<String, dynamic> json) {
    return FreesoundSound(
      id: json['id'] as int,
      name: json['name'] as String,
      url: json['url'] as String,
      previewUrl: json['previewUrl'] as String?,
      previewUrlLq: json['previewUrlLq'] as String?,
      duration: (json['duration'] as num).toDouble(),
      username: json['username'] as String,
      license: json['license'] as String,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      description: json['description'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      numRatings: json['numRatings'] as int?,
      attribution: json['attribution'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'previewUrl': previewUrl,
    'previewUrlLq': previewUrlLq,
    'duration': duration,
    'username': username,
    'license': license,
    'tags': tags,
    'description': description,
    'rating': rating,
    'numRatings': numRatings,
    'attribution': attribution,
  };

  /// Get the best available preview URL
  String? get bestPreviewUrl => previewUrl ?? previewUrlLq;

  /// Check if this sound requires attribution (non-CC0)
  bool get requiresAttribution => !license.toLowerCase().contains('cc0');
}

/// Response from Freesound search API
class FreesoundSearchResponse {
  final int count;
  final int page;
  final int pageSize;
  final bool hasNext;
  final bool hasPrevious;
  final List<FreesoundSound> results;

  const FreesoundSearchResponse({
    required this.count,
    required this.page,
    required this.pageSize,
    required this.hasNext,
    required this.hasPrevious,
    required this.results,
  });

  factory FreesoundSearchResponse.fromJson(Map<String, dynamic> json) {
    return FreesoundSearchResponse(
      count: json['count'] as int,
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      hasNext: json['hasNext'] as bool,
      hasPrevious: json['hasPrevious'] as bool,
      results: (json['results'] as List<dynamic>)
          .map((e) => FreesoundSound.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Check if there are more pages available
  int get totalPages => (count / pageSize).ceil();
}

/// Sound detail with additional info
class FreesoundSoundDetail extends FreesoundSound {
  final String? downloadUrl;
  final Map<String, dynamic>? images;

  const FreesoundSoundDetail({
    required super.id,
    required super.name,
    required super.url,
    super.previewUrl,
    super.previewUrlLq,
    required super.duration,
    required super.username,
    required super.license,
    super.tags,
    super.description,
    super.rating,
    super.numRatings,
    required super.attribution,
    this.downloadUrl,
    this.images,
  });

  factory FreesoundSoundDetail.fromJson(Map<String, dynamic> json) {
    return FreesoundSoundDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      url: json['url'] as String,
      previewUrl: json['previewUrl'] as String?,
      previewUrlLq: json['previewUrlLq'] as String?,
      duration: (json['duration'] as num).toDouble(),
      username: json['username'] as String,
      license: json['license'] as String,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      description: json['description'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      numRatings: json['numRatings'] as int?,
      attribution: json['attribution'] as String,
      downloadUrl: json['downloadUrl'] as String?,
      images: json['images'] as Map<String, dynamic>?,
    );
  }
}

/// Download URL response
class FreesoundDownloadInfo {
  final int id;
  final String name;
  final String? previewHq;
  final String? previewLq;
  final String? streamUrl;

  const FreesoundDownloadInfo({
    required this.id,
    required this.name,
    this.previewHq,
    this.previewLq,
    this.streamUrl,
  });

  factory FreesoundDownloadInfo.fromJson(Map<String, dynamic> json) {
    return FreesoundDownloadInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      previewHq: json['previewHq'] as String?,
      previewLq: json['previewLq'] as String?,
      streamUrl: json['streamUrl'] as String?,
    );
  }

  /// Get the best available stream URL
  String? get bestStreamUrl => streamUrl ?? previewHq ?? previewLq;
}
