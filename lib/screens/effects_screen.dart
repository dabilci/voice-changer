import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/effects_provider.dart';
import '../widgets/audio_player_widget.dart';

class EffectsScreen extends StatefulWidget {
  const EffectsScreen({super.key});

  @override
  State<EffectsScreen> createState() => _EffectsScreenState();
}

class _EffectsScreenState extends State<EffectsScreen> {
  String? _selectedFile;

  // Sadece recording ve imported dosyalarını filtrele
  List<AudioFile> _getRecordingFiles(List<AudioFile> allFiles) {
    return allFiles.where((file) {
      final fileName = file.name.toLowerCase();
      
      // Sadece recording veya imported ile başlayan orijinal dosyaları al
      final isRecording = fileName.startsWith('recording');
      final isImported = fileName.startsWith('imported_');
      
      // Efekt uygulanmış dosyaları filtrele (efekt prefix'leri ile başlayanları hariç tut)
      final effectPrefixes = [
        'robot_', 'echo_', 'helium_', 'deep_', 'reverb_', 'child_', 'oldman_',
        'woman_', 'man_', 'telephone_', 'radio_', 'megaphone_', 'underwater_',
        'cave_', 'space_', 'wind_', 'tunnel_', 'frog_', 'alien_', 'devil_',
        'static_', 'chorus_', 'flanger_', 'phaser_', 'tremolo_'
      ];
      
      final hasEffectPrefix = effectPrefixes.any((prefix) => fileName.startsWith(prefix));
      
      // SADECE recording veya imported ile başlayan VE efekt prefix'i olmayan dosyaları döndür
      return (isRecording || isImported) && !hasEffectPrefix;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Ses Efektleri'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(),
          ),
        ],
      ),
      body: Consumer2<AudioProvider, EffectsProvider>(
        builder: (context, audioProvider, effectsProvider, child) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Dosya seçim kartı
                  _buildFileSelectionCard(audioProvider),
                  
                  const SizedBox(height: 24),
                  
                  // Efektler grid
                  Expanded(
                    child: _buildEffectsGrid(
                      audioProvider, 
                      effectsProvider,
                    ),
                  ),
                  
                  // İşlem durumu
                  if (effectsProvider.isProcessing)
                    _buildProcessingCard(effectsProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFileSelectionCard(AudioProvider audioProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.audio_file,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ses Dosyası Seçin',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Efekt uygulamak için bir ses dosyası seçin',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Dosya seçim dropdown - sadece recording dosyaları
              if (_getRecordingFiles(audioProvider.audioFiles).isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: _selectedFile,
                  decoration: InputDecoration(
                    labelText: 'Ses Dosyası (Kayıtlarım)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    prefixIcon: const Icon(Icons.audiotrack),
                  ),
                  isExpanded: true,
                  items: _getRecordingFiles(audioProvider.audioFiles).map((file) {
                    return DropdownMenuItem(
                      value: file.path,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          file.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${file.formattedSize} • ${file.formattedDate}',
                           overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }).toList(),
                  selectedItemBuilder: (BuildContext context) {
                    return _getRecordingFiles(audioProvider.audioFiles).map((file) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          file.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList();
                  },
                  onChanged: (value) {
                    setState(() {
                      _selectedFile = value;
                    });
                  },
                ),
                
                // Seçili dosya için oynatıcı
                if (_selectedFile != null) ...[
                  const SizedBox(height: 16),
                  AudioPlayerWidget(
                    filePath: _selectedFile!,
                    showActions: false,
                  ),
                ],
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.mic_off,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Henüz ses dosyası yok',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Efekt uygulamak için "Kaydet" sekmesinden:\n• Mikrofon ile kayıt yapın\n• Telefondan ses dosyası ekleyin\n\nSadece orijinal ses dosyaları burada görünür.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEffectsGrid(AudioProvider audioProvider, EffectsProvider effectsProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Efektler',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75, // Daha uzun kart
              ),
              itemCount: effectsProvider.availableEffects.length,
              itemBuilder: (context, index) {
                final effect = effectsProvider.availableEffects[index];
                final isEnabled = _selectedFile != null && !effectsProvider.isProcessing;
                
                return _buildEffectCard(
                  effect,
                  isEnabled,
                  () => _applyEffect(audioProvider, effectsProvider, effect.effect),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEffectCard(EffectOption effect, bool isEnabled, VoidCallback onTap) {
    return Card(
      elevation: isEnabled ? 4 : 1,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                  : Theme.of(context).colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isEnabled 
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.outline.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  effect.icon,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  effect.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isEnabled 
                        ? null
                        : Theme.of(context).colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  effect.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isEnabled 
                        ? Theme.of(context).colorScheme.outline
                        : Theme.of(context).colorScheme.outline.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingCard(EffectsProvider effectsProvider) {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        effectsProvider.processingStatus,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Lütfen bekleyin, ses dosyanız işleniyor...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyEffect(
    AudioProvider audioProvider,
    EffectsProvider effectsProvider,
    AudioEffect effect,
  ) async {
    if (_selectedFile == null) return;

    try {
      final result = await effectsProvider.applyEffect(_selectedFile!, effect);
      
      if (result != null && mounted) {
        // Başarılı işlem sonrası snackbar
        final effectOption = effectsProvider.availableEffects.firstWhere((e) => e.effect == effect);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${effectOption.name} efekti başarıyla uygulandı!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'Oynat',
              textColor: Colors.white,
              onPressed: () => audioProvider.playAudio(result),
            ),
          ),
        );

        // Dosya listesini güncelle
        await audioProvider.loadAudioFiles();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Efekt uygulanamadı: $e')),
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
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Efektler Nasıl Kullanılır?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Yukarıdan bir ses dosyası seçin'),
            SizedBox(height: 8),
            Text('2. Uygulamak istediğiniz efekte dokunun'),
            SizedBox(height: 8),
            Text('3. İşlem tamamlandığında yeni dosya otomatik oluşur'),
            SizedBox(height: 8),
            Text('4. "Dosyalarım" sekmesinden tüm kayıtlarınıza erişebilirsiniz'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }
}