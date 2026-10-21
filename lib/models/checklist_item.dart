class ChecklistItem {
  final String id;
  String text;
  bool isDone;
  String? time; // Format waktu, misal "08:00" atau "14:30"

  ChecklistItem({
    required this.id,
    required this.text,
    this.isDone = false,
    this.time,
  });

  bool get hasTime => time != null && time!.trim().isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isDone': isDone,
      if (time != null && time!.trim().isNotEmpty) 'time': time,
    };
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      text: json['text'] as String? ?? '',
      isDone: json['isDone'] as bool? ?? false,
      time: json['time'] as String?,
    );
  }

  ChecklistItem copyWith({
    String? id,
    String? text,
    bool? isDone,
    String? time,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
      time: time ?? this.time,
    );
  }
}
