// lib/services/algorithm_service.dart

class AlgorithmService {

  // =========================
  // 🧠 Calculate Post Score
  // =========================
  static double calculateScore(Map post) {
    final int likes = post['likes'] ?? 0;
    final int comments = post['comments'] ?? 0;
    final int shares = post['shares'] ?? 0;

    double score =
        (likes * 3) +
        (comments * 5) +
        (shares * 8);

    // 🆕 Freshness boost
    final createdAt = DateTime.tryParse(post['created_at'] ?? '');
    if (createdAt != null) {
      final hours = DateTime.now().difference(createdAt).inHours;
      score += (24 - hours).clamp(0, 24); // boost for new posts
    }

    return score;
  }

  // =========================
  // 📊 Sort Posts
  // =========================
  static List sortPosts(List posts) {
    posts.sort((a, b) {
      final scoreA = calculateScore(a);
      final scoreB = calculateScore(b);

      return scoreB.compareTo(scoreA);
    });

    return posts;
  }
}