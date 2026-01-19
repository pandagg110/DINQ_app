String assetPath(String path) {
  final trimmed = path.startsWith('/') ? path.substring(1) : path;
  return 'assets/$trimmed';
}


