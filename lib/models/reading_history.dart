class ReadingHistory {
  final int? id;
  final int surahNumber;
  final String surahName;
  final int ayahNumber;
  final DateTime readAt;

  ReadingHistory({
    this.id,
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
    required this.readAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'surah_number': surahNumber,
      'surah_name': surahName,
      'ayah_number': ayahNumber,
      'read_at': readAt.toIso8601String(),
    };
  }

  factory ReadingHistory.fromMap(Map<String, dynamic> map) {
    return ReadingHistory(
      id: map['id'],
      surahNumber: map['surah_number'],
      surahName: map['surah_name'],
      ayahNumber: map['ayah_number'],
      readAt: DateTime.parse(map['read_at']),
    );
  }
}
