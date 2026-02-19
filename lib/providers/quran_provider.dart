import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../models/ayah.dart';
import '../models/user_target.dart';
import '../models/user_profile.dart';
import '../models/reading_history.dart';
import '../services/quran_api_service.dart';
import '../services/local_storage_service.dart';

class QuranProvider with ChangeNotifier {
  final QuranApiService _apiService = QuranApiService();
  final LocalStorageService _storageService = LocalStorageService();

  List<Surah> _surahs = [];
  bool _isLoading = false;
  Surah? _currentSurah;
  List<Ayah> _currentAyahs = [];
  Map<String, int>? _lastRead;
  UserTarget _userTarget = UserTarget();
  UserProfile _userProfile = UserProfile();
  int _dailyProgress = 0;
  List<ReadingHistory> _history = [];

  List<Surah> get surahs => _surahs;
  bool get isLoading => _isLoading;
  Surah? get currentSurah => _currentSurah;
  List<Ayah> get currentAyahs => _currentAyahs;
  Map<String, int>? get lastRead => _lastRead;
  UserTarget get userTarget => _userTarget;
  UserProfile get userProfile => _userProfile;
  int get dailyProgress => _dailyProgress;
  List<ReadingHistory> get history => _history;

  Future<void> fetchSurahs() async {
    _isLoading = true;
    notifyListeners();
    try {
      _surahs = await _apiService.getSurahList();
    } catch (e) {
      debugPrint("Error fetching surahs: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchJuzDetail(int startSurah, int startAyah, int endSurah, int endAyah) async {
    _isLoading = true;
    notifyListeners();
    try {
      List<Ayah> allAyahs = [];
      Surah? firstSurah;

      for (int i = startSurah; i <= endSurah; i++) {
        final result = await _apiService.getSurahDetail(i);
        final surah = result['surah'] as Surah;
        List<Ayah> ayahs = result['ayahs'] as List<Ayah>;

        if (i == startSurah) {
          firstSurah = surah;
          // Filter start ayah
          ayahs = ayahs.where((a) => a.number >= startAyah).toList();
        }

        if (i == endSurah) {
          // Filter end ayah
          ayahs = ayahs.where((a) => a.number <= endAyah).toList();
        }

        allAyahs.addAll(ayahs);
      }

      _currentSurah = firstSurah; // Just for title, might need adjustment for Juz title
      _currentAyahs = allAyahs;
    } catch (e) {
      debugPrint("Error fetching juz detail: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSurahDetail(int number) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _apiService.getSurahDetail(number);
      _currentSurah = result['surah'];
      _currentAyahs = result['ayahs'];
    } catch (e) {
      debugPrint("Error fetching surah detail: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLastRead() async {
    _lastRead = await _storageService.getLastRead();
    await loadHistory();
    notifyListeners();
  }

  Future<void> saveLastRead(int surah, int ayah) async {
    await _storageService.saveLastRead(surah, ayah);
    _lastRead = {'surah': surah, 'ayah': ayah};
    
    // Add to history
    final surahData = _surahs.firstWhere((s) => s.number == surah, orElse: () => Surah(
      number: surah,
      name: 'Unknown',
      nameLatin: 'Unknown',
      numberOfAyahs: 0,
      place: '',
      translation: '',
    ));
    
    final historyItem = ReadingHistory(
      surahNumber: surah,
      surahName: surahData.nameLatin,
      ayahNumber: ayah,
      readAt: DateTime.now(),
    );
    
    await _storageService.addReadingHistory(historyItem);
    await loadHistory(); // Reload history
    notifyListeners();
  }
  
  Future<void> loadHistory() async {
    _history = await _storageService.getReadingHistory();
    notifyListeners();
  }
  
  Future<void> clearHistory() async {
    await _storageService.clearReadingHistory();
    _history = [];
    notifyListeners();
  }

  Future<void> loadUserTarget() async {
    final target = await _storageService.getUserTarget();
    if (target != null) {
      _userTarget = target;
    }
    await loadUserProfile();
    _dailyProgress = await _storageService.getDailyProgress();
    notifyListeners();
  }

  Future<void> updateUserTarget(UserTarget target) async {
    await _storageService.saveUserTarget(target);
    _userTarget = target;
    notifyListeners();
  }

  Future<void> loadUserProfile() async {
    final profile = await _storageService.getUserProfile();
    if (profile != null) {
      _userProfile = profile;
    }
    notifyListeners();
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    await _storageService.saveUserProfile(profile);
    _userProfile = profile;
    notifyListeners();
  }

  Future<void> incrementDailyProgress() async {
    await _storageService.incrementDailyProgress();
    _dailyProgress = await _storageService.getDailyProgress();
    notifyListeners();
  }
}
