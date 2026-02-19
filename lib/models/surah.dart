class Surah {
  final int number;
  final String name;
  final String nameLatin;
  final int numberOfAyahs;
  final String place;
  final String translation;
  final String? audioUrl;

  Surah({
    required this.number,
    required this.name,
    required this.nameLatin,
    required this.numberOfAyahs,
    required this.place,
    required this.translation,
    this.audioUrl,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['nomor'],
      name: json['nama'],
      nameLatin: json['nama_latin'],
      numberOfAyahs: json['jumlah_ayat'],
      place: json['tempat_turun'],
      translation: json['arti'],
      audioUrl: json['audio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nomor': number,
      'nama': name,
      'nama_latin': nameLatin,
      'jumlah_ayat': numberOfAyahs,
      'tempat_turun': place,
      'arti': translation,
      'audio': audioUrl,
    };
  }
}
