enum ResumeStatus { draft, processing, ready }

ResumeStatus resumeStatusFromString(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'processing':
    case 'converting':
      return ResumeStatus.processing;
    case 'ready':
    case 'completed':
    case 'done':
      return ResumeStatus.ready;
    default:
      return ResumeStatus.draft;
  }
}

Map<String, dynamic> normalizeResumeJson(Map<String, dynamic> json) {
  final resume = json['resume'];
  if (resume is Map) {
    return Map<String, dynamic>.from(resume);
  }
  final data = json['data'];
  if (data is Map && (data.containsKey('id') || data.containsKey('status'))) {
    return Map<String, dynamic>.from(data);
  }
  return json;
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
    final data = normalizeResumeJson(json);
    return ResumeItem(
      id: (data['id'] ?? data['resume_id'] ?? '').toString(),
      title: (data['title'] ?? 'Untitled').toString(),
      sourceUrl: data['source_url']?.toString() ?? data['sourceUrl']?.toString(),
      fileName: data['file_name']?.toString() ?? data['fileName']?.toString(),
      status: resumeStatusFromString(data['status']?.toString()),
      createdAt: data['created_at']?.toString() ?? data['createdAt']?.toString(),
      updatedAt: data['updated_at']?.toString() ?? data['updatedAt']?.toString(),
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
