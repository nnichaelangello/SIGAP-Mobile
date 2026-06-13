// Widget Test untuk SIGAP Mobile App
// Test untuk memastikan aplikasi dapat diinisialisasi dengan benar

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sigap_mobile/main.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    // Build app dan trigger frame
    await tester.pumpWidget(const SigapApp());

    // Verifikasi app title/header ditampilkan
    expect(find.text('Akses Pengembangan'), findsOneWidget);

    // Verifikasi tombol login tersedia
    expect(find.text('Sudah Login'), findsOneWidget);
    expect(find.text('Belum Login'), findsOneWidget);

    // Verifikasi icon keamanan ditampilkan
    expect(find.byIcon(Icons.verified_user_rounded), findsOneWidget);
  });
}
