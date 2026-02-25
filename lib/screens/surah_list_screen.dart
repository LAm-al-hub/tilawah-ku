import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tilawah_ku/l10n/gen/app_localizations.dart';
import '../providers/quran_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/theme.dart';
import '../utils/juz_data.dart';
import 'quran_reader_screen.dart';

class SurahListScreen extends StatelessWidget {
  const SurahListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.surahList),
      ),
      body: Consumer<QuranProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.surahs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.surahs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    l10n.failedToLoadSurahs,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ElevatedButton(
                    onPressed: () => provider.fetchSurahs(),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          // Group surahs by Juz
          // ... (comments kept for context)
          
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  labelColor: AppTheme.primaryColor,
                  tabs: [
                    Tab(text: l10n.surah),
                    Tab(text: l10n.juz),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Surah List
                      ListView.builder(
                        itemCount: provider.surahs.length,
                        itemBuilder: (context, index) {
                          final surah = provider.surahs[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.accentColor,
                                child: Text(
                                  '${surah.number}',
                                  style: const TextStyle(color: AppTheme.primaryColor),
                                ),
                              ),
                              title: Text(surah.nameLatin, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${surah.translation} • ${surah.numberOfAyahs} ${l10n.numberOfAyahs} • ${surah.place.toUpperCase()}'),
                              trailing: Consumer<ThemeProvider>(
                                builder: (context, themeProvider, child) {
                                  return Text(
                                    surah.name,
                                    style: AppTheme.arabicText(themeProvider.arabicFont).copyWith(fontSize: 20),
                                  );
                                },
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuranReaderScreen(
                                      surahId: surah.number,
                                      initialAyahId: 1,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      
                      // Juz List with Real Navigation
                      ListView.builder(
                        itemCount: JuzData.juzList.length,
                        itemBuilder: (context, index) {
                          final juz = JuzData.juzList[index];
                          final juzNumber = juz['juz'];
                          final startSurahId = juz['start_surah'];
                          final startAyahId = juz['start_ayah'];
                          
                          // Find Surah Name for subtitle
                          final surahName = provider.surahs.isNotEmpty 
                              ? provider.surahs.firstWhere((s) => s.number == startSurahId, orElse: () => provider.surahs.first).nameLatin
                              : 'Surah $startSurahId';

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.goldColor,
                                child: Text(
                                  '$juzNumber',
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ),
                              title: Text('${l10n.juz} $juzNumber', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${l10n.startsAt} $surahName : ${l10n.ayah} $startAyahId'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuranReaderScreen(
                                      surahId: startSurahId,
                                      initialAyahId: startAyahId,
                                      endSurahId: juz['end_surah'],
                                      endAyahId: juz['end_ayah'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
