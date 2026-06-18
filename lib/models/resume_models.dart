enum ResumeStatus { draft, processing, ready }

ResumeStatus resumeStatusFromString(String? raw) {
  switch (raw) {
    case 'processing':
      return ResumeStatus.processing;
    case 'ready':
      return ResumeStatus.ready;
    default:
      return ResumeStatus.draft;
  }
}

String resumeStatusLabel(ResumeStatus status) {
  switch (status) {
    case ResumeStatus.draft:
      return 'Draft';
    case ResumeStatus.processing:
      return 'Processing';
    case ResumeStatus.ready:
      return 'Ready';
  }
}

class ResumeItem {
  const ResumeItem({
    required this.id,
    required this.title,
    this.sourceUrl,
    this.fileName,
    this.status = ResumeStatus.draft,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String? sourceUrl;
  final String? fileName;
  final ResumeStatus status;
  final String? createdAt;
  final String? updatedAt;

  factory ResumeItem.fromJson(Map<String, dynamic> json) {
    return ResumeItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Untitled').toString(),
      sourceUrl: json['source_url']?.toString(),
      fileName: json['file_name']?.toString(),
      status: resumeStatusFromString(json['status']?.toString()),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  ResumeItem copyWith({
    String? title,
    String? sourceUrl,
    String? fileName,
    ResumeStatus? status,
    String? updatedAt,
  }) {
    return ResumeItem(
      id: id,
      title: title ?? this.title,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
