import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/imsakiyah_service.dart';
import '../services/notification_service.dart';
import '../utils/theme.dart';
import 'package:tilawah_ku/l10n/gen/app_localizations.dart';

class ImsakiyahScreen extends StatefulWidget {
  const ImsakiyahScreen({super.key});

  @override
  State<ImsakiyahScreen> createState() => _ImsakiyahScreenState();
}

class _ImsakiyahScreenState extends State<ImsakiyahScreen> {
  final ImsakiyahService _service = ImsakiyahService();
  final NotificationService _notificationService = NotificationService();

  List<String> _provinces = [];
  List<String> _cities = [];
  Map<String, dynamic>? _scheduleData;
  bool _isLoading = false;
  String? _selectedProvince;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
    _loadSavedLocation();
    _notificationService.init();
  }

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final savedProvince = prefs.getString('selected_province');
    final savedCity = prefs.getString('selected_city');

    if (savedProvince != null) {
      setState(() {
        _selectedProvince = savedProvince;
      });
      await _loadCities(savedProvince);
      if (savedCity != null && _cities.contains(savedCity)) {
        setState(() {
          _selectedCity = savedCity;
        });
        _loadSchedule();
      }
    }
  }

  Future<void> _saveLocation() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedProvince != null) {
      await prefs.setString('selected_province', _selectedProvince!);
    }
    if (_selectedCity != null) {
      await prefs.setString('selected_city', _selectedCity!);
    }
  }

  Future<void> _loadProvinces() async {
    setState(() => _isLoading = true);
    try {
      final provinces = await _service.getProvinces();
      setState(() {
        _provinces = provinces;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.failedToLoadSurahs}: $e')), // Reusing generic fail string or specific if available
        );
      }
    }
  }

  Future<void> _loadCities(String province) async {
    setState(() => _isLoading = true);
    try {
      final cities = await _service.getCities(province);
      setState(() {
        _cities = cities;
        _selectedCity = null; // Reset city selection
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.failedToLoadSurahs}: $e')),
        );
      }
    }
  }

  Future<void> _loadSchedule() async {
    if (_selectedProvince == null || _selectedCity == null) return;

    setState(() => _isLoading = true);
    try {
      final data = await _service.getSchedule(_selectedProvince!, _selectedCity!);
      setState(() {
        _scheduleData = data;
        _isLoading = false;
      });
      _saveLocation();
      _scheduleNotifications(data);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.failedToLoadSurahs}: $e')),
        );
      }
    }
  }

  void _scheduleNotifications(Map<String, dynamic> data) async {
    await _notificationService.cancelAllNotifications();
    
    final List<dynamic> imsakiyah = data['imsakiyah'];
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    int notificationId = 0;

    for (var daySchedule in imsakiyah) {
      final day = daySchedule['tanggal'];
      // Skip past days
      if (day < now.day) continue;
      
      // Limit to next 7 days to avoid notification limit
      if (day > now.day + 7) break;

      final date = DateTime(currentYear, currentMonth, day);

      final times = {
        'Imsak': daySchedule['imsak'],
        'Subuh': daySchedule['subuh'],
        'Dzuhur': daySchedule['dzuhur'],
        'Ashar': daySchedule['ashar'],
        'Maghrib': daySchedule['maghrib'],
        'Isya': daySchedule['isya'],
      };

      times.forEach((name, timeStr) {
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final scheduledTime = DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );

        if (scheduledTime.isAfter(DateTime.now())) {
           _notificationService.schedulePrayerNotification(
            id: notificationId++,
            title: 'Waktu Sholat',
            body: 'Sebentar lagi waktu $name ($timeStr)',
            scheduledTime: scheduledTime,
          );
        }
      });
    }
    
    if (mounted) {
       final l10n = AppLocalizations.of(context)!;
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.notificationEnabled)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.prayerSchedule),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDropdowns(l10n),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _scheduleData != null
                      ? _buildScheduleList()
                      : Center(child: Text('${l10n.province} / ${l10n.city}')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdowns(AppLocalizations l10n) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedProvince,
          decoration: InputDecoration(
            labelText: l10n.province,
            border: const OutlineInputBorder(),
          ),
          items: _provinces.map((province) {
            return DropdownMenuItem(
              value: province,
              child: Text(province),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedProvince = value;
                _scheduleData = null;
              });
              _loadCities(value);
            }
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedCity,
          decoration: InputDecoration(
            labelText: l10n.city,
            border: const OutlineInputBorder(),
          ),
          items: _cities.map((city) {
            return DropdownMenuItem(
              value: city,
              child: Text(city),
            );
          }).toList(),
          onChanged: _selectedProvince == null
              ? null
              : (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCity = value;
                    });
                    _loadSchedule();
                  }
                },
        ),
      ],
    );
  }

  Widget _buildScheduleList() {
    final List<dynamic> schedule = _scheduleData!['imsakiyah'];
    final today = DateTime.now().day;

    final todaySchedule = schedule.firstWhere(
      (item) => item['tanggal'] == today,
      orElse: () => null,
    );

    if (todaySchedule == null) {
      return const Center(child: Text('Jadwal hari ini tidak tersedia'));
    }

    final date = DateTime.now();
    final formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_selectedCity ?? ''}, ${_selectedProvince ?? ''}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildPrayerTimeCard('Imsak', todaySchedule['imsak']),
          _buildPrayerTimeCard('Subuh', todaySchedule['subuh']),
          _buildPrayerTimeCard('Terbit', todaySchedule['terbit']),
          _buildPrayerTimeCard('Dhuha', todaySchedule['dhuha']),
          _buildPrayerTimeCard('Dzuhur', todaySchedule['dzuhur']),
          _buildPrayerTimeCard('Ashar', todaySchedule['ashar']),
          _buildPrayerTimeCard('Maghrib', todaySchedule['maghrib']),
          _buildPrayerTimeCard('Isya', todaySchedule['isya']),
        ],
      ),
    );
  }

  Widget _buildPrayerTimeCard(String label, String time) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              time,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
