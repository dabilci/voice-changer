## Ses Değiştirici (Flutter)

Ses kaydınızı alıp çeşitli efektlerle dönüştürmenizi, dosyalarınızı yönetmenizi ve sonuçları paylaşmanızı sağlayan çok platformlu bir Flutter uygulaması.

### Özellikler
- Ses kaydı alma (mikrofon izni ile)
- Kayıtları oynatma ve dalga formu görselleştirme
- Efektler uygulama (ör. hız/pitch, yankı/eko vb.)
- Dosya içe/dışa aktarma, yönetme ve paylaşma
- Reklam entegrasyonu (Google Mobile Ads)

### Ekran Görüntüleri
Ekran görüntüleri için `assets/` veya proje Wiki kullanılabilir. (İsteğe bağlı)

---

### Kurulum
Gereksinimler:
- Flutter SDK (Dart sdk: `>=3.4.4 <4.0.0`)
- Android Studio / Xcode
- Platform SDK ve emülatör/cihaz

Kurulum adımları:
```bash
flutter pub get
flutter run
```

Android için mikrofon izni otomatik eklenir. iOS tarafında `Info.plist` içinde `NSMicrophoneUsageDescription` bulunduğundan emin olun.

### Derleme
- Android (APK): `flutter build apk --release`
- Android (AppBundle): `flutter build appbundle --release`
- iOS: `flutter build ios --release`
- Web: `flutter build web`

---

### Proje Yapısı
- `lib/main.dart`: Uygulama girişi
- `lib/screens/`: Ekranlar (`home_screen.dart`, `effects_screen.dart`, `files_screen.dart`)
- `lib/providers/`: State yönetimi (ses/efekt sağlayıcıları)
- `lib/widgets/`: Yeniden kullanılabilir bileşenler (kayıt butonu, oynatıcı, waveform)
- `lib/utils/`: Yardımcılar (tema, reklam yardımcıları)

### Kullanılan Paketler
- Durum ve UI: `provider`, `cupertino_icons`
- Ses: `record`, `audioplayers`, `just_audio`, `audio_session`, `flutter_audio_waveforms`
- İzin/Dosya: `permission_handler`, `path_provider`, `path`, `file_picker`
- Paylaşım/Reklam: `share_plus`, `google_mobile_ads`
- Diğer: `intl`

Reklam konfigürasyonu için `lib/utils/ad_helper.dart` içindeki birim kimliklerini (Ad Unit IDs) kendi değerlerinizle güncelleyin.

### Notlar ve İpuçları
- Üretim imzası için Android `key.properties` ve `*.jks` dosyalarınızı versiyon kontrolüne eklemeyin. `.gitignore` ile hariç tutulur.
- `build/` klasörleri ve IDE çıktı dosyaları repoya dahil edilmez.

### Yol Haritası (Örnek)
- Daha fazla ses efekti
- Gelişmiş düzenleme (kesme/birleştirme)
- i18n/çok dil desteği

### Katkı
Katkılar açıktır. Lütfen bir issue açın ya da doğrudan pull request gönderin.

### Lisans
Bu proje için lisans bilgisi ekleyin (örn. MIT).
