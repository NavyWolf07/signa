# 🌟 Signa — Kişisel Akıllı Günlük & Anı Uygulaması

<p align="center">
  <img src="web/icons/Icon-512.png" width="128" height="128" alt="Signa Logo" />
</p>

<p align="center">
  <b>Signa</b>, duygu ve düşüncelerinizi, ses kayıtlarınızı, fotoğraflarınızı ve konum/hava durumu bilgilerinizi güvenle saklamanızı sağlayan modern, zengin özelliklere sahip kişisel günlük uygulamasıdır.
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" /></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.10+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" /></a>
  <a href="https://riverpod.dev"><img src="https://img.shields.io/badge/State_Management-Riverpod_3-00599C?style=for-the-badge" alt="Riverpod" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.style=for-the-badge" alt="License" /></a>
</p>

---

## 🚀 Öne Çıkan Özellikler

### 📝 Zengin Metin Düzenleyici (Rich Text Editor)
- **Quill Entegrasyonu**: Metinlerinizi kalın, eğik, altı çizili yapın; liste, başlık ve özel biçimlendirmeler ekleyin.
- **Medya Desteği**: Günlük yazılarınıza yüksek çözünürlüklü fotoğraflar ve özel görseller ekleyin.

### 🎙️ Ses Kaydı & Dahili Oynatıcı
- **Dahili Ses Kaydedici**: Günlük anlarınızı sesli olarak kaydedin (`record` entegrasyonu).
- **Gelişmiş Ses Çalar**: Kaydettiğiniz sesleri doğrudan uygulama içinden dinleyin (`just_audio`).

### 🔒 Biyometrik Güvenlik & Gizlilik
- **Parmak İzi / Yüz Tanıma**: Uygulama açılışında ve arka plana alındığında biyometrik doğrulama ekranı.
- **Ekran Karartma Koruması**: Arka plana geçildiğinde hassas verilerinizi korumak için anında kararan gizlilik katmanı.

### 📍 Konum & Otomatik Hava Durumu
- **Konum Tespiti**: Günlük yazdığınız anın konumunu otomatik olarak ekleyin (`geolocator`).
- **Anlık Hava Durumu**: O anki hava durumu ve sıcaklık bilgisini yazınıza otomatik olarak kaydedin.

### 📊 Detaylı İstatistikler & Duygu Analizi
- **Duygu Takibi (Mood Tracker)**: Günlük ruh halinizi (Mutlu, Nötr, Üzgün, Harika vb.) kaydedin ve görselleştirin.
- **Grafiksel Analiz**: `fl_chart` ile duygu dağılımı, günlük tutma serileri (streak) ve etiket istatistiklerinizi grafiklerle inceleyin.

### 📅 Takvim Görünümü
- **İnteraktif Takvim**: `table_calendar` entegrasyonu ile geçmiş günlerdeki günlüklerinizi tarihe göre kolayca görüntüleyin ve filtreleyin.

### 🎨 Kişiselleştirilebilir Tema & Yazı Boyutu
- **Dinamik Renk Paletleri**: İstediğiniz tohum renkle (Seed Color) kişisel izinizi yansıtan renk temasını seçin.
- **Karanlık / Aydınlık Mod**: Göz dostu karanlık (Dark) ve aydınlık (Light) tema seçenekleri.
- **Dinamik Yazı Boyutu**: Uygulama genelindeki yazı boyutunu tercihinize göre ölçeklendirin.

### 💾 Güvenli Yedekleme & Geri Yükleme
- **Yedek Dışa Aktarma (`.diarybackup`)**: Veritabanı (`sqflite`), fotoğraflar ve ses kayıtlarınızı şifreli/sıkıştırılmış dosya formatında dışa aktarın.
- **Geri Yükleme**: Yedek dosyanızı seçerek tüm anılarınızı başka bir cihaza saniyeler içinde aktarın.

---

## 🛠️ Kullanılan Teknolojiler & Kütüphaneler

| Alan | Kullanılan Kütüphane / Teknoloji |
| :--- | :--- |
| **Framework & Dil** | Flutter (SDK ^3.10.0), Dart 3 |
| **Durum Yönetimi** | `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator` |
| **Navigasyon** | `go_router` |
| **Yerel Veritabanı** | `sqflite`, `path_provider`, `path` |
| **Zengin Metin Editörü** | `flutter_quill` |
| **Ses İşleme** | `just_audio`, `record` |
| **Biyometrik Güvenlik** | `local_auth` |
| **Grafik & İstatistik** | `fl_chart` |
| **Takvim** | `table_calendar` |
| **Konum & Hava Durumu** | `geolocator`, `http` |
| **Yedekleme & Medya** | `archive`, `share_plus`, `image_picker`, `file_picker` |

---

## 📂 Proje Mimarısı (Feature-First Architecture)

Project clean architecture ilkelerine uygun olarak **Feature-First** (Özellik Odaklı) yapıda tasarlanmıştır:

```
lib/
├── app.dart                        # Ana uygulama widget'ı ve Tema/Auth sağlayıcıları
├── main.dart                       # Uygulama başlangıç noktası ve ProviderScope
├── core/                           # Çekirdek yardımcılar ve konfigürasyonlar
│   ├── database/                   # SQLite veritabanı bağlantısı ve migration'lar
│   ├── router/                     # GoRouter rota tanımları
│   └── theme/                      # Material 3 tema ve renk şemaları
└── features/                       # Modüler özellikler
    ├── audio/                      # Ses kaydı ve oynatıcı servisleri
    ├── auth/                       # Biyometrik doğrulama ve güvenlik ekranları
    ├── entries/                    # Günlük yazıları (Domain, Data, Presentation)
    │   ├── data/                   # Modeller ve Repozitörler
    │   ├── domain/                 # Konum, hava durumu ve istatistik servisleri
    │   └── presentation/           # Ekranlar (Home, Editor) & Widget'lar (Calendar, Statistics)
    └── settings/                   # Tema, yazı boyutu ve yedekleme (BackupService)
```

---

## ⚙️ Kurulum & Çalıştırma

### Gereksinimler
- **Flutter SDK**: `>=3.10.0`
- **Dart SDK**: `>=3.10.0`
- **Android Studio / VS Code** (Flutter eklentileri ile)

### Adım Adım Kurulum

1. **Repoyu klonlayın**:
   ```bash
   git clone https://github.com/NavyWolf07/signa.git
   cd signa
   ```

2. **Bağımlılıkları yükleyin**:
   ```bash
   flutter pub get
   ```

3. **Kod üretecini çalıştırın (Riverpod modelleri için)**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Uygulamayı çalıştırın**:
   ```bash
   flutter run
   ```

---

## 🧪 Testleri Çalıştırma

Projedeki birim ve widget testlerini çalıştırmak için:

```bash
flutter test
```

Statik kod analizini çalıştırmak için:

```bash
flutter analyze
```

---

## 📜 Lisans

Bu proje [MIT Lisansı](LICENSE) ile lisanslanmıştır. Dilediğiniz gibi geliştirebilir ve kullanabilirsiniz.

---

<p align="center">
  <i>Signa — Anılarınızı güvenle saklayın. ✍️✨</i>
</p>
