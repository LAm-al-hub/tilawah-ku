class Ayah {
  final int id;
  final int surahId;
  final int number;
  final String textArabic;
  final String textLatin;
  final String textIndonesian;
  final String? audioUrl;
  bool isLastRead;

  Ayah({
    required this.id,
    required this.surahId,
    required this.number,
    required this.textArabic,
    required this.textLatin,
    required this.textIndonesian,
    this.audioUrl,
    this.isLastRead = false,
  });

  factory Ayah.fromJson(Map<String, dynamic> json, int surahId) {
    return Ayah(
      id: json['nomor'], // Using ayah number as ID relative to surah, or unique ID if available
      surahId: surahId,
      number: json['nomor'],
      textArabic: json['ar'],
      textLatin: json['tr'],
      textIndonesian: json['idn'], // Correct key for Indonesian translation
      audioUrl: null, // API v2 structure might vary, adjusting as needed
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nomor': number,
      'surahId': surahId,
      'ar': textArabic,
      'tr': textLatin,
      'id': textIndonesian,
      'isLastRead': isLastRead ? 1 : 0,
    };
  }
}
