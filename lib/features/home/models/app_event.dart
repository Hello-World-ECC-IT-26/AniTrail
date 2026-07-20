class AppEvent {
  const AppEvent({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    this.summary,
    this.content,
    this.bannerUrl,
  });

  final String id;
  final String title;
  final String? summary;
  final String? content;
  final String? bannerUrl;
  final DateTime startsAt;
  final DateTime endsAt;

  factory AppEvent.fromJson(Map<String, dynamic> json) {
    return AppEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String?,
      content: json['content'] as String?,
      bannerUrl: json['banner_url'] as String?,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
    );
  }
}

String formatEventPeriod(AppEvent event) {
  String date(DateTime value) {
    final local = value.toLocal();
    return '${local.year}年${local.month}月${local.day}日';
  }

  return '${date(event.startsAt)} 〜 ${date(event.endsAt)}';
}
