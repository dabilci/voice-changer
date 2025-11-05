import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/audio_provider.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String filePath;
  final bool showActions;
  final bool useCard;

  const AudioPlayerWidget({
    super.key,
    required this.filePath,
    this.showActions = true,
    this.useCard = true,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  bool _isCurrentlyPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final isThisFilePlaying = audioProvider.isPlaying && 
            audioProvider.currentlyPlayingPath == widget.filePath;
        
        _isCurrentlyPlaying = isThisFilePlaying;

        final content = Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Ana oynatma kontrolleri
              Row(
                children: [
                  // Play/Pause butonu
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        isThisFilePlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () async {
                        try {
                          if (isThisFilePlaying) {
                            await audioProvider.pauseAudio();
                          } else {
                            await audioProvider.playAudio(widget.filePath);
                          }
                        } catch (e) {
                          _showErrorSnackBar(e.toString());
                        }
                      },
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // İlerleme çubuğu ve süre bilgisi
                  Expanded(
                    child: Column(
                      children: [
                        // İlerleme çubuğu
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16,
                            ),
                          ),
                          child: Slider(
                            value: _getSliderValue(audioProvider).clamp(0.0, 1.0),
                            min: 0,
                            max: 1,
                            onChanged: isThisFilePlaying ? (value) {
                              final duration = audioProvider.totalDuration;
                              final position = Duration(
                                milliseconds: (duration.inMilliseconds * value).round(),
                              );
                              audioProvider.seekTo(position);
                            } : null,
                          ),
                        ),
                        
                        // Süre bilgisi
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(
                                  isThisFilePlaying 
                                      ? audioProvider.playbackPosition 
                                      : Duration.zero
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                _formatDuration(
                                  isThisFilePlaying 
                                      ? audioProvider.totalDuration 
                                      : Duration.zero
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Aksiyon butonları
              if (widget.showActions) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Paylaş butonu
                    _buildActionButton(
                      icon: Icons.share,
                      label: 'Paylaş',
                      onPressed: () => _shareAudio(),
                    ),
                    
                    // Stop butonu
                    _buildActionButton(
                      icon: Icons.stop,
                      label: 'Durdur',
                      onPressed: isThisFilePlaying 
                          ? () => audioProvider.stopAudio()
                          : null,
                    ),
                    
                    // Dosya bilgisi
                    _buildActionButton(
                      icon: Icons.info_outline,
                      label: 'Bilgi',
                      onPressed: () => _showFileInfo(),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );

        if (widget.useCard) {
          return Card(
            elevation: 2,
            child: content,
          );
        } else {
          return content;
        }
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onPressed != null 
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: onPressed != null 
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.outline,
            ),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: onPressed != null 
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  double _getSliderValue(AudioProvider audioProvider) {
    if (!_isCurrentlyPlaying || audioProvider.totalDuration.inMilliseconds == 0) {
      return 0;
    }

    final ratio = audioProvider.playbackPosition.inMilliseconds /
        audioProvider.totalDuration.inMilliseconds;
    if (ratio.isNaN) return 0;
    return ratio;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _shareAudio() async {
    try {
      final file = File(widget.filePath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(widget.filePath)],
          text: 'Ses Değiştirici uygulamasıyla oluşturduğum ses kaydı',
        );
      } else {
        _showErrorSnackBar('Dosya bulunamadı');
      }
    } catch (e) {
      _showErrorSnackBar('Paylaşım başarısız: $e');
    }
  }

  Future<void> _showFileInfo() async {
    try {
      final file = File(widget.filePath);
      final stat = await file.stat();
      final size = _formatFileSize(stat.size);
      final fileName = widget.filePath.split('/').last;
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Dosya Bilgileri'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Dosya Adı:', fileName),
              const SizedBox(height: 8),
              _buildInfoRow('Boyut:', size),
              const SizedBox(height: 8),
              _buildInfoRow('Oluşturulma:', _formatDate(stat.modified)),
              const SizedBox(height: 8),
              _buildInfoRow('Yol:', widget.filePath),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Dosya bilgileri alınamadı: $e');
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
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