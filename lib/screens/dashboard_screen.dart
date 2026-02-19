import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tilawah_ku/l10n/gen/app_localizations.dart';
import '../providers/quran_provider.dart';
import '../providers/task_provider.dart';
import '../utils/theme.dart';
import 'quran_reader_screen.dart';
import 'task_screen.dart';
import 'surah_list_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuranProvider>().loadLastRead();
      context.read<QuranProvider>().loadUserTarget();
      context.read<QuranProvider>().fetchSurahs(); // Fetch surah list
      context.read<TaskProvider>().loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(),
              const SizedBox(height: 20),
              _buildLastReadCard(context),
              const SizedBox(height: 20),
              _buildProgressOverview(context),
              const SizedBox(height: 20),
              _buildSurahList(context), // Add Surah List
              const SizedBox(height: 20),
              _buildTaskSummary(context),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TaskScreen()),
          );
        },
        child: const Icon(Icons.add_task),
      ),
    );
  }

  Widget _buildGreeting() {
    return Consumer<QuranProvider>(
      builder: (context, provider, child) {
        final profile = provider.userProfile;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assalamualaikum, ${profile.name}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLastReadCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<QuranProvider>(
      builder: (context, provider, child) {
        final lastRead = provider.lastRead;
        return Card(
          color: AppTheme.primaryColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.lastRead,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const Icon(Icons.book, color: Colors.white70),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  lastRead != null
                      ? '${l10n.surah} ${lastRead['surah']}, ${l10n.ayah} ${lastRead['ayah']}'
                      : l10n.startReading,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldColor,
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: () {
                      if (lastRead != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuranReaderScreen(
                              surahId: lastRead['surah']!,
                              initialAyahId: lastRead['ayah']!,
                            ),
                          ),
                        );
                      } else {
                         Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuranReaderScreen(
                              surahId: 1, // Start from Al-Fatiha
                              initialAyahId: 1,
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(l10n.continueReading),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressOverview(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<QuranProvider>(
      builder: (context, provider, child) {
        int target = provider.userTarget.dailyAyahTarget;
        int current = provider.dailyProgress;
        double progress = (target > 0) ? (current / target).clamp(0.0, 1.0) : 0.0;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircularProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.accentColor,
                  color: AppTheme.primaryColor,
                  strokeWidth: 8,
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dailyGoal,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '$current / $target ${l10n.numberOfAyahs}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSurahList(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<QuranProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.surahs.isEmpty) {
           return const Center(child: CircularProgressIndicator());
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.surahList,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full surah list screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SurahListScreen(),
                      ),
                    );
                  },
                  child: Text(l10n.viewAll),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Show only first 5 surahs in dashboard
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.surahs.take(5).length,
              itemBuilder: (context, index) {
                final surah = provider.surahs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.accentColor,
                      child: Text(
                        '${surah.number}',
                        style: const TextStyle(color: AppTheme.primaryColor),
                      ),
                    ),
                    title: Text(surah.nameLatin, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${surah.translation} • ${surah.numberOfAyahs} ${l10n.numberOfAyahs}'),
                    trailing: Text(
                      surah.name,
                      style: AppTheme.arabicText.copyWith(fontSize: 20),
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
          ],
        );
      },
    );
  }

  Widget _buildTaskSummary(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        final tasks = provider.tasks.take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.tasksForToday,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TaskScreen()),
                    );
                  },
                  child: Text(l10n.viewAll),
                ),
              ],
            ),
            if (tasks.isEmpty)
              Text(l10n.noTasks),
            ...tasks.map((task) => CheckboxListTile(
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  value: task.isCompleted,
                  onChanged: (val) {
                    provider.toggleTaskCompletion(task);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                )),
          ],
        );
      },
    );
  }
}
