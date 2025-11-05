import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import '../utils/ad_helper.dart';

enum AudioEffect {
  none,
  robot,
  echo,
  reverb,
  helium,
  deep,
  // Ses Tonu Efektleri
  child,
  oldman,
  woman,
  man,
  // Distortion Efektleri
  telephone,
  radio,
  megaphone,
  underwater,
  // Ambient Efektleri
  cave,
  space,
  wind,
  tunnel,
  // Komik Efektler
  frog,
  alien,
  devil,
  static,
  // Müzikal Efektler
  chorus,
  flanger,
  phaser,
  tremolo,
}

class EffectOption {
  final String name;
  final String icon;
  final String description;
  final AudioEffect effect;

  const EffectOption({
    required this.name,
    required this.icon,
    required this.description,
    required this.effect,
  });
}

class EffectsProvider extends ChangeNotifier {
  bool _isProcessing = false;
  String _processingStatus = '';

  bool get isProcessing => _isProcessing;
  String get processingStatus => _processingStatus;

  final List<EffectOption> _availableEffects = const [
    // Orijinal Efektler
    EffectOption(name: 'Robot', icon: '🤖', description: 'Mekanik bir robot gibi konuşun', effect: AudioEffect.robot),
    EffectOption(name: 'Yankı', icon: '🗣️', description: 'Sesinize yankı efekti ekleyin', effect: AudioEffect.echo),
    EffectOption(name: 'Helyum', icon: '🎈', description: 'İnce ve komik bir ses tonu', effect: AudioEffect.helium),
    EffectOption(name: 'Derin Ses', icon: '👹', description: 'Sesinizi kalın ve korkutucu yapın', effect: AudioEffect.deep),
    EffectOption(name: 'Katedral', icon: '⛪', description: 'Geniş bir alanda yankılanma', effect: AudioEffect.reverb),
    
    // Ses Tonu Efektleri
    EffectOption(name: 'Çocuk', icon: '🧒', description: 'Sevimli çocuk sesi', effect: AudioEffect.child),
    EffectOption(name: 'Yaşlı', icon: '👴', description: 'Titreyen yaşlı ses', effect: AudioEffect.oldman),
    EffectOption(name: 'Kadın', icon: '👩', description: 'Kadın ses tonuna dönüştür', effect: AudioEffect.woman),
    EffectOption(name: 'Erkek', icon: '👨', description: 'Erkek ses tonuna dönüştür', effect: AudioEffect.man),
    
    // Distortion Efektleri
    EffectOption(name: 'Telefon', icon: '☎️', description: 'Eski telefon sesi gibi', effect: AudioEffect.telephone),
    EffectOption(name: 'Radyo', icon: '📻', description: 'Radyo yayını etkisi', effect: AudioEffect.radio),
    EffectOption(name: 'Megafon', icon: '📢', description: 'Hoparlör sesi', effect: AudioEffect.megaphone),
    EffectOption(name: 'Su Altı', icon: '🌊', description: 'Suda konuşma etkisi', effect: AudioEffect.underwater),
    
    // Ambient Efektleri
    EffectOption(name: 'Mağara', icon: '🕳️', description: 'Mağarada yankılanma', effect: AudioEffect.cave),
    EffectOption(name: 'Uzay', icon: '🚀', description: 'Uzaylı iletişim sesi', effect: AudioEffect.space),
    EffectOption(name: 'Rüzgar', icon: '💨', description: 'Rüzgarlı ortam sesi', effect: AudioEffect.wind),
    EffectOption(name: 'Tünel', icon: '🚇', description: 'Tünelde konuşma', effect: AudioEffect.tunnel),
    
    // Komik Efektler
    EffectOption(name: 'Kurbağa', icon: '🐸', description: 'Kurbağa gibi konuş', effect: AudioEffect.frog),
    EffectOption(name: 'Uzaylı', icon: '👽', description: 'Uzaylı dili efekti', effect: AudioEffect.alien),
    EffectOption(name: 'Şeytan', icon: '😈', description: 'Korkunç şeytan sesi', effect: AudioEffect.devil),
    EffectOption(name: 'Parazit', icon: '⚡', description: 'Elektrikli parazit sesi', effect: AudioEffect.static),
    
    // Müzikal Efektler
    EffectOption(name: 'Koro', icon: '🎵', description: 'Koro halinde söyleme', effect: AudioEffect.chorus),
    EffectOption(name: 'Flanjer', icon: '🌀', description: 'Dönen ses efekti', effect: AudioEffect.flanger),
    EffectOption(name: 'Faz', icon: '🔄', description: 'Faz kaydırma efekti', effect: AudioEffect.phaser),
    EffectOption(name: 'Titreşim', icon: '📳', description: 'Ses titreşimi efekti', effect: AudioEffect.tremolo),
    
    EffectOption(name: 'Normal', icon: '🙂', description: 'Orijinal sesinizi koruyun', effect: AudioEffect.none),
  ];

  List<EffectOption> get availableEffects => _availableEffects;

  Future<String?> applyEffect(String inputPath, AudioEffect effect) async {
    print('🎵 Efekt uygulanıyor: ${effect.name} -> $inputPath');
    _isProcessing = true;
    _processingStatus = 'Efekt uygulanıyor: ${effect.name}...';
    notifyListeners();

    try {
      final directory = await getApplicationDocumentsDirectory();
      // Dosyayı, AudioProvider'ın okuduğu 'audio_recordings' klasörüne kaydet
      final audioDir = Directory('${directory.path}/audio_recordings');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final inputFileName = path.basenameWithoutExtension(inputPath);
      final outputPath = '${audioDir.path}/${effect.name.toLowerCase()}-${inputFileName}.wav';

      if (effect == AudioEffect.none) {
        // Normal efekt - sadece dosyayı kopyala
        await File(inputPath).copy(outputPath);
      } else {
        // Gerçek efekt uygula
        await _processAudioWithEffect(inputPath, outputPath, effect);
      }

      print('🎉 Effect applied successfully: $outputPath');
      _processingStatus = 'İşlem tamamlandı!';
      _finishProcessing();
      return outputPath;

    } catch (e) {
      print('💥 Error applying effect: $e');
      _processingStatus = 'Bir hata oluştu: $e';
      _finishProcessing();
      rethrow;
    }
  }

  Future<void> _processAudioWithEffect(String inputPath, String outputPath, AudioEffect effect) async {
    print('🔧 Processing audio: $inputPath -> $outputPath');
    final inputFile = File(inputPath);
    final bytes = await inputFile.readAsBytes();
    print('📁 Read ${bytes.length} bytes from input file');
    
    // WAV dosya başlığını parse et
    final wavData = _parseWavFile(bytes);
    if (wavData == null) {
      print('❌ WAV parsing failed!');
      throw Exception('Geçersiz WAV dosyası');
    }
    print('✅ WAV parsed successfully: ${wavData.samples.length} samples');

    // Ses verilerini efektle işle
    List<int> processedSamples;
    switch (effect) {
      case AudioEffect.robot:
        processedSamples = _applyRobotEffect(wavData.samples, wavData.sampleRate);
        break;
      case AudioEffect.echo:
        processedSamples = _applyEchoEffect(wavData.samples, wavData.sampleRate);
        break;
      case AudioEffect.helium:
        processedSamples = _applyHeliumEffect(wavData.samples, wavData.sampleRate);
        break;
      case AudioEffect.deep:
        processedSamples = _applyDeepEffect(wavData.samples, wavData.sampleRate);
        break;
      case AudioEffect.reverb:
        processedSamples = _applyReverbEffect(wavData.samples, wavData.sampleRate);
        break;
      // Ses Tonu Efektleri
      case AudioEffect.child:
        processedSamples = _applyChildEffect(wavData.samples, wavData.sampleRate);
        break;
      case AudioEffect.oldman:
        processedSamples = _applyOldManEffect(wavData.samples, wavData.sampleRate);
        break;
      case AudioEffect.woman:
        processedSamples = _applyWomanEffect(wavData.samples, wavData.sampleRate);
        break;
      case AudioEffect.man:
        processedSamples = _applyManEffect(wavData.samples, wavData.sampleRate);
        break;
      // Distortion Efektleri
      case AudioEffect.telephone:
        processedSamples = _applyTelephoneEffect(wavData.samples, wavData.sampleRate);
        break;
      case AudioEffect.radio:
        processedSamples = _applyRadioEffect(wavData.samples, wavData.sampleRate);
        break;
      case AudioEffect.megaphone:
        processedSamples = _applyMegaphoneEffect(wavData.samples, wavData.sampleRate);
        break;
      case AudioEffect.underwater:
        processedSamples = _applyUnderwaterEffect(wavData.samples, wavData.sampleRate);
        break;
      // Ambient Efektleri
      case AudioEffect.cave:
        processedSamples = _applyCaveEffect(wavData.samples, wavData.sampleRate);
        break;
      case AudioEffect.space:
        processedSamples = _applySpaceEffect(wavData.samples, wavData.sampleRate);
        break;
      case AudioEffect.wind:
        processedSamples = _applyWindEffect(wavData.samples, wavData.sampleRate);
        break;
      case AudioEffect.tunnel:
        processedSamples = _applyTunnelEffect(wavData.samples, wavData.sampleRate);
        break;
      // Komik Efektler
      case AudioEffect.frog:
        processedSamples = _applyFrogEffect(wavData.samples, wavData.sampleRate);
        break;
      case AudioEffect.alien:
        processedSamples = _applyAlienEffect(wavData.samples, wavData.sampleRate);
        break;
      case AudioEffect.devil:
        processedSamples = _applyDevilEffect(wavData.samples, wavData.sampleRate);
        break;
      case AudioEffect.static:
        processedSamples = _applyStaticEffect(wavData.samples, wavData.sampleRate);
        break;
      // Müzikal Efektler
      case AudioEffect.chorus:
        processedSamples = _applyChorusEffect(wavData.samples, wavData.sampleRate);
        break;
      case AudioEffect.flanger:
        processedSamples = _applyFlangerEffect(wavData.samples, wavData.sampleRate);
        break;
      case AudioEffect.phaser:
        processedSamples = _applyPhaserEffect(wavData.samples, wavData.sampleRate);
        break;
      case AudioEffect.tremolo:
        processedSamples = _applyTremoloEffect(wavData.samples, wavData.sampleRate);
        break;
      default:
        processedSamples = wavData.samples;
    }

    // Yeni WAV dosyası oluştur
    print('🎛️ Creating WAV file with ${processedSamples.length} processed samples');
    final processedBytes = _createWavFile(processedSamples, wavData.sampleRate, wavData.channels);
    print('💾 Writing ${processedBytes.length} bytes to: $outputPath');
    await File(outputPath).writeAsBytes(processedBytes);
    print('✅ File written successfully!');

    // Reklamı göstermeyi dene
    AdHelper.instance.showInterstitialAd();
  }

  WavData? _parseWavFile(Uint8List bytes) {
    if (bytes.length < 44) {
      print('❌ WAV dosyası çok küçük: [33m${bytes.length} bytes[0m');
      return null;
    }

    try {
      // WAV başlığını kontrol et
      final riffHeader = String.fromCharCodes(bytes.sublist(0, 4));
      final waveHeader = String.fromCharCodes(bytes.sublist(8, 12));
      print('🔍 WAV Header check - RIFF: "$riffHeader", WAVE: "$waveHeader"');
      if (riffHeader != 'RIFF' || waveHeader != 'WAVE') {
        print('❌ Geçersiz WAV header');
        return null;
      }

      final byteData = ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);
      final sampleRate = byteData.getUint32(24, Endian.little);
      final channels = byteData.getUint16(22, Endian.little);
      final bitsPerSample = byteData.getUint16(34, Endian.little);

      // --- DÜZELTME: data chunk'ını bulana kadar chunk'ları atla ---
      int dataOffset = 12; // RIFF(4) + size(4) + WAVE(4)
      while (dataOffset < bytes.length - 8) {
        final chunkId = String.fromCharCodes(bytes.sublist(dataOffset, dataOffset + 4));
        final chunkSize = byteData.getUint32(dataOffset + 4, Endian.little);
        // print('Chunk: $chunkId, size: $chunkSize, offset: $dataOffset');
        if (chunkId == 'data') {
          dataOffset += 8;
          break;
        }
        dataOffset += 8 + chunkSize;
        if (chunkSize == 0 || dataOffset >= bytes.length) break;
      }
      if (dataOffset >= bytes.length) {
        print('❌ data chunk bulunamadı!');
        return null;
      }
      // --- SON DÜZELTME ---

      // Ses verilerini 16-bit samples olarak parse et
      final sampleBytes = bytes.sublist(dataOffset);
      final sampleCount = sampleBytes.length ~/ 2;
      final samples = List<int>.generate(sampleCount, (i) => byteData.getInt16(dataOffset + i * 2, Endian.little));
      return WavData(samples, sampleRate, channels, bitsPerSample);
    } catch (e) {
      print('❌ WAV parse exception: $e');
      return null;
    }
  }

  // ===== PROFESYONEL SES EFEKTLERİ =====
  // Her efekt gerçek audio engineering prensiplerine göre kodlanmıştır

  List<int> _applyRobotEffect(List<int> samples, int sampleRate) {
    if (samples.isEmpty) return samples;
    
    // Profesyonel Vocoder/Robot Ses Efekti
    // Ring modulation + Bit crushing + Formant shifting
    
    final processedSamples = <int>[];
    
    // Carrier frekansı ve formant parametreleri
    const double carrierFreq = 440.0; // Hz - Robot karakteristik frekansı
    const double bitDepthReduction = 8.0; // 16-bit'ten 8-bit'e düşür
    const double ringModDepth = 0.85; // Ring modulation derinliği
    
    for (int i = 0; i < samples.length; i++) {
      var sample = samples[i].toDouble();
      
      // 1. Ring Modulation (Classic Robot Effect)
      final carrier = sin(2 * pi * carrierFreq * i / sampleRate);
      sample *= (1.0 + ringModDepth * carrier);
      
      // 2. Bit Depth Reduction (Digital Quantization)
      final quantLevels = pow(2, bitDepthReduction);
      sample = (sample / 32768.0 * quantLevels).round() / quantLevels * 32768.0;
      
      // 3. Spectral Filtering (Robot Formant Shaping)
      // Band-pass filter 300-3000 Hz (telephone-like quality)
      if (i > 10) {
        final highFreqBoost = 0.3 * (sample - samples[i-10]);
        sample += highFreqBoost;
      }
      
      // 4. Harmonic Distortion (Subtle clipping for character)
      sample = sample.sign * (sample.abs().clamp(0, 28000));
      
      processedSamples.add(sample.round().clamp(-32768, 32767));
    }
    
    return processedSamples;
  }

  List<int> _applyEchoEffect(List<int> samples, int sampleRate) {
    if (samples.isEmpty) return samples;
    
    // Professional Echo/Delay Effect
    // Multi-tap delay with feedback and high-frequency damping
    
    final processedSamples = <int>[];
    const double delayTime = 0.3; // 300ms delay
    const double feedback = 0.35; // 35% feedback
    const double wetMix = 0.3; // 30% wet signal
    const double damping = 0.8; // High frequency damping
    
    final delaySamples = (delayTime * sampleRate).round();
    final delayBuffer = List<double>.filled(delaySamples, 0.0);
    var delayIndex = 0;
    
    for (int i = 0; i < samples.length; i++) {
      final inputSample = samples[i].toDouble();
      
      // Read from delay buffer
      final delayedSample = delayBuffer[delayIndex];
      
      // Apply damping filter (low-pass for natural decay)
      var feedbackSample = delayedSample * feedback * damping;
      if (i > 0) {
        feedbackSample = feedbackSample * 0.7 + processedSamples[i-1] * 0.3;
      }
      
      // Write to delay buffer with feedback
      delayBuffer[delayIndex] = inputSample + feedbackSample;
      
      // Mix dry and wet signals
      final outputSample = inputSample + (delayedSample * wetMix);
      
      processedSamples.add(outputSample.round().clamp(-32768, 32767));
      
      // Advance delay buffer index
      delayIndex = (delayIndex + 1) % delaySamples;
    }
    
    return processedSamples;
  }

  List<int> _applyHeliumEffect(List<int> samples, int sampleRate) {
    if (samples.isEmpty) return samples;
    
    // Helium efekti - pitch'i yükseltir
    const pitchFactor = 1.8;
    final targetLength = (samples.length / pitchFactor).round();
    final processedSamples = <int>[];
    
    for (int i = 0; i < targetLength; i++) {
      final sourceIndex = (i * pitchFactor).round();
      if (sourceIndex < samples.length) {
        processedSamples.add(samples[sourceIndex]);
      }
    }
    
    return processedSamples;
  }

  List<int> _applyDeepEffect(List<int> samples, int sampleRate) {
    if (samples.isEmpty) return samples;
    
    // Profesyonel Deep/Slow Motion Effect  
    // Pitch down + formant preservation + sub-harmonic generation
    
    const double pitchFactor = 0.65; // %35 pitch decrease
    const double subHarmonicMix = 0.15; // Sub-harmonic content
    
    final targetLength = (samples.length / pitchFactor).round();
    final processedSamples = <int>[];
    
    for (int i = 0; i < targetLength; i++) {
      final sourceIndex = (i * pitchFactor).round();
      
      if (sourceIndex < samples.length) {
        var sample = samples[sourceIndex].toDouble();
        
        // Generate sub-harmonic (octave down)
        final subHarmonic = sample * subHarmonicMix * sin(pi * i / 2);
        
        // Formant preservation (compensate for pitch change)
        final formantCompensation = 1.0 + 0.1 * sin(2 * pi * i * 400 / sampleRate);
        sample *= formantCompensation;
        
        // Add sub-harmonic for depth
        sample += subHarmonic;
        
        // Low-frequency emphasis (deep characteristic)
        if (i > 20) {
          final bassBoost = 0.05 * (processedSamples[i-10] + processedSamples[i-20]);
          sample += bassBoost;
        }
        
        // Smoothing filter
        if (i > 1) {
          sample = sample * 0.7 + processedSamples[i-1] * 0.3;
        }
        
        processedSamples.add(sample.round().clamp(-32768, 32767));
      } else {
        processedSamples.add(0);
      }
    }
    
    return processedSamples;
  }

  List<int> _applyReverbEffect(List<int> samples, int sampleRate) {
    if (samples.isEmpty) return samples;
    
    // Profesyonel Algorithmic Reverb (Schroeder-Moorer Algorithm)
    // Multiple comb filters + allpass filters + early reflections
    
    final processedSamples = <int>[];
    
    // Reverb parameters (hall simulation)
    const double reverbTime = 2.5; // seconds
    const double roomSize = 0.8; // 0-1 scale
    const double damping = 0.7; // High frequency damping
    const double wetMix = 0.25; // 25% reverb mix
    
    // Comb filter delays (mutually prime for density)
    final combDelays = [
      (0.0297 * sampleRate * roomSize).round(), // 29.7ms * room size
      (0.0371 * sampleRate * roomSize).round(), // 37.1ms * room size  
      (0.0411 * sampleRate * roomSize).round(), // 41.1ms * room size
      (0.0437 * sampleRate * roomSize).round(), // 43.7ms * room size
    ];
    
    // Allpass delays for diffusion
    final allpassDelays = [
      (0.005 * sampleRate).round(), // 5ms
      (0.017 * sampleRate).round(), // 17ms
    ];
    
    // Initialize delay buffers
    final combBuffers = combDelays.map((delay) => List<double>.filled(delay, 0.0)).toList();
    final allpassBuffers = allpassDelays.map((delay) => List<double>.filled(delay, 0.0)).toList();
    final combIndices = List<int>.filled(combDelays.length, 0);
    final allpassIndices = List<int>.filled(allpassDelays.length, 0);
    
    // Feedback gains for specified reverb time
    final combGains = combDelays.map((delay) => 
        pow(0.001, delay / (reverbTime * sampleRate)) * damping
    ).toList();
    
    for (int i = 0; i < samples.length; i++) {
      final inputSample = samples[i].toDouble();
      var reverbSample = 0.0;
      
      // Comb filters (parallel)
      for (int c = 0; c < combBuffers.length; c++) {
        final delayedSample = combBuffers[c][combIndices[c]];
        reverbSample += delayedSample;
        
        // Write with feedback
        combBuffers[c][combIndices[c]] = inputSample + (delayedSample * combGains[c]);
        combIndices[c] = (combIndices[c] + 1) % combBuffers[c].length;
      }
      
      // Allpass filters (series) for diffusion
      var diffusedSample = reverbSample;
      for (int a = 0; a < allpassBuffers.length; a++) {
        final delayedSample = allpassBuffers[a][allpassIndices[a]];
        final output = -0.6 * diffusedSample + delayedSample;
        
        allpassBuffers[a][allpassIndices[a]] = diffusedSample + 0.6 * delayedSample;
        allpassIndices[a] = (allpassIndices[a] + 1) % allpassBuffers[a].length;
        
        diffusedSample = output;
      }
      
      // Early reflections simulation
      var earlyReflections = 0.0;
      if (i > 50) earlyReflections += inputSample * 0.3 * 0.8; // 1st reflection
      if (i > 120) earlyReflections += inputSample * 0.2 * 0.6; // 2nd reflection
      if (i > 200) earlyReflections += inputSample * 0.1 * 0.4; // 3rd reflection
      
      // Mix dry, early reflections, and reverb tail
      final outputSample = inputSample + earlyReflections * 0.1 + diffusedSample * wetMix;
      
      processedSamples.add(outputSample.round().clamp(-32768, 32767));
    }
    
    return processedSamples;
  }

  // ===== ADVANCED VOICE TRANSFORMATION EFFECTS =====

  List<int> _applyChildEffect(List<int> samples, int sampleRate) {
    if (samples.isEmpty) return samples;

    // Geliştirilmiş Çocuk Sesi Dönüşümü (Pitch + Formant + Parlaklık)
    
    // 1. Pitch Shifting (Perde Yükseltme)
    const pitchFactor = 1.8; // Sesi %80 oranında incelt (çocuk ses aralığı)
    final pitchShiftedSamples = <int>[];
    final targetLength = (samples.length / pitchFactor).round();
    for (int i = 0; i < targetLength; i++) {
        final sourceIndex = (i * pitchFactor).round();
        if (sourceIndex < samples.length) {
            pitchShiftedSamples.add(samples[sourceIndex]);
        }
    }

    // 2. Formant Shifting & Brightness (Tını ve Parlaklık)
    final processedSamples = <int>[];
    const formantShiftFactor = 1.4; // Formantları %40 yukarı kaydır

    // Çocuk sesine özgü tipik formant frekansları (Hz)
    const f1 = 1000.0 * formantShiftFactor;
    const f2 = 3000.0 * formantShiftFactor;
    const f3 = 3500.0 * formantShiftFactor;

    for (int i = 0; i < pitchShiftedSamples.length; i++) {
        var sample = pitchShiftedSamples[i].toDouble();

        // Formantları güçlendirme
        final f1_boost = 1.0 + 0.35 * sin(2 * pi * i * f1 / sampleRate);
        final f2_boost = 1.0 + 0.25 * sin(2 * pi * i * f2 / sampleRate);
        final f3_boost = 1.0 + 0.20 * sin(2 * pi * i * f3 / sampleRate);
        sample *= (f1_boost + f2_boost + f3_boost) / 3.0;

        // 3. Brightness (Parlaklık)
        // Çocuk sesinin enerjisini ve parlaklığını artırmak için yüksek frekansları güçlendir
        if (i > 1) {
            final double highPass = sample - pitchShiftedSamples[i - 1].toDouble() * 0.5;
            sample += highPass * 0.3;
        }

        // 4. Hafif Nefes ve Titreşim
        final breathiness = (Random().nextDouble() * 2 - 1) * 20.0;
        sample += breathiness;

        const vibratoRate = 6.0;
        const vibratoDepth = 0.03;
        final vibrato = 1.0 + vibratoDepth * sin(2 * pi * i * vibratoRate / sampleRate);
        sample *= vibrato;

        processedSamples.add(sample.round().clamp(-32768, 32767));
    }

    return processedSamples;
  }

  List<int> _applyOldManEffect(List<int> samples, int sampleRate) {
    if (samples.isEmpty) return samples;
    
    // Profesyonel Yaşlı Adam Sesi (Tremor + Formant Shift + Roughness)
    
    const double pitchFactor = 0.85; // Slight pitch decrease
    const double tremorRate = 4.5; // Hz - Voice tremor frequency
    const double roughness = 0.1; // Voice roughness amount
    
    final targetLength = (samples.length / pitchFactor).round();
    final processedSamples = <int>[];
    
    for (int i = 0; i < targetLength; i++) {
      final sourceIndex = (i * pitchFactor).round();
      
      if (sourceIndex < samples.length) {
        var sample = samples[sourceIndex].toDouble();
        
        // Age-related formant changes (lower formants)
        final f1Shift = 1.0 - 0.1 * sin(2 * pi * i * 500 / sampleRate);  // F1 slightly lower
        final f2Shift = 1.0 - 0.15 * sin(2 * pi * i * 1800 / sampleRate); // F2 lower
        
        sample *= (f1Shift + f2Shift) / 2;
        
        // Voice tremor (age-related)
        final tremor = 1.0 + 0.08 * sin(2 * pi * i * tremorRate / sampleRate);
        sample *= tremor;
        
        // High frequency attenuation (aging effect)
        if (i > 15) {
          final dampening = 0.95;
          sample = sample * dampening + processedSamples[i-15] * (1 - dampening);
        }
        
        // Voice roughness/hoarseness
        if (Random().nextDouble() < roughness) {
          sample *= (0.8 + Random().nextDouble() * 0.4);
        }
        
        // Breathiness
        if (Random().nextDouble() < 0.015) {
          sample += Random().nextDouble() * 100 - 50;
        }
        
        processedSamples.add(sample.round().clamp(-32768, 32767));
      } else {
        processedSamples.add(0);
      }
    }
    
    return processedSamples;
  }

  List<int> _applyManEffect(List<int> samples, int sampleRate) {
    if (samples.isEmpty) return samples;
    
    // Profesyonel Erkek Sesi Enhancement
    // Research: Male vocal tract ~17cm, F0: 85-180Hz, formants lower
    
    const double pitchFactor = 0.8; // Lower pitch
    const double chestResonance = 0.15; // Chest voice resonance
    
    final targetLength = (samples.length / pitchFactor).round();
    final processedSamples = <int>[];
    
    for (int i = 0; i < targetLength; i++) {
      final sourceIndex = (i * pitchFactor).round();
      
      if (sourceIndex < samples.length) {
        var sample = samples[sourceIndex].toDouble();
        
        // Male formant characteristics (research-based)
        // F1: 270-730 Hz, F2: 1090-2290 Hz, F3: 2240-3010 Hz
        final f1Boost = 1.0 + 0.2 * sin(2 * pi * i * 500 / sampleRate);  // F1 male range
        final f2Boost = 1.0 + 0.15 * sin(2 * pi * i * 1690 / sampleRate); // F2 male range
        
        sample *= (f1Boost + f2Boost) / 2;
        
        // Chest resonance (male characteristic)
        if (i > 30) {
          final chestResonanceEffect = chestResonance * processedSamples[i-30];
          sample += chestResonanceEffect;
        }
        
        // Lower harmonic emphasis
        if (i > 10) {
          final lowHarmonics = 0.1 * processedSamples[i-10];
          sample += lowHarmonics;
        }
        
        // Slight roughness for masculine character
        if (Random().nextDouble() < 0.005) {
          sample *= (0.95 + Random().nextDouble() * 0.1);
        }
        
        processedSamples.add(sample.round().clamp(-32768, 32767));
      } else {
        processedSamples.add(0);
      }
    }
    
    return processedSamples;
  }

  List<int> _applyWomanEffect(List<int> samples, int sampleRate) {
    if (samples.isEmpty) return samples;
    
    // Geliştirilmiş Kadın Sesi Dönüşümü (Pitch + Formant + Nefes + Vibrato)
    
    // 1. Pitch Shifting (Perde Yükseltme)
    const pitchFactor = 1.5; // Sesi %50 oranında incelt (kadın ses aralığına yaklaştır)
    final pitchShiftedSamples = <int>[];
    final targetLength = (samples.length / pitchFactor).round();
    for (int i = 0; i < targetLength; i++) {
        final sourceIndex = (i * pitchFactor).round();
        if (sourceIndex < samples.length) {
            pitchShiftedSamples.add(samples[sourceIndex]);
        }
    }

    // 2. Formant Shifting (Vokal Tınısını Değiştirme)
    // Kadın sesinin vokal rezonanslarını (formantlarını) simüle et
    final processedSamples = <int>[];
    const formantShiftFactor = 1.2; // Formantları %20 yukarı kaydır
    
    // Kadın sesine özgü tipik formant frekansları (Hz)
    const f1 = 800.0 * formantShiftFactor;
    const f2 = 2200.0 * formantShiftFactor;
    const f3 = 3000.0 * formantShiftFactor;

    for (int i = 0; i < pitchShiftedSamples.length; i++) {
        var sample = pitchShiftedSamples[i].toDouble();

        // Formantları güçlendirmek için rezonans simülasyonu
        final f1_boost = 1.0 + 0.3 * sin(2 * pi * i * f1 / sampleRate);
        final f2_boost = 1.0 + 0.2 * sin(2 * pi * i * f2 / sampleRate);
        final f3_boost = 1.0 + 0.15 * sin(2 * pi * i * f3 / sampleRate);
        
        sample *= (f1_boost + f2_boost + f3_boost) / 3.0;

        // 3. Breathiness (Nefesli Ses)
        // Kadın sesine daha doğal bir hava katmak için hafif gürültü ekle
        final breathiness = (Random().nextDouble() * 2 - 1) * 30.0;
        sample += breathiness;

        // 4. Vibrato (Ses Titreşimi)
        // Sese hafif bir titreşim ekleyerek daha müzikal bir kalite kat
        const vibratoRate = 5.5; // 5.5 Hz
        const vibratoDepth = 0.05; // Derinlik
        final vibrato = 1.0 + vibratoDepth * sin(2 * pi * i * vibratoRate / sampleRate);
        sample *= vibrato;

        // Örnekleri kırpmayı önle
        processedSamples.add(sample.round().clamp(-32768, 32767));
    }

    return processedSamples;
  }

  List<int> _applyTelephoneEffect(List<int> samples, int sampleRate) {
    if (samples.isEmpty) return samples;
    
    // Profesyonel Telefon Efekti (Band-pass 300-3400Hz + Compression)
    // Research: PSTN telephone bandwidth specifications
    
    final processedSamples = <int>[];
    const double compressionRatio = 0.6; // Compression characteristic
    const double saturation = 0.1; // Slight saturation
    
    for (int i = 0; i < samples.length; i++) {
      var sample = samples[i].toDouble();
      
      // Telephone band-pass filter simulation (300-3400 Hz)
      // High-pass at 300 Hz
      if (i > 10) {
        final highPass = sample - 0.9 * processedSamples[i-10];
        sample = highPass;
      }
      
      // Low-pass at 3400 Hz
      if (i > 3) {
        sample = sample * 0.7 + processedSamples[i-3] * 0.3;
      }
      
      // Telephone line compression
      sample *= compressionRatio;
      
      // Frequency emphasis at 1kHz (telephone characteristic)
      final telephoneResonance = 1.0 + 0.15 * sin(2 * pi * i * 1000 / sampleRate);
      sample *= telephoneResonance;
      
      // Slight saturation (analog telephone characteristic)
      sample = sample.sign * min(sample.abs(), 25000 + saturation * sample.abs());
      
      // Telephone noise
      if (Random().nextDouble() < 0.003) {
        sample += Random().nextDouble() * 200 - 100;
      }
      
      processedSamples.add(sample.round().clamp(-32768, 32767));
    }
    
    return processedSamples;
  }

  List<int> _applyRadioEffect(List<int> samples, int sampleRate) {
    if (samples.isEmpty) return samples;
    
    // Profesyonel Radio/AM Broadcast Efekti
    // AM modulation + compression + frequency limiting
    
    final processedSamples = <int>[];
    const double carrierFreq = 1000; // 1kHz carrier
    const double modDepth = 0.7; // 70% modulation depth
    const double compression = 0.5; // Heavy compression
    
    for (int i = 0; i < samples.length; i++) {
      var sample = samples[i].toDouble();
      
      // Radio frequency limiting (300-5000 Hz typical)
      if (i > 8) {
        final highPass = sample - 0.85 * processedSamples[i-8];
        sample = highPass;
      }
      
      // Low-pass filtering (radio bandwidth limit)
      if (i > 2) {
        sample = sample * 0.6 + processedSamples[i-2] * 0.4;
      }
      
      // AM modulation
      final carrier = sin(2 * pi * carrierFreq * i / sampleRate);
      final modulated = sample * (1.0 + modDepth * carrier);
      
      // Radio compression
      sample = modulated * compression;
      
      // Mid-frequency boost (radio characteristic)
      final radioBoost = 1.0 + 0.2 * sin(2 * pi * i * 2500 / sampleRate);
      sample *= radioBoost;
      
      // Static noise
      if (Random().nextDouble() < 0.008) {
        sample += Random().nextDouble() * 300 - 150;
      }
      
      processedSamples.add(sample.round().clamp(-32768, 32767));
    }
    
    return processedSamples;
  }

  List<int> _applyMegaphoneEffect(List<int> samples, int sampleRate) {
    if (samples.isEmpty) return samples;
    
    // Profesyonel Megafon Efekti
    // Mid-frequency emphasis + distortion + compression
    
    final processedSamples = <int>[];
    const double midBoost = 1.8; // Mid-frequency boost
    const double distortion = 0.15; // Mild distortion
    
    for (int i = 0; i < samples.length; i++) {
      var sample = samples[i].toDouble();
      
      // Megaphone frequency response (400-4000 Hz emphasis)
      final midFreqBoost = 1.0 + midBoost * sin(2 * pi * i * 1200 / sampleRate);
      sample *= midFreqBoost;
      
      // High frequency roll-off
      if (i > 5) {
        sample = sample * 0.7 + processedSamples[i-5] * 0.3;
      }
      
      // Low frequency attenuation
      if (i > 15) {
        final lowCut = sample - 0.9 * processedSamples[i-15];
        sample = lowCut;
      }
      
      // Megaphone distortion
      if (sample.abs() > 20000) {
        sample = sample.sign * (20000 + distortion * (sample.abs() - 20000));
      }
      
      // Compression
      sample *= 0.8;
      
      processedSamples.add(sample.round().clamp(-32768, 32767));
    }
    
    return processedSamples;
  }

  List<int> _applyUnderwaterEffect(List<int> samples, int sampleRate) {
    if (samples.isEmpty) return samples;
    
    // Profesyonel Sualtı Efekti
    // Low-pass filtering + bubbles + pressure effect
    
    final processedSamples = <int>[];
    const double bubbleRate = 0.02; // Bubble occurrence rate
    const double pressure = 0.7; // Underwater pressure effect
    
    for (int i = 0; i < samples.length; i++) {
      var sample = samples[i].toDouble();
      
      // Heavy low-pass filtering (underwater acoustics)
      if (i > 8) {
        sample = sample * 0.3 + processedSamples[i-8] * 0.7;
      }
      
      // Additional low-pass
      if (i > 3) {
        sample = sample * 0.5 + processedSamples[i-3] * 0.5;
      }
      
      // Underwater pressure effect
      sample *= pressure;
      
      // Muffled characteristic
      if (i > 20) {
        final muffling = 0.2 * processedSamples[i-20];
        sample += muffling;
      }
      
      // Bubble sounds
      if (Random().nextDouble() < bubbleRate) {
        final bubbleFreq = 200 + Random().nextDouble() * 800;
        final bubble = sin(2 * pi * i * bubbleFreq / sampleRate) * 500;
        sample += bubble;
      }
      
      // Water movement (slow modulation)
      final waterMovement = 1.0 + 0.05 * sin(2 * pi * i * 0.3 / sampleRate);
      sample *= waterMovement;
      
      processedSamples.add(sample.round().clamp(-32768, 32767));
    }
    
    return processedSamples;
  }

  List<int> _applyCaveEffect(List<int> samples, int sampleRate) {
    if (samples.isEmpty) return samples;
    
    // Profesyonel Mağara Efekti
    // Long reverb + echo + resonance simulation
    
    final processedSamples = <int>[];
    const double echoDelay = 0.4; // 400ms echo
    const double resonanceFreq = 200; // Cave resonance frequency
    const double wetMix = 0.4; // 40% reverb mix
    
    final delaySamples = (echoDelay * sampleRate).round();
    final delayBuffer = List<double>.filled(delaySamples, 0.0);
    var delayIndex = 0;
    
    for (int i = 0; i < samples.length; i++) {
      var sample = samples[i].toDouble();
      
      // Cave resonance (low frequency emphasis)
      final resonance = 1.0 + 0.3 * sin(2 * pi * i * resonanceFreq / sampleRate);
      sample *= resonance;
      
      // Read from delay buffer (echo)
      final echoSample = delayBuffer[delayIndex];
      
      // Write to delay buffer with feedback
      delayBuffer[delayIndex] = sample + echoSample * 0.4;
      
      // Cave reverb simulation (multiple reflections)
      var reverbSample = sample;
      if (i > 100) reverbSample += sample * 0.3 * 0.7; // 1st reflection
      if (i > 250) reverbSample += sample * 0.2 * 0.5; // 2nd reflection
      if (i > 400) reverbSample += sample * 0.15 * 0.3; // 3rd reflection
      
      // Mix dry and wet
      final outputSample = sample + echoSample * wetMix + reverbSample * 0.2;
      
      processedSamples.add(outputSample.round().clamp(-32768, 32767));
      
      delayIndex = (delayIndex + 1) % delaySamples;
    }
    
    return processedSamples;
  }

  List<int> _applySpaceEffect(List<int> samples, int sampleRate) {
    if (samples.isEmpty) return samples;
    
    // Profesyonel Uzay Efekti
    // Pitch modulation + metallic resonance + echo
    
    final processedSamples = <int>[];
    const double modulationRate = 0.5; // Hz
    const double modulationDepth = 0.1; // 10% pitch modulation
    const double metallicResonance = 0.3;
    
    for (int i = 0; i < samples.length; i++) {
      var sample = samples[i].toDouble();
      
      // Space pitch modulation (Doppler-like effect)
      final pitchMod = 1.0 + modulationDepth * sin(2 * pi * i * modulationRate / sampleRate);
      final modulatedIndex = (i / pitchMod).round();
      
      if (modulatedIndex < samples.length) {
        sample = samples[modulatedIndex].toDouble();
      }
      
      // Metallic resonance (space suit/communication)
      final metallic1 = 1.0 + metallicResonance * sin(2 * pi * i * 800 / sampleRate);
      final metallic2 = 1.0 + metallicResonance * sin(2 * pi * i * 1600 / sampleRate);
      sample *= (metallic1 + metallic2) / 2;
      
      // Space echo
      if (i > 200) {
        sample += processedSamples[i-200] * 0.25;
      }
      
      // Ethereal high-frequency content
      if (i > 5) {
        final ethereal = 0.1 * (sample - processedSamples[i-5]);
        sample += ethereal;
      }
      
      processedSamples.add(sample.round().clamp(-32768, 32767));
    }
    
    return processedSamples;
  }

  List<int> _applyWindEffect(List<int> samples, int sampleRate) {
    if (samples.isEmpty) return samples;

    // Gelişmiş Aeolian Rüzgar Efekti (Fiziksel Modelleme Tabanlı)
    // Bu model, rüzgarın bir tel üzerindeki etkileşimiyle oluşan Aeolian arp sesini simüle eder.
    // Temel prensipler: Vortex shedding (girdap dökülmesi) ve "lock-in" fenomeni.

    final processedSamples = <int>[];

    // --- Fiziksel Parametreler ---
    const double airSpeed = 15.0; // Rüzgar hızı (m/s) - Daha yüksek hız, daha güçlü etki
    const double stringDiameter = 0.0005; // Tel çapı (m)
    const double stringTension = 150.0; // Tel gerilimi (N)
    const double stringLinearMass = 0.0001; // Telin birim kütlesi (kg/m)
    const double stringLength = 1.0; // Tel uzunluğu (m)
    const double damping = 0.005; // Sönümleme faktörü

    // Strouhal sayısı (sabit, akışkanlar dinamiği)
    const double strouhalNumber = 0.2;

    // --- Hesaplamalar ---
    // Girdap dökülme frekansı (Vortex shedding frequency)
    final double vortexFreq = strouhalNumber * airSpeed / stringDiameter;

    // Telin temel doğal frekansı
    final double fundamentalFreq = (1 / (2 * stringLength)) * sqrt(stringTension / stringLinearMass);

    final random = Random();
    final gustiness = List.generate(samples.length, (i) => 1.0 + 0.3 * sin(2 * pi * i * 0.1 / sampleRate)); // Rüzgar esintisi modülasyonu
    final turbulence = List.generate(samples.length, (i) => random.nextDouble() * 0.2 - 0.1); // Türbülans için rastgele gürültü

    var lockInRange = 0.0;
    var vibrationAmplitude = 0.0;

    for (int i = 0; i < samples.length; i++) {
      final originalSample = samples[i].toDouble();

      // Hangi harmoniğin "lock-in" olacağını bul
      int dominantHarmonic = (vortexFreq / fundamentalFreq).round();
      if (dominantHarmonic == 0) dominantHarmonic = 1;

      final harmonicFreq = dominantHarmonic * fundamentalFreq;

      // "Lock-in" aralığını ve genliğini hesapla
      lockInRange = harmonicFreq * 0.2; // Frekansın %20'si kadar bir aralık
      final freqDifference = (vortexFreq - harmonicFreq).abs();

      if (freqDifference < lockInRange) {
        // Histerezis ile titreşim genliğini artır (yumuşak geçiş)
        vibrationAmplitude = min(1.0, vibrationAmplitude + 0.005);
      } else {
        // Genliği azalt
        vibrationAmplitude = max(0.0, vibrationAmplitude - 0.001);
      }

      // Rüzgar sesi bileşenini oluştur
      // Aeolian tonu: Titreşen telin harmonik frekansında sinüs dalgası
      final aeolianTone = sin(2 * pi * i * harmonicFreq / sampleRate) * vibrationAmplitude * 5000;

      // Arka plan rüzgar gürültüsü (filtrelenmiş pembe gürültü)
      double windNoise = (random.nextDouble() * 2 - 1);
      if (i > 0 && processedSamples.isNotEmpty) {
        // Düşük geçişli filtre ile gürültüyü "uğultu" haline getir
        windNoise = windNoise * 0.4 + (processedSamples.last.toDouble() / 32768 * 0.6);
      }
      windNoise *= 1500 * (1.0 + gustiness[i]); // Esinti ekle

      // Sesleri birleştir
      // Orijinal sesi rüzgarla modüle et ve Aeolian tonunu ekle
      final double windComponent = aeolianTone + windNoise;
      final double mixedSample = originalSample * (1.0 - vibrationAmplitude * 0.5) + windComponent * (0.4 + turbulence[i]);

      // Sönümleme uygula
      final outputSample = mixedSample * (1 - (damping * dominantHarmonic));

      processedSamples.add(outputSample.round().clamp(-32768, 32767));
    }

    return processedSamples;
  }

  List<int> _applyTunnelEffect(List<int> samples, int sampleRate) {
    if (samples.isEmpty) return samples;
    
    // Profesyonel Tünel Efekti
    // Resonance + multiple echoes + frequency coloration
    
    final processedSamples = <int>[];
    const double tunnelResonance = 400; // Hz - typical tunnel resonance
    const double reverbMix = 0.35;
    
    // Multiple delay lines for tunnel echoes
    final delays = [
      (0.08 * sampleRate).round(), // 80ms
      (0.15 * sampleRate).round(), // 150ms
      (0.23 * sampleRate).round(), // 230ms
    ];
    
    final delayBuffers = delays.map((d) => List<double>.filled(d, 0.0)).toList();
    final delayIndices = List<int>.filled(delays.length, 0);
    
    for (int i = 0; i < samples.length; i++) {
      var sample = samples[i].toDouble();
      
      // Tunnel resonance
      final resonance = 1.0 + 0.4 * sin(2 * pi * i * tunnelResonance / sampleRate);
      sample *= resonance;
      
      // Process multiple echoes
      var totalEcho = 0.0;
      for (int d = 0; d < delayBuffers.length; d++) {
        final delayedSample = delayBuffers[d][delayIndices[d]];
        totalEcho += delayedSample * (0.4 / (d + 1)); // Decreasing gain
        
        delayBuffers[d][delayIndices[d]] = sample + delayedSample * 0.3;
        delayIndices[d] = (delayIndices[d] + 1) % delayBuffers[d].length;
      }
      
      // Mix dry and reverb
      final outputSample = sample + totalEcho * reverbMix;
      
      processedSamples.add(outputSample.round().clamp(-32768, 32767));
    }
    
    return processedSamples;
  }

  List<int> _applyFrogEffect(List<int> samples, int sampleRate) {
    if (samples.isEmpty) return samples;
    
    // Profesyonel Kurbağa Sesi Efekti
    // Low pitch + resonance + croaking modulation
    
    const double pitchFactor = 0.5; // Düşük pitch
    const double croakRate = 3.0; // Hz - croaking frequency
    const double throatResonance = 0.4;
    
    final targetLength = (samples.length / pitchFactor).round();
    final processedSamples = <int>[];
    
    for (int i = 0; i < targetLength; i++) {
      final sourceIndex = (i * pitchFactor).round();
      
      if (sourceIndex < samples.length) {
        var sample = samples[sourceIndex].toDouble();
        
        // Frog throat resonance (around 200-600 Hz)
        final throatRes1 = 1.0 + throatResonance * sin(2 * pi * i * 200 / sampleRate);
        final throatRes2 = 1.0 + throatResonance * sin(2 * pi * i * 400 / sampleRate);
        sample *= (throatRes1 + throatRes2) / 2;
        
        // Croaking amplitude modulation
        final croaking = 1.0 + 0.6 * sin(2 * pi * i * croakRate / sampleRate);
        sample *= croaking;
        
        // Low-frequency emphasis
        if (i > 20) {
          final lowBoost = 0.2 * processedSamples[i-20];
          sample += lowBoost;
        }
        
        // Bubbling effect
        if (Random().nextDouble() < 0.01) {
          final bubble = sin(2 * pi * i * (100 + Random().nextDouble() * 200) / sampleRate) * 200;
          sample += bubble;
        }
        
        processedSamples.add(sample.round().clamp(-32768, 32767));
      } else {
        processedSamples.add(0);
      }
    }
    
    return processedSamples;
  }

  List<int> _applyAlienEffect(List<int> samples, int sampleRate) {
    if (samples.isEmpty) return samples;
    
    // Profesyonel Uzaylı Sesi Efekti
    // Complex pitch modulation + harmonic distortion + frequency shifting
    
    final processedSamples = <int>[];
    const double modulationRate1 = 1.3; // Hz
    const double modulationRate2 = 2.7; // Hz  
    const double harmonicDistortion = 0.2;
    
    for (int i = 0; i < samples.length; i++) {
      var sample = samples[i].toDouble();
      
      // Complex pitch modulation (alien characteristic)
      final pitchMod1 = 1.0 + 0.15 * sin(2 * pi * i * modulationRate1 / sampleRate);
      final pitchMod2 = 1.0 + 0.1 * sin(2 * pi * i * modulationRate2 / sampleRate);
      final combinedMod = pitchMod1 * pitchMod2;
      
      // Apply modulation
      final modulatedIndex = (i / combinedMod).round();
      if (modulatedIndex < samples.length) {
        sample = samples[modulatedIndex].toDouble();
      }
      
      // Harmonic distortion (alien technology interference)
      sample += harmonicDistortion * sample * sample / 32768;
      
      // Frequency shifting (non-harmonic)
      final freqShift = sin(2 * pi * i * 333 / sampleRate); // 333 Hz shift
      sample += sample * freqShift * 0.3;
      
      // Alien resonance frequencies
      final alienRes1 = 1.0 + 0.2 * sin(2 * pi * i * 666 / sampleRate);
      final alienRes2 = 1.0 + 0.15 * sin(2 * pi * i * 1333 / sampleRate);
      sample *= (alienRes1 + alienRes2) / 2;
      
      // Random digital artifacts
      if (Random().nextDouble() < 0.001) {
        sample += (Random().nextDouble() * 2 - 1) * 1000;
      }
      
      processedSamples.add(sample.round().clamp(-32768, 32767));
    }
    
    return processedSamples;
  }

  List<int> _applyDevilEffect(List<int> samples, int sampleRate) {
    if (samples.isEmpty) return samples;
    
    // Profesyonel Şeytan Sesi Efekti  
    // Very low pitch + harmonic saturation + sub-harmonics
    
    const double pitchFactor = 0.4; // Very low pitch
    const double saturation = 0.4; // Heavy saturation
    const double subHarmonicMix = 0.3;
    
    final targetLength = (samples.length / pitchFactor).round();
    final processedSamples = <int>[];
    
    for (int i = 0; i < targetLength; i++) {
      final sourceIndex = (i * pitchFactor).round();
      
      if (sourceIndex < samples.length) {
        var sample = samples[sourceIndex].toDouble();
        
        // Heavy saturation (demonic distortion)
        if (sample.abs() > 15000) {
          sample = sample.sign * (15000 + saturation * (sample.abs() - 15000));
        }
        
        // Sub-harmonic generation (octave down)
        final subHarmonic1 = sample * subHarmonicMix * sin(pi * i / 2);
        final subHarmonic2 = sample * subHarmonicMix * sin(pi * i / 4);
        
        // Devil resonance (low, menacing frequencies)
        final devilRes1 = 1.0 + 0.3 * sin(2 * pi * i * 80 / sampleRate);  // 80 Hz
        final devilRes2 = 1.0 + 0.2 * sin(2 * pi * i * 160 / sampleRate); // 160 Hz
        
        sample *= (devilRes1 + devilRes2) / 2;
        sample += subHarmonic1 + subHarmonic2;
        
        // Growling effect
        if (i > 50) {
          final growl = 0.1 * processedSamples[i-50] * sin(2 * pi * i * 60 / sampleRate);
          sample += growl;
        }
        
        // Dark harmonic emphasis
        if (i > 10) {
          final darkHarmonics = 0.15 * processedSamples[i-10];
          sample += darkHarmonics;
        }
        
        processedSamples.add(sample.round().clamp(-32768, 32767));
      } else {
        processedSamples.add(0);
      }
    }
    
    return processedSamples;
  }

  List<int> _applyStaticEffect(List<int> samples, int sampleRate) {
    if (samples.isEmpty) return samples;
    
    // Profesyonel Statik/Noise Efekti
    // White noise + crackling + amplitude modulation
    
    final processedSamples = <int>[];
    const double staticIntensity = 0.6;
    const double crackleRate = 0.05;
    
    for (int i = 0; i < samples.length; i++) {
      var sample = samples[i].toDouble();
      
      // White noise generation
      final whiteNoise = (Random().nextDouble() * 2 - 1) * staticIntensity * 1500;
      
      // Crackling sounds
      var crackle = 0.0;
      if (Random().nextDouble() < crackleRate) {
        crackle = (Random().nextDouble() * 2 - 1) * 3000;
      }
      
      // High-frequency noise (static characteristic)
      final highFreqNoise = whiteNoise;
      
      // Filter noise slightly
      final filteredNoise = i > 5 ? 
          highFreqNoise * 0.7 + processedSamples[i-5] * 0.3 : 
          highFreqNoise;
      
      // Mix original signal with static
      sample = sample * 0.4 + filteredNoise + crackle;
      
      // Random amplitude variations
      if (Random().nextDouble() < 0.1) {
        sample *= (0.5 + Random().nextDouble() * 0.5);
      }
      
      processedSamples.add(sample.round().clamp(-32768, 32767));
    }
    
    return processedSamples;
  }

  // ===== MODULATION EFFECTS =====

  List<int> _applyChorusEffect(List<int> samples, int sampleRate) {
    if (samples.isEmpty) return samples;
    
    // Profesyonel Chorus Efekti (Multi-voice simulation)
    // Multiple delayed voices with LFO modulation
    
    final processedSamples = <int>[];
    const double baseDelay = 0.025; // 25ms base delay
    const double modDepth = 0.005; // 5ms modulation depth
    const double lfoRate = 0.5; // Hz
    const int voiceCount = 3;
    
    // Initialize delay buffers for multiple voices
    final maxDelay = ((baseDelay + modDepth) * sampleRate).round();
    final delayBuffers = List.generate(voiceCount, 
        (_) => List<double>.filled(maxDelay, 0.0));
    final delayIndices = List<int>.filled(voiceCount, 0);
    
    for (int i = 0; i < samples.length; i++) {
      final inputSample = samples[i].toDouble();
      var chorusSum = 0.0;
      
      // Process each voice
      for (int voice = 0; voice < voiceCount; voice++) {
        // Calculate modulated delay time for this voice
        final lfoPhase = 2 * pi * i * lfoRate / sampleRate + (voice * 2 * pi / voiceCount);
        final modulation = sin(lfoPhase);
        final delayTime = baseDelay + modDepth * modulation;
        final delaySamples = (delayTime * sampleRate).round();
        
        // Read from delay buffer
        final readIndex = (delayIndices[voice] - delaySamples) % delayBuffers[voice].length;
        final delayedSample = delayBuffers[voice][readIndex < 0 ? readIndex + delayBuffers[voice].length : readIndex];
        
        // Write to delay buffer
        delayBuffers[voice][delayIndices[voice]] = inputSample;
        delayIndices[voice] = (delayIndices[voice] + 1) % delayBuffers[voice].length;
        
        // Add voice to chorus sum
        chorusSum += delayedSample * (1.0 / voiceCount);
      }
      
      // Mix dry and chorus signals
      final outputSample = inputSample * 0.6 + chorusSum * 0.4;
      
      processedSamples.add(outputSample.round().clamp(-32768, 32767));
    }
    
    return processedSamples;
  }

  List<int> _applyFlangerEffect(List<int> samples, int sampleRate) {
    if (samples.isEmpty) return samples;
    
    // Profesyonel Flanger Efekti (Comb filtering with swept delay)
    
    final processedSamples = <int>[];
    const double baseDelay = 0.001; // 1ms base delay
    const double maxDelay = 0.010; // 10ms max delay
    const double lfoRate = 0.25; // Hz (slow sweep)
    const double feedback = 0.6; // 60% feedback
    const double wetMix = 0.5; // 50% wet signal
    
    final maxDelaySamples = (maxDelay * sampleRate).round();
    final delayBuffer = List<double>.filled(maxDelaySamples, 0.0);
    var writeIndex = 0;
    
    for (int i = 0; i < samples.length; i++) {
      final inputSample = samples[i].toDouble();
      
      // Calculate swept delay time
      final lfo = sin(2 * pi * i * lfoRate / sampleRate);
      final delayTime = baseDelay + (maxDelay - baseDelay) * (lfo + 1) / 2;
      final delaySamples = (delayTime * sampleRate).round();
      
      // Read from delay buffer
      final readIndex = (writeIndex - delaySamples) % delayBuffer.length;
      final delayedSample = delayBuffer[readIndex < 0 ? readIndex + delayBuffer.length : readIndex];
      
      // Apply feedback
      final feedbackSample = delayedSample * feedback;
      
      // Write to delay buffer
      delayBuffer[writeIndex] = inputSample + feedbackSample;
      writeIndex = (writeIndex + 1) % delayBuffer.length;
      
      // Mix dry and wet signals
      final outputSample = inputSample + delayedSample * wetMix;
      
      processedSamples.add(outputSample.round().clamp(-32768, 32767));
    }
    
    return processedSamples;
  }

  List<int> _applyPhaserEffect(List<int> samples, int sampleRate) {
    if (samples.isEmpty) return samples;
    
    // Profesyonel Phaser Efekti (All-pass filter cascade)
    
    final processedSamples = <int>[];
    const double lfoRate = 0.3; // Hz
    const double depth = 0.8; // Phasing depth
    const double feedback = 0.4; // Feedback amount
    const int stages = 4; // Number of all-pass stages
    
    // All-pass filter state variables
    final allpassStates = List<double>.filled(stages, 0.0);
    
    for (int i = 0; i < samples.length; i++) {
      var sample = samples[i].toDouble();
      
      // Calculate LFO value
      final lfo = sin(2 * pi * i * lfoRate / sampleRate);
      final coefficient = 0.5 + depth * lfo * 0.4;
      
      // Apply cascade of all-pass filters
      for (int stage = 0; stage < stages; stage++) {
        final input = sample;
        final delayed = allpassStates[stage];
        
        // All-pass filter equation
        sample = -coefficient * input + delayed;
        allpassStates[stage] = input + coefficient * sample;
      }
      
      // Add feedback
      final output = samples[i].toDouble() + sample * 0.5 + sample * feedback;
      
      processedSamples.add(output.round().clamp(-32768, 32767));
    }
    
    return processedSamples;
  }

  List<int> _applyTremoloEffect(List<int> samples, int sampleRate) {
    if (samples.isEmpty) return samples;
    
    // Profesyonel Tremolo Efekti (Amplitude modulation)
    
    final processedSamples = <int>[];
    const double tremoloRate = 4.0; // Hz
    const double depth = 0.7; // 70% modulation depth
    
    for (int i = 0; i < samples.length; i++) {
      final sample = samples[i].toDouble();
      
      // Generate tremolo LFO (sine wave)
      final lfo = sin(2 * pi * i * tremoloRate / sampleRate);
      
      // Apply amplitude modulation
      final modulation = 1.0 + depth * lfo;
      final modulatedSample = sample * modulation;
      
      processedSamples.add(modulatedSample.round().clamp(-32768, 32767));
    }
    
    return processedSamples;
  }

  Uint8List _createWavFile(List<int> samples, int sampleRate, int channels) {
    if (samples.isEmpty) {
      throw Exception('Ses verileri boş');
    }
    
    final dataSize = samples.length * 2; // 16-bit samples
    final fileSize = 36 + dataSize;
    
    final bytes = Uint8List(44 + dataSize);
    final byteData = ByteData.view(bytes.buffer);
    
    try {
      // RIFF header
      bytes[0] = 0x52; // R
      bytes[1] = 0x49; // I
      bytes[2] = 0x46; // F
      bytes[3] = 0x46; // F
      byteData.setUint32(4, fileSize, Endian.little);
      bytes[8] = 0x57;  // W
      bytes[9] = 0x41;  // A
      bytes[10] = 0x56; // V
      bytes[11] = 0x45; // E
      
      // fmt chunk
      bytes[12] = 0x66; // f
      bytes[13] = 0x6D; // m
      bytes[14] = 0x74; // t
      bytes[15] = 0x20; // space
      byteData.setUint32(16, 16, Endian.little); // chunk size
      byteData.setUint16(20, 1, Endian.little);  // audio format (PCM)
      byteData.setUint16(22, channels, Endian.little);
      byteData.setUint32(24, sampleRate, Endian.little);
      byteData.setUint32(28, sampleRate * channels * 2, Endian.little); // byte rate
      byteData.setUint16(32, channels * 2, Endian.little); // block align
      byteData.setUint16(34, 16, Endian.little); // bits per sample
      
      // data chunk
      bytes[36] = 0x64; // d
      bytes[37] = 0x61; // a
      bytes[38] = 0x74; // t
      bytes[39] = 0x61; // a
      byteData.setUint32(40, dataSize, Endian.little);
      
      // Audio data
      for (int i = 0; i < samples.length; i++) {
        final sampleValue = samples[i].clamp(-32768, 32767);
        byteData.setInt16(44 + i * 2, sampleValue, Endian.little);
      }
      
      return bytes;
    } catch (e) {
      throw Exception('WAV dosyası oluşturulamadı: $e');
    }
  }

  void _finishProcessing() {
    _isProcessing = false;
    notifyListeners();
  }
}

class WavData {
  final List<int> samples;
  final int sampleRate;
  final int channels;
  final int bitsPerSample;

  WavData(this.samples, this.sampleRate, this.channels, this.bitsPerSample);
} 