import 'package:flutter/material.dart';
import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

// AudioFile modeli
class AudioFile {
  final String path;
  final String name;
  final int size;
  final DateTime createdAt;

  AudioFile({
    required this.path,
    required this.name,
    required this.size,
    required this.createdAt,
  });

  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get formattedDate {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }
}

class AudioProvider extends ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentAudioPath;
  String? _recordingPath;
  String? _currentlyPlayingPath;
  Duration _playbackPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  List<AudioFile> _audioFiles = [];
  
  // Getters
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get currentAudioPath => _currentAudioPath;
  String? get recordingPath => _recordingPath;
  String? get currentlyPlayingPath => _currentlyPlayingPath;
  Duration get playbackPosition => _playbackPosition;
  Duration get totalDuration => _totalDuration;
  List<AudioFile> get audioFiles => _audioFiles;
  
  AudioProvider() {
    _setupPlayerListeners();
    loadAudioFiles();
  }

  void _setupPlayerListeners() {
    _player.playerStateStream.listen((PlayerState state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
    
    _player.positionStream.listen((Duration position) {
      _playbackPosition = position;
      notifyListeners();
    });

    _player.durationStream.listen((Duration? duration) {
      _totalDuration = duration ?? Duration.zero;
      notifyListeners();
    });
  }

  Future<bool> _checkPermissions() async {
    final micPermission = await Permission.microphone.status;
    if (micPermission != PermissionStatus.granted) {
      final result = await Permission.microphone.request();
      return result == PermissionStatus.granted;
    }
    return true;
  }

  Future<void> startRecording() async {
    if (!await _checkPermissions()) {
      throw Exception('Mikrofon izni gerekli');
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/audio_recordings');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = '${audioDir.path}/recording_$timestamp.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordingPath!,
      );
      
      _isRecording = true;
      notifyListeners();
    } catch (e) {
      print('Kayıt başlatma hatası: $e');
      rethrow;
    }
  }

  Future<void> stopRecording() async {
    try {
      await _recorder.stop();
      _isRecording = false;
      
      if (_recordingPath != null) {
        _currentAudioPath = _recordingPath;
        await _loadAudio(_currentAudioPath!);
        await loadAudioFiles(); // Dosya listesini güncelle
      }
      
      notifyListeners();
    } catch (e) {
      print('Kayıt durdurma hatası: $e');
      rethrow;
    }
  }

  Future<void> pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['wav'], // Sadece WAV dosyalarını kabul et
      );
      
      if (result != null && result.files.single.path != null) {
        String selectedPath = result.files.single.path!;
        
        // İmport edilen dosyaları özel isimle kaydet
        final directory = await getApplicationDocumentsDirectory();
        final audioDir = Directory('${directory.path}/audio_recordings');
        if (!await audioDir.exists()) {
          await audioDir.create(recursive: true);
        }
        
        final originalFileName = result.files.single.name ?? 'imported';
        final nameWithoutExt = originalFileName.split('.').first;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final newPath = '${audioDir.path}/imported_${nameWithoutExt}_$timestamp.wav';
        
        // Dosyayı kopyala
        final originalFile = File(selectedPath);
        await originalFile.copy(newPath);
        
        _currentAudioPath = newPath;
        await _loadAudio(_currentAudioPath!);
        await loadAudioFiles(); // Listeyi güncelle
      }
    } catch (e) {
      print('Dosya seçme hatası: $e');
      rethrow;
    }
  }

  Future<void> _loadAudio(String path) async {
    try {
      await _player.setFilePath(path);
          notifyListeners();
    } catch (e) {
      print('Ses yükleme hatası: $e');
      rethrow;
    }
  }
  
  Future<void> playPause() async {
    try {
      if (_currentAudioPath == null) return;
      
      if (_isPlaying) {
        await _player.pause();
      } else {
      await _player.play();
      }
      notifyListeners();
    } catch (e) {
      print('Oynatma/Durdurma hatası: $e');
      rethrow;
  }
  }

  Future<void> seekTo(Duration position) async {
    try {
    await _player.seek(position);
      notifyListeners();
    } catch (e) {
      print('Atlama hatası: $e');
      rethrow;
    }
  }

  Future<void> loadAudioFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/audio_recordings');
      
      if (!await audioDir.exists()) {
        _audioFiles = [];
        notifyListeners();
        return;
      }

      final files = audioDir.listSync()
          .where((file) => file.path.toLowerCase().endsWith('.wav'))
          .map((file) {
        final stat = file.statSync();
          return AudioFile(
          path: file.path,
            name: file.path.split('/').last,
            size: stat.size,
            createdAt: stat.modified,
          );
      }).toList();

      files.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // En yeni önce
      _audioFiles = files;
      notifyListeners();
    } catch (e) {
      print('Dosya yükleme hatası: $e');
      _audioFiles = [];
      notifyListeners();
    }
  }

  Future<void> playAudio(String path) async {
    try {
      if (_currentlyPlayingPath == path && _isPlaying) {
        await _player.pause();
        _currentlyPlayingPath = null;
      } else {
        await _player.setFilePath(path);
        await _player.play();
        _currentlyPlayingPath = path;
      }
      notifyListeners();
    } catch (e) {
      print('Ses oynatma hatası: $e');
      rethrow;
        }
  }
  
  Future<void> pauseAudio() async {
    try {
      await _player.pause();
      _currentlyPlayingPath = null;
      notifyListeners();
    } catch (e) {
      print('Ses durdurma hatası: $e');
      rethrow;
    }
  }
  
  Future<void> stopAudio() async {
    try {
      await _player.stop();
      _currentlyPlayingPath = null;
      notifyListeners();
    } catch (e) {
      print('Ses durdurma hatası: $e');
      rethrow;
    }
  }

  Future<void> deleteAudioFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        await loadAudioFiles(); // Listeyi güncelle
      }
    } catch (e) {
      print('Dosya silme hatası: $e');
      rethrow;
    }
  }

  String get currentFileName {
    if (_currentAudioPath == null) return 'Dosya seçilmedi';
    
    String fileName = _currentAudioPath!.split('/').last;
    
    // "imported_" prefix'ini ve timestamp'i gizle
    if (fileName.startsWith('imported_')) {
      fileName = fileName.substring(9); // "imported_" prefix'ini kaldır
      // Timestamp'i de kaldır (son _ sonrası)
      final parts = fileName.split('_');
      if (parts.length > 1) {
        parts.removeLast(); // timestamp'i kaldır
        fileName = parts.join('_');
      }
    }
    
    return fileName;
  }
  
  String get fileInfo {
    if (_currentAudioPath == null) return '';
    
    try {
      final file = File(_currentAudioPath!);
      final bytes = file.lengthSync();
      
      String size;
      if (bytes < 1024) size = '${bytes}B';
      else if (bytes < 1024 * 1024) size = '${(bytes / 1024).toStringAsFixed(1)}KB';
      else size = '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
      
      final duration = _totalDuration.inSeconds > 0 
          ? '${(_totalDuration.inSeconds ~/ 60)}:${(_totalDuration.inSeconds % 60).toString().padLeft(2, '0')}'
          : '0:00';
      
      return '$size • $duration';
    } catch (e) {
      return '';
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }
}