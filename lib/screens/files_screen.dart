import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/ad_helper.dart';
import '../providers/audio_provider.dart';
import '../widgets/audio_player_widget.dart';

// Dosya grubu modeli
class AudioFileGroup {
  final String baseName; // Orijinal dosya adı
  final AudioFile originalFile; // Orijinal kayıt
  final List<AudioFile> effectFiles; // Efekt uygulanmış versiyonlar

  AudioFileGroup({
    required this.baseName,
    required this.originalFile,
    required this.effectFiles,
  });

  int get totalFiles => 1 + effectFiles.length;
  
  List<AudioFile> get allFiles => [originalFile, ...effectFiles];
}

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  String _searchQuery = '';
  bool _showSearchBar = false;
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = AdHelper.instance.bannerAd;
    // We don't need to call load() here because it's pre-loaded in main.dart
    // Just re-assign it to the local variable.
    // If it's not ready, the UI won't show it.
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: _showSearchBar 
            ? _buildSearchField()
            : const Text('Dosyalarım'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(_showSearchBar ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) {
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortDialog(),
          ),
        ],
      ),
      body: Consumer2<AudioProvider, AdHelper>(
        builder: (context, audioProvider, adHelper, child) {
          final fileGroups = _createFileGroups(audioProvider.audioFiles);
          final filteredGroups = _getFilteredGroups(fileGroups);
          
          return RefreshIndicator(
            onRefresh: () async {
              await audioProvider.loadAudioFiles();
            },
            child: filteredGroups.isEmpty
                ? _buildEmptyState()
                : _buildGroupsList(audioProvider, filteredGroups),
          );
        },
      ),
      bottomNavigationBar: Consumer<AdHelper>(
        builder: (context, adHelper, child) {
          if (adHelper.isBannerAdReady && _bannerAd != null) {
            return SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // Dosyaları grupla
  List<AudioFileGroup> _createFileGroups(List<AudioFile> files) {
    final Map<String, List<AudioFile>> groupMap = {};
    
    // Dosyaları base name'e göre grupla
    for (final file in files) {
      String baseName = _extractBaseName(file.name);
      groupMap.putIfAbsent(baseName, () => []);
      groupMap[baseName]!.add(file);
    }
    
    // Grupları oluştur
    final groups = <AudioFileGroup>[];
    
    for (final entry in groupMap.entries) {
      final files = entry.value;
      files.sort((a, b) => a.createdAt.compareTo(b.createdAt)); // En eski önce
      
      // Orijinal dosyayı bul (efekt içermeyen)
      AudioFile? originalFile;
      final effectFiles = <AudioFile>[];
      
      for (final file in files) {
        if (_isEffectFile(file.name)) {
          effectFiles.add(file);
        } else {
          originalFile ??= file; // İlk orijinal dosyayı al
        }
      }
      
      if (originalFile != null) {
        groups.add(AudioFileGroup(
          baseName: entry.key,
          originalFile: originalFile,
          effectFiles: effectFiles,
        ));
      } else if (effectFiles.isNotEmpty) {
        // Eğer orijinal dosya yoksa ilk efekt dosyasını orijinal olarak kabul et
        groups.add(AudioFileGroup(
          baseName: entry.key,
          originalFile: effectFiles.first,
          effectFiles: effectFiles.skip(1).toList(),
        ));
      }
    }
    
    // Grupları tarihe göre sırala (en yeni önce)
    groups.sort((a, b) => b.originalFile.createdAt.compareTo(a.originalFile.createdAt));
    
    return groups;
  }
  
  // Base name çıkar (efekt prefix'lerini kaldır)
  String _extractBaseName(String fileName) {
    // .wav uzantısını kaldır
    String nameWithoutExt = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
    
    // Efekt prefix'lerini kaldır
    final effectPrefixes = [
      'robot-', 'echo-', 'helium-', 'deep-', 'reverb-', 'child-', 'oldman-',
      'woman-', 'man-', 'telephone-', 'radio-', 'megaphone-', 'underwater-',
      'cave-', 'space-', 'wind-', 'tunnel-', 'frog-', 'alien-', 'devil-',
      'static-', 'chorus-', 'flanger-', 'phaser-', 'tremolo-'
    ];
    
    for (final prefix in effectPrefixes) {
      if (nameWithoutExt.startsWith(prefix)) {
        return nameWithoutExt.substring(prefix.length);
      }
    }
    
    // Imported prefix'ini kaldır
    if (nameWithoutExt.startsWith('imported_')) {
      // imported_originalname_timestamp formatından originalname'i çıkar
      final parts = nameWithoutExt.substring(9).split('_'); // 'imported_' kısmını kaldır
      if (parts.length >= 2) {
        // Son iki part timestamp olması gerekir (yyyyMMdd_HHmmss)
        return parts.take(parts.length - 2).join('_');
      }
      return nameWithoutExt.substring(9); // Fallback
    }
    
    return nameWithoutExt;
  }
  
  // Efekt dosyası mı kontrol et
  bool _isEffectFile(String fileName) {
    final effectPrefixes = [
      'robot-', 'echo-', 'helium-', 'deep-', 'reverb-', 'child-', 'oldman-',
      'woman-', 'man-', 'telephone-', 'radio-', 'megaphone-', 'underwater-',
      'cave-', 'space-', 'wind-', 'tunnel-', 'frog-', 'alien-', 'devil-',
      'static-', 'chorus-', 'flanger-', 'phaser-', 'tremolo-'
    ];
    
    return effectPrefixes.any((prefix) => fileName.startsWith(prefix));
  }

  Widget _buildSearchField() {
    return TextField(
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Dosya adı ara...',
        border: InputBorder.none,
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value.toLowerCase();
        });
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open,
                size: 64,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Arama sonucu bulunamadı'
                  : 'Henüz kayıt yok',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? '"$_searchQuery" için eşleşen dosya bulunamadı'
                  : 'Kayıt yapmaya başlamak için "Kaydet" sekmesini kullanın',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Ana sayfa sekmesine git
                  DefaultTabController.of(context)?.animateTo(0);
                },
                icon: const Icon(Icons.mic),
                label: const Text('Kayıt Yapmaya Başla'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsList(AudioProvider audioProvider, List<AudioFileGroup> groups) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildGroupCard(audioProvider, group),
        );
      },
    );
  }

  Widget _buildGroupCard(AudioProvider audioProvider, AudioFileGroup group) {
    return Card(
      elevation: 2,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.audiotrack,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          group.baseName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${group.totalFiles} dosya • ${group.originalFile.formattedSize} • ${group.originalFile.formattedDate}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            if (group.effectFiles.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: group.effectFiles.take(3).map((file) {
                  final effectName = _getEffectName(file.name);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getEffectColor(effectName).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      effectName,
                      style: TextStyle(
                        fontSize: 10,
                        color: _getEffectColor(effectName),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleGroupAction(audioProvider, group, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'play_original',
              child: ListTile(
                leading: Icon(Icons.play_arrow),
                title: Text('Orijinali Oynat'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'share_all',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Tümünü Paylaş'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete_all',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Tümünü Sil', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                
                // Orijinal dosya
                _buildFileItem(
                  audioProvider,
                  group.originalFile,
                  'Orijinal',
                  Icons.mic,
                  Colors.blue,
                  isOriginal: true,
                ),
                
                // Efekt dosyaları
                if (group.effectFiles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Efekt Versiyonları (${group.effectFiles.length})',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...group.effectFiles.map((file) {
                    final effectName = _getEffectName(file.name);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildFileItem(
                        audioProvider,
                        file,
                        effectName,
                        _getEffectIcon(effectName),
                        _getEffectColor(effectName),
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(
    AudioProvider audioProvider,
    AudioFile file,
    String displayName,
    IconData icon,
    Color color, {
    bool isOriginal = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Text(
                      '${file.formattedSize} • ${file.formattedDate}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_arrow, size: 20),
                    onPressed: () => audioProvider.playAudio(file.path),
                    style: IconButton.styleFrom(
                      backgroundColor: color.withOpacity(0.1),
                      foregroundColor: color,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, size: 20),
                    onPressed: () => _shareFile(file),
                    style: IconButton.styleFrom(
                      backgroundColor: color.withOpacity(0.1),
                      foregroundColor: color,
                    ),
                  ),
                  if (!isOriginal)
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () => _showDeleteDialog(audioProvider, file),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        foregroundColor: Colors.red,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          AudioPlayerWidget(
            filePath: file.path,
            showActions: false,
          ),
        ],
      ),
    );
  }

  // Dosya adından efekt ismini çıkar
  String _getEffectName(String fileName) {
    if (fileName.startsWith('robot-')) return 'Robot';
    if (fileName.startsWith('echo-')) return 'Echo';
    if (fileName.startsWith('helium-')) return 'Helium';
    if (fileName.startsWith('deep-')) return 'Deep';
    if (fileName.startsWith('reverb-')) return 'Reverb';
    if (fileName.startsWith('child-')) return 'Çocuk';
    if (fileName.startsWith('oldman-')) return 'Yaşlı Adam';
    if (fileName.startsWith('woman-')) return 'Kadın';
    if (fileName.startsWith('man-')) return 'Erkek';
    if (fileName.startsWith('telephone-')) return 'Telefon';
    if (fileName.startsWith('radio-')) return 'Radyo';
    if (fileName.startsWith('megaphone-')) return 'Megafon';
    if (fileName.startsWith('underwater-')) return 'Sualtı';
    if (fileName.startsWith('cave-')) return 'Mağara';
    if (fileName.startsWith('space-')) return 'Uzay';
    if (fileName.startsWith('wind-')) return 'Rüzgar';
    if (fileName.startsWith('tunnel-')) return 'Tünel';
    if (fileName.startsWith('frog-')) return 'Kurbağa';
    if (fileName.startsWith('alien-')) return 'Uzaylı';
    if (fileName.startsWith('devil-')) return 'Şeytan';
    if (fileName.startsWith('static-')) return 'Statik';
    if (fileName.startsWith('chorus-')) return 'Chorus';
    if (fileName.startsWith('flanger-')) return 'Flanger';
    if (fileName.startsWith('phaser-')) return 'Phaser';
    if (fileName.startsWith('tremolo-')) return 'Tremolo';
    return 'Bilinmeyen';
  }

  // Efekt ikonunu getir
  IconData _getEffectIcon(String effectName) {
    switch (effectName) {
      case 'Robot': return Icons.smart_toy;
      case 'Echo': return Icons.graphic_eq;
      case 'Helium': return Icons.bubble_chart;
      case 'Deep': return Icons.waves;
      case 'Reverb': return Icons.surround_sound;
      case 'Çocuk': return Icons.child_care;
      case 'Yaşlı Adam': return Icons.elderly;
      case 'Kadın': return Icons.face_3;
      case 'Erkek': return Icons.face;
      case 'Telefon': return Icons.phone;
      case 'Radyo': return Icons.radio;
      case 'Megafon': return Icons.campaign;
      case 'Sualtı': return Icons.water;
      case 'Mağara': return Icons.landscape;
      case 'Uzay': return Icons.rocket_launch;
      case 'Rüzgar': return Icons.air;
      case 'Tünel': return Icons.architecture;
      case 'Kurbağa': return Icons.pets;
      case 'Uzaylı': return Icons.flight;
      case 'Şeytan': return Icons.whatshot;
      case 'Statik': return Icons.electrical_services;
      case 'Chorus': return Icons.queue_music;
      case 'Flanger': return Icons.multitrack_audio;
      case 'Phaser': return Icons.tune;
      case 'Tremolo': return Icons.vibration;
      default: return Icons.auto_fix_high;
    }
  }

  // Efekt rengini getir
  Color _getEffectColor(String effectName) {
    switch (effectName) {
      case 'Robot': return Colors.grey;
      case 'Echo': return Colors.purple;
      case 'Helium': return Colors.green;
      case 'Deep': return Colors.brown;
      case 'Reverb': return Colors.indigo;
      case 'Çocuk': return Colors.pink;
      case 'Yaşlı Adam': return Colors.orange;
      case 'Kadın': return Colors.pink;
      case 'Erkek': return Colors.blue;
      case 'Telefon': return Colors.teal;
      case 'Radyo': return Colors.amber;
      case 'Megafon': return Colors.red;
      case 'Sualtı': return Colors.lightBlue;
      case 'Mağara': return Colors.blueGrey;
      case 'Uzay': return Colors.deepPurple;
      case 'Rüzgar': return Colors.cyan;
      case 'Tünel': return Colors.brown;
      case 'Kurbağa': return Colors.lightGreen;
      case 'Uzaylı': return Colors.lime;
      case 'Şeytan': return Colors.deepOrange;
      case 'Statik': return Colors.grey;
      case 'Chorus': return Colors.purple;
      case 'Flanger': return Colors.teal;
      case 'Phaser': return Colors.indigo;
      case 'Tremolo': return Colors.orange;
      default: return Colors.blue;
    }
  }

  List<AudioFileGroup> _getFilteredGroups(List<AudioFileGroup> groups) {
    if (_searchQuery.isEmpty) return groups;
    
    return groups.where((group) {
      return group.baseName.toLowerCase().contains(_searchQuery) ||
             group.allFiles.any((file) => file.name.toLowerCase().contains(_searchQuery));
    }).toList();
  }

  Future<void> _handleGroupAction(
    AudioProvider audioProvider,
    AudioFileGroup group,
    String action,
  ) async {
    switch (action) {
      case 'play_original':
        await audioProvider.playAudio(group.originalFile.path);
        break;
      case 'share_all':
        await _shareAllFiles(group.allFiles);
        break;
      case 'delete_all':
        await _showDeleteGroupDialog(audioProvider, group);
        break;
    }
  }

  Future<void> _shareFile(AudioFile file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Ses Değiştirici uygulamasıyla oluşturduğum "${file.name}" dosyası',
      );
    } catch (e) {
      _showErrorSnackBar('Paylaşım başarısız: $e');
    }
  }

  Future<void> _shareAllFiles(List<AudioFile> files) async {
    try {
      final xFiles = files.map((file) => XFile(file.path)).toList();
      await Share.shareXFiles(
        xFiles,
        text: 'Ses Değiştirici uygulamasıyla oluşturduğum ${files.length} ses dosyası',
      );
    } catch (e) {
      _showErrorSnackBar('Paylaşım başarısız: $e');
    }
  }

  Future<void> _showDeleteDialog(AudioProvider audioProvider, AudioFile file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dosyayı Sil'),
        content: Text('${file.name} dosyasını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await audioProvider.deleteAudioFile(file.path);
        _showSuccessSnackBar('Dosya başarıyla silindi');
      } catch (e) {
        _showErrorSnackBar('Silme işlemi başarısız: $e');
      }
    }
  }

  Future<void> _showDeleteGroupDialog(AudioProvider audioProvider, AudioFileGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Dosyaları Sil'),
        content: Text('${group.baseName} grubundaki tüm dosyaları (${group.totalFiles} dosya) silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tümünü Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        for (final file in group.allFiles) {
          await audioProvider.deleteAudioFile(file.path);
        }
        _showSuccessSnackBar('${group.totalFiles} dosya başarıyla silindi');
      } catch (e) {
        _showErrorSnackBar('Silme işlemi başarısız: $e');
      }
    }
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sıralama'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Tarihe göre (Yeni → Eski)'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('Tarihe göre (Eski → Yeni)'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('İsme göre (A → Z)'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.folder_zip),
              title: const Text('Boyuta göre'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
} 