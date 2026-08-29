import 'dart:io';

/// Safe media helpers for Android paths that contain dots in package names.
String safeMediaExtension(String path, {required bool isVideo}) {
  final name = path.split(RegExp(r'[\\/]')).last;
  final i = name.lastIndexOf('.');
  if (i > 0 && i < name.length - 1) {
    final ext = name.substring(i).toLowerCase();
    const video = {'.mp4', '.mov', '.m4v', '.webm', '.3gp'};
    const image = {'.jpg', '.jpeg', '.png', '.webp', '.heic', '.heif'};
    if (isVideo && video.contains(ext)) return ext == '.mov' ? '.mp4' : ext;
    if (!isVideo && image.contains(ext)) return ext == '.jpeg' ? '.jpg' : ext;
  }
  return isVideo ? '.mp4' : '.jpg';
}

String contentTypeForExtension(String ext, {required bool isVideo}) {
  switch (ext) {
    case '.mp4':
    case '.m4v':
    case '.mov':
      return 'video/mp4';
    case '.webm':
      return 'video/webm';
    case '.3gp':
      return 'video/3gpp';
    case '.png':
      return 'image/png';
    case '.webp':
      return 'image/webp';
    case '.jpg':
    default:
      return isVideo ? 'video/mp4' : 'image/jpeg';
  }
}

bool isPlayableVideoUrl(String url) {
  final lower = url.toLowerCase();
  return lower.contains('.mp4') ||
      lower.contains('.mov') ||
      lower.contains('.m4v') ||
      lower.contains('.webm') ||
      lower.contains('.3gp');
}

Future<File> ensureLocalPlayableFile(File file, {required bool isVideo}) async {
  final ext = safeMediaExtension(file.path, isVideo: isVideo);
  if (file.path.toLowerCase().endsWith(ext)) return file;

  final dir = Directory.systemTemp;
  final target = File(
    '${dir.path}/feed_${DateTime.now().millisecondsSinceEpoch}$ext',
  );
  return file.copy(target.path);
}
