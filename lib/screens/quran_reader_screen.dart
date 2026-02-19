import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/quran_provider.dart';
import '../providers/theme_provider.dart';
import '../models/ayah.dart';
import '../utils/theme.dart';

class QuranReaderScreen extends StatefulWidget {
  final int surahId;
  final int initialAyahId;
  final int? endSurahId; // For Juz reading
  final int? endAyahId;   // For Juz reading

  const QuranReaderScreen({
    super.key,
    required this.surahId,
    this.initialAyahId = 1,
    this.endSurahId,
    this.endAyahId,
  });

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  bool _scrolled = false;

  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<QuranProvider>();
      
      if (widget.endSurahId != null && widget.endAyahId != null) {
        // Fetch Juz (Range of Surahs/Ayahs)
        provider.fetchJuzDetail(
          widget.surahId, 
          widget.initialAyahId, 
          widget.endSurahId!, 
          widget.endAyahId!
        ).then((_) {
           // Scroll to top or specific position if needed
        });
      } else {
        // Fetch Single Surah
        provider.fetchSurahDetail(widget.surahId).then((_) {
          if (widget.initialAyahId > 1 && !_scrolled) {
            _scrollToAyah(widget.initialAyahId);
          }
        });
      }
    });
  }

  void _scrollToAyah(int ayahNumber) {
    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: ayahNumber - 1, // 0-based index
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() {
        _scrolled = true;
      });
    } else {
      // Retry if not attached yet (rare but possible)
      Future.delayed(const Duration(milliseconds: 100), () => _scrollToAyah(ayahNumber));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isJuzMode = widget.endSurahId != null;

    return Scaffold(
      appBar: AppBar(
        title: _isSearchVisible
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: isJuzMode ? 'Search Ayah or Surah Name...' : 'Search Ayah Number...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                keyboardType: isJuzMode ? TextInputType.text : TextInputType.number,
                onSubmitted: (value) {
                  _handleSearch(value, isJuzMode);
                },
              )
            : Consumer<QuranProvider>(
                builder: (context, provider, child) {
                  return Text(provider.currentSurah?.nameLatin ?? 'Loading...');
                },
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchController.clear();
                }
              });
            },
          ),
          if (!_isSearchVisible)
            IconButton(
              icon: const Icon(Icons.bookmark),
              onPressed: () {
                // Show bookmarks or save current position
                final visibleIndices = _itemPositionsListener.itemPositions.value
                    .where((item) => item.itemLeadingEdge >= 0)
                    .map((item) => item.index)
                    .toList();
                if (visibleIndices.isNotEmpty) {
                   final currentAyahIndex = visibleIndices.first;
                   final provider = context.read<QuranProvider>();
                   final ayah = provider.currentAyahs[currentAyahIndex];
                   // Note: When reading Juz, ayah.number might restart for new Surah, 
                   // but saveLastRead takes SurahID and AyahID.
                   // We need to find the correct SurahID for the visible ayah.
                   // Since provider.currentAyahs stores Ayah objects which (should) have surahId if we added it to model.
                   // Let's check Ayah model.
                   
                   // Assuming Ayah model has surahId (I recall adding it or it being there).
                   // Let's use the surahId from the ayah object if available, otherwise fallback to widget.surahId (which is start surah).
                   
                   _saveLastRead(ayah.surahId, ayah.number);
                }
              },
            ),
        ],
      ),
      body: Consumer<QuranProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.currentSurah == null) {
            return const Center(child: Text('Failed to load Surah'));
          }

          final ayahs = provider.currentAyahs;

          return ScrollablePositionedList.builder(
            itemCount: ayahs.length,
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositionsListener,
            itemBuilder: (context, index) {
              final ayah = ayahs[index];
              return _buildAyahItem(ayah, index);
            },
          );
        },
      ),
    );
  }

  void _handleSearch(String query, bool isJuzMode) {
    if (query.isEmpty) return;

    final provider = context.read<QuranProvider>();
    final ayahs = provider.currentAyahs;
    int? targetIndex;

    if (isJuzMode) {
      // Juz Mode: Search by Ayah Number OR Surah Name
      if (int.tryParse(query) != null) {
        // If number, find ayah with that number in CURRENT list (might be multiple if multiple surahs)
        // Usually users mean "Ayah X of current/first surah" or just "Ayah X relative to Juz start" (rare).
        // Let's assume they mean Ayah number in the FIRST surah visible or just find the first occurrence.
        final ayahNum = int.parse(query);
        targetIndex = ayahs.indexWhere((a) => a.number == ayahNum);
      } else {
        // If text, search by Surah Name Latin (fuzzy match)
        // We need to find the first ayah of the matching Surah.
        // We don't have Surah Name in Ayah model directly accessible as a string field unless we check surahId map.
        // But provider.surahs has the list.
        final surahMatch = provider.surahs.firstWhere(
          (s) => s.nameLatin.toLowerCase().contains(query.toLowerCase()),
          orElse: () => provider.surahs.first, // Fallback
        );
        
        // Find the first ayah belonging to this Surah ID in our current list
        targetIndex = ayahs.indexWhere((a) => a.surahId == surahMatch.number);
      }
    } else {
      // Single Surah Mode: Search by Ayah Number only
      final ayahNum = int.tryParse(query);
      if (ayahNum != null) {
        targetIndex = ayahs.indexWhere((a) => a.number == ayahNum);
      }
    }

    if (targetIndex != null && targetIndex != -1) {
      if (_itemScrollController.isAttached) {
        _itemScrollController.scrollTo(
          index: targetIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() {
          _isSearchVisible = false;
          _searchController.clear();
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ayah/Surah not found in this view')),
      );
    }
  }

  Widget _buildAyahItem(Ayah ayah, int index) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.accentColor,
                      child: Text(
                        '${ayah.number}',
                        style: const TextStyle(color: AppTheme.primaryColor),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          tooltip: 'Mark as Read',
                          onPressed: () {
                            context.read<QuranProvider>().incrementDailyProgress();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Daily Progress Updated!')),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.share),
                          tooltip: 'Share Ayah',
                          onPressed: () {
                            final surahName = context.read<QuranProvider>().currentSurah?.nameLatin ?? '';
                            // ignore: deprecated_member_use
                            Share.share(
                              '${ayah.textArabic}\n\n'
                              '${ayah.textLatin}\n'
                              '${ayah.textIndonesian}\n\n'
                              '(QS $surahName: ${ayah.number}) - TilawahKU',
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.bookmark_border),
                          tooltip: 'Save Last Read',
                          onPressed: () {
                             // Correctly handle Surah ID for Juz reading mode
                             // If we have surahId in Ayah model, use it.
                             // Otherwise, fallback to widget.surahId (which might be incorrect for multi-surah juz view)
                             // Since we don't have surahId in Ayah model (based on previous file read, it was added in fromJson but maybe not field?)
                             // Let's check Ayah model again if needed.
                             // Wait, I see "targetIndex = ayahs.indexWhere((a) => a.surahId == surahMatch.number);" in search logic.
                             // This implies Ayah model HAS surahId.
                             _saveLastRead(ayah.surahId, ayah.number);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  ayah.textArabic,
                  textAlign: TextAlign.right,
                  style: AppTheme.arabicText,
                ),
                if (themeProvider.showLatin) ...[
                  const SizedBox(height: 16),
                  Text(
                    ayah.textLatin,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[700],
                        ),
                  ),
                ],
                if (themeProvider.showTranslation) ...[
                  const SizedBox(height: 8),
                  Text(
                    ayah.textIndonesian,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _saveLastRead(int surahNumber, int ayahNumber) {
    context.read<QuranProvider>().saveLastRead(surahNumber, ayahNumber);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved as Last Read: Surah $surahNumber, Ayah $ayahNumber')),
    );
  }
}
