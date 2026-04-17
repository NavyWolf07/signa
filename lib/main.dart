import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

void main() async {
  // Flutter'ın başlamadan önce hazırlık yapmasını sağlar
  WidgetsFlutterBinding.ensureInitialized();

  // Türkçe tarih formatı için başlat
  await initializeDateFormatting('tr', null);

  runApp(
    // Riverpod'un tüm uygulamayı sarması gerekiyor
    // Bunu olmadan Riverpod çalışmaz
    const ProviderScope(child: DiaryApp()),
  );
}
