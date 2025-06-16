import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tokan/settings/views/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('dev.fluttercommunity.plus/package_info');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return {
        'appName': 'tokan',
        'packageName': 'com.example.tokan',
        'version': '1.2.3',
        'buildNumber': '1',
        'buildSignature': '',
        'installerStore': '',
      };
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  testWidgets('affiche la version et le bouton de mise à jour', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pumpAndSettle();

    expect(find.text('1.2.3'), findsOneWidget);
    expect(find.text('Mise à jour'), findsOneWidget);
  });
}