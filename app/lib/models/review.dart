class Review {
  final int id;
  final int storeId;
  final int userId;
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  final String? username;
  final String? profilePic;
  final String? pseudoname;

  Review({
    required this.id,
    required this.storeId,
    required this.userId,
    required this.rating,
    this.comment,
    this.createdAt,
    this.username,
    this.profilePic,
    this.pseudoname,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int? ?? 0,
      storeId: json['store_id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      username: json['username'] as String?,
      profilePic: json['profile_pic'] as String?,
      pseudoname: json['pseudoname'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
    };
  }

  String get displayName => pseudoname ?? username ?? 'Anonymous';
}
