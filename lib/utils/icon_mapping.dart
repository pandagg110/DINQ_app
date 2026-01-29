/// Maps SVG icon names to PNG file names in assets/icons/logo
/// Converts social-icons SVG paths to logo PNG paths
String mapSvgToPng(String svgPath) {
  // Extract the SVG filename from the path
  final svgName = svgPath.split('/').last.replaceAll('.svg', '');
  
  // Mapping from SVG name to PNG filename (matching the renamed files)
  final Map<String, String> mapping = {
    'Github': 'Github',
    'LinkedIn': 'LinkedIn',
    'GoogleScholar': 'GoogleScholar',
    'Scholar': 'GoogleScholar',
    'Facebook': 'Facebook',
    'Behance': 'Behance',
    'Dribbble': 'Dribbble',
    'Instagram': 'Instagram',
    'OpenReview': 'OpenReview',
    'Reddit': 'Reddit',
    'Spotify': 'Spotify',
    'Telegram': 'Telegram',
    'Tiktok': 'Tiktok',
    'Twitter': 'Twitter',
    'Youtube': 'Youtube',
    'WeChat': 'WeChat',
    'Netease': 'Netease',
    'Bilibili': 'Bilibili',
    'Snapchat': 'Snapchat',
    'Vimeo': 'Vimeo',
    'Discord': 'Discord',
  };
  
  // Get the PNG filename (default to original name if not in mapping)
  final pngName = mapping[svgName] ?? svgName;
  
  // Return the path to logo PNG
  return 'icons/logo/$pngName.png';
}

