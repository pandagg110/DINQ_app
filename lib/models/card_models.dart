class CardItem {
  CardItem({
    required this.id,
    required this.data,
    required this.layout,
  });

  final String id;
  final CardData data;
  final CardLayout layout;

  factory CardItem.fromJson(Map<String, dynamic> json) {
    return CardItem(
      id: json['id']?.toString() ?? '',
      data: CardData.fromJson(Map<String, dynamic>.from(json['data'] ?? {})),
      layout: CardLayout.fromJson(Map<String, dynamic>.from(json['layout'] ?? {})),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': data.toJson(),
        'layout': layout.toJson(),
      };
}

class CardData {
  CardData({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.metadata,
    required this.status,
  });

  final String id;
  final String type;
  final String title;
  final String description;
  final Map<String, dynamic> metadata;
  final String status;

  factory CardData.fromJson(Map<String, dynamic> json) {
    return CardData(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      status: json['status']?.toString() ?? 'COMPLETED',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'description': description,
        'metadata': metadata,
        'status': status,
      };
}

class CardLayout {
  CardLayout({required this.desktop, required this.mobile});

  final CardLayoutState desktop;
  final CardLayoutState mobile;

  factory CardLayout.fromJson(Map<String, dynamic> json) {
    return CardLayout(
      desktop: CardLayoutState.fromJson(Map<String, dynamic>.from(json['desktop'] ?? {})),
      mobile: CardLayoutState.fromJson(Map<String, dynamic>.from(json['mobile'] ?? {})),
    );
  }

  Map<String, dynamic> toJson() => {
        'desktop': desktop.toJson(),
        'mobile': mobile.toJson(),
      };
}

class CardLayoutState {
  CardLayoutState({required this.size, required this.position});

  String size;
  CardPosition position;

  factory CardLayoutState.fromJson(Map<String, dynamic> json) {
    return CardLayoutState(
      size: json['size']?.toString() ?? '2x2',
      position: CardPosition.fromJson(Map<String, dynamic>.from(json['position'] ?? {})),
    );
  }

  Map<String, dynamic> toJson() => {
        'size': size,
        'position': position.toJson(),
      };
}

class CardPosition {
  CardPosition({required this.x, required this.y, required this.w, required this.h});

  int x;
  int y;
  int w;
  int h;

  factory CardPosition.fromJson(Map<String, dynamic> json) {
    return CardPosition(
      x: json['x'] is int ? json['x'] as int : int.tryParse(json['x']?.toString() ?? '0') ?? 0,
      y: json['y'] is int ? json['y'] as int : int.tryParse(json['y']?.toString() ?? '0') ?? 0,
      w: json['w'] is int ? json['w'] as int : int.tryParse(json['w']?.toString() ?? '1') ?? 1,
      h: json['h'] is int ? json['h'] as int : int.tryParse(json['h']?.toString() ?? '1') ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'w': w,
        'h': h,
      };
}

enum ViewMode { desktop, mobile }

class CardState {
  CardState({
    this.loading = false,
    this.isUploading = false,
    this.isNew = false,
  });

  bool loading;
  bool isUploading;
  bool isNew;
}


