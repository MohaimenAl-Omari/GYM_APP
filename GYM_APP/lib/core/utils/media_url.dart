import '../constant/const.dart';

/// Resolves a value stored in a `media`/`gif_url`-style database column
/// into a URL an [Image]/[CachedNetworkImage] widget can load directly.
///
/// Exercise media can come from two places: a file uploaded to this app's
/// own server (stored as a path relative to Laravel's `public` disk, e.g.
/// `exercises/bench-press.gif`) or a URL pasted straight from an already-
/// licensed external source (e.g. a CDN). The two need different handling
/// — a relative path must be prefixed with [storageBaseUrl], but an
/// absolute URL must be used exactly as-is, or the two get concatenated
/// into garbage like `http://host/storage/https://cdn.example.com/...`.
///
/// Shared by [Exercise] and [HistoryExercise] instead of each duplicating
/// the same absolute-vs-relative check.
String? resolveMediaUrl(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  return '$storageBaseUrl/$raw';
}
