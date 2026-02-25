import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tilawah_ku/l10n/gen/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../providers/quran_provider.dart';
import '../models/user_target.dart';
import '../models/user_profile.dart';
import '../utils/theme.dart'; // Add this import

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            children: [
              _buildProfileSection(context, l10n),
              const Divider(),
              SwitchListTile(
                title: Text(l10n.darkMode),
                subtitle: Text(l10n.enableDarkTheme),
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
              ),
              const Divider(),
              ListTile(
                title: Text(l10n.readingPreferences),
                subtitle: Text(l10n.customizeReading),
              ),
              SwitchListTile(
                title: Text(l10n.showLatin),
                subtitle: Text(l10n.showLatinDesc),
                value: themeProvider.showLatin,
                onChanged: (value) {
                  themeProvider.toggleLatin(value);
                },
              ),
              SwitchListTile(
                title: Text(l10n.showTranslation),
                subtitle: Text(l10n.showTranslationDesc),
                value: themeProvider.showTranslation,
                onChanged: (value) {
                  themeProvider.toggleTranslation(value);
                },
              ),
              const Divider(),
              ListTile(
                title: Text(l10n.arabicFont),
                subtitle: Text(themeProvider.arabicFont),
                trailing: const Icon(Icons.text_fields),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.selectArabicFont),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: themeProvider.availableArabicFonts.map((font) {
                            return RadioListTile<String>(
                              title: Text(font),
                              subtitle: Text('بسم الله الرحمن الرحيم', style: AppTheme.arabicText(font)),
                              value: font,
                              groupValue: themeProvider.arabicFont,
                              onChanged: (value) {
                                if (value != null) {
                                  themeProvider.setArabicFont(value);
                                  Navigator.pop(context);
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                title: Text(l10n.appLanguage),
                subtitle: Text(themeProvider.languageCode == 'id' ? 'Indonesia' : 'English'),
                trailing: const Icon(Icons.language),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.appLanguage),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<String>(
                            title: const Text('Indonesia'),
                            value: 'id',
                            groupValue: themeProvider.languageCode,
                            onChanged: (value) {
                              if (value != null) {
                                themeProvider.setLanguage(value);
                                Navigator.pop(context);
                              }
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('English'),
                            value: 'en',
                            groupValue: themeProvider.languageCode,
                            onChanged: (value) {
                              if (value != null) {
                                themeProvider.setLanguage(value);
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                title: Text(l10n.dailyTarget),
                subtitle: Text(l10n.setDailyGoal),
                trailing: const Icon(Icons.edit),
                onTap: () => _showTargetDialog(context, l10n),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, AppLocalizations l10n) {
    return Consumer<QuranProvider>(
      builder: (context, provider, child) {
        final profile = provider.userProfile;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(profile.name.isNotEmpty ? profile.name : 'User'),
          subtitle: Text(profile.email.isNotEmpty ? profile.email : 'No email set'),
          trailing: const Icon(Icons.edit),
          onTap: () => _showProfileDialog(context, l10n),
        );
      },
    );
  }

  void _showProfileDialog(BuildContext context, AppLocalizations l10n) {
    final provider = context.read<QuranProvider>();
    final nameController = TextEditingController(text: provider.userProfile.name);
    final emailController = TextEditingController(text: provider.userProfile.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editProfile),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.userName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: l10n.email,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final newProfile = UserProfile(
                name: nameController.text,
                email: emailController.text,
              );
              provider.updateUserProfile(newProfile);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.profileSaved)),
              );
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showTargetDialog(BuildContext context, AppLocalizations l10n) {
    final provider = context.read<QuranProvider>();
    final controller = TextEditingController(text: provider.userTarget.dailyAyahTarget.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.setDailyGoal),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.numberOfAyahs),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.numberOfAyahs,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final target = int.tryParse(controller.text);
              if (target != null && target > 0) {
                provider.updateUserTarget(UserTarget(dailyAyahTarget: target));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l10n.dailyGoal} updated to $target ${l10n.ayah}')),
                );
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
