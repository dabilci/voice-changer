import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import '../providers/audio_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/record_button.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/waveform_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Ses Değiştirici'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Consumer<AudioProvider>(
        builder: (context, audioProvider, child) {
          // Kayıt durumuna göre animasyonu başlat/durdur
          if (audioProvider.isRecording && !_pulseController.isAnimating) {
            _pulseController.repeat(reverse: true);
          } else if (!audioProvider.isRecording && _pulseController.isAnimating) {
            _pulseController.stop();
            _pulseController.reset();
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 
                    MediaQuery.of(context).padding.top - 
                    MediaQuery.of(context).padding.bottom - 
                    kToolbarHeight - 
                    kBottomNavigationBarHeight - 
                    48, // padding
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Üst bilgi kartı
                      _buildInfoCard(audioProvider),
                      
                      const SizedBox(height: 32),
                      
                      // Seçili dosya bilgisi
                      if (audioProvider.currentAudioPath != null) ...[
                        _buildCurrentFileCard(audioProvider),
                        const SizedBox(height: 32),
                      ],
                      
                      // Dalga formu
                      _buildWaveformSection(audioProvider),
                      
                      const SizedBox(height: 40),
                      
                      // Ana kayıt butonu ve ses ekleme
                      _buildRecordingSection(audioProvider),
                      
                      const SizedBox(height: 32),
                      
                      // Oynatma kontrolleri
                      if (audioProvider.currentAudioPath != null) ...[
                        _buildPlaybackControls(audioProvider),
                        const SizedBox(height: 32),
                      ],
                      
                      // Esnek boşluk
                      const Expanded(child: SizedBox()),
                      
                      // Alt bilgi metni
                      _buildBottomInfo(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(AudioProvider audioProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.mic,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ses Kayıt Durumu',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusText(audioProvider),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _getStatusColor(audioProvider),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentFileCard(AudioProvider audioProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.audio_file,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seçili Dosya',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    audioProvider.currentFileName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (audioProvider.fileInfo.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      audioProvider.fileInfo,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveformSection(AudioProvider audioProvider) {
    return Card(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 120, // Sabit yükseklik
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: audioProvider.isRecording
              ? const WaveformWidget()
              : Center(
                  key: const ValueKey('placeholder'),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.graphic_eq,
                        size: 32,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kayıt başladığında dalga formu burada görünecek',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildRecordingSection(AudioProvider audioProvider) {
    return Column(
      children: [
        // Ana kayıt butonu
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: audioProvider.isRecording ? _pulseAnimation.value : 1.0,
              child: RecordButton(
                isRecording: audioProvider.isRecording,
                isProcessing: false,
                onPressed: () async {
                  try {
                    if (audioProvider.isRecording) {
                      await audioProvider.stopRecording();
                      _showRecordingCompleteSnackBar();
                    } else {
                      await audioProvider.startRecording();
                    }
                  } catch (e) {
                    _showErrorSnackBar(e.toString());
                  }
                },
              ),
            );
          },
        ),
        
        const SizedBox(height: 24),
        
        // "VEYA" ayırıcısı
        Row(
          children: [
            Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'VEYA',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Ses ekleme butonu
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              try {
                await audioProvider.pickAudioFile();
                if (audioProvider.currentAudioPath != null) {
                  _showImportSuccessSnackBar();
                }
              } catch (e) {
                _showErrorSnackBar(e.toString());
              }
            },
            icon: const Icon(Icons.file_upload),
            label: const Text('WAV Dosyası Ekle'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Format bilgisi
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lütfen yükleyeceğiniz ses dosyanızı WAV formatında yükleyiniz',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControls(AudioProvider audioProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Ses Oynatıcı',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            AudioPlayerWidget(
              filePath: audioProvider.currentAudioPath!,
              useCard: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'İpucu: Ses dosyanızı seçtikten sonra "Efektler" sekmesinden çeşitli ses efektleri uygulayabilirsiniz.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(AudioProvider audioProvider) {
    if (audioProvider.isRecording) return 'Kayıt yapılıyor...';
    if (audioProvider.isPlaying) return 'Oynatılıyor...';
    if (audioProvider.currentAudioPath != null) return 'Ses dosyası hazır';
    return 'Kayıt yapmaya hazır';
  }

  Color _getStatusColor(AudioProvider audioProvider) {
    if (audioProvider.isRecording) return Colors.red;

    if (audioProvider.isPlaying) return Colors.green;
    if (audioProvider.currentAudioPath != null) return Colors.blue;
    return Theme.of(context).colorScheme.outline;
  }

  void _showRecordingCompleteSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Kayıt başarıyla tamamlandı!'),
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

  void _showImportSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Başarıyla eklendi'),
          ],
        ),
        backgroundColor: Colors.blue,
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
            SizedBox(width: 8),
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

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nasıl Kullanılır?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Kayıt butonuna basarak ses kaydını başlatın'),
            SizedBox(height: 8),
            Text('2. VEYA telefonunuzdan ses dosyası ekleyin'),
            SizedBox(height: 8),
            Text('3. "Efektler" sekmesinden istediğiniz efekti seçin'),
            SizedBox(height: 8),
            Text('4. "Dosyalarım" sekmesinden kayıtlarınızı yönetin'),
            SizedBox(height: 12),
            Text('📝 Not: MP3, OPUS gibi formatlar otomatik olarak WAV\'a çevrilir', 
                 style: TextStyle(fontStyle: FontStyle.italic)),
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