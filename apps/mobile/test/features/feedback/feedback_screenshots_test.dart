import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/theme/app_theme.dart';
import 'package:ourney/features/feedback/ui/feature_request_detail_screen.dart';
import 'package:ourney/features/feedback/ui/feature_requests_screen.dart';
import 'package:ourney/features/safety/data/safety_providers.dart';

import '../../app/test_helpers.dart';
import 'feature_requests_test.dart' show FakeFeatureRequestRepository;

bool _fontsLoaded = false;

Future<void> _loadBundledFonts() async {
  if (_fontsLoaded) return;
  _fontsLoaded = true;
  const fontMap = <String, List<String>>{
    'BeVietnamPro': [
      'assets/fonts/BeVietnamPro-Regular.ttf',
      'assets/fonts/BeVietnamPro-Medium.ttf',
      'assets/fonts/BeVietnamPro-SemiBold.ttf',
      'assets/fonts/BeVietnamPro-Bold.ttf',
    ],
    'BricolageGrotesque': ['assets/fonts/BricolageGrotesque-Variable.ttf'],
    'SpaceGrotesk': ['assets/fonts/SpaceGrotesk-Variable.ttf'],
    'SpaceMono': [
      'assets/fonts/SpaceMono-Regular.ttf',
      'assets/fonts/SpaceMono-Bold.ttf',
    ],
  };

  for (final entry in fontMap.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        loader.addFont(
          Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
        );
      }
    }
    await loader.load();
  }
}

final String? _shotsDir = () {
  final raw = Platform.environment['OURNEY_SHOTS_DIR']?.trim();
  return (raw == null || raw.isEmpty) ? null : raw;
}();

Future<void> _captureShot(
  GlobalKey boundaryKey,
  String outDir,
  String filename,
) async {
  final dir = Directory(outDir);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2.0);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  final pngBytes = byteData!.buffer.asUint8List();
  File('${dir.path}/$filename').writeAsBytesSync(pngBytes);
}

void main() {
  testWidgets(
    'renders light and dark screenshots of board, detail, and create sheet',
    skip: _shotsDir == null,
    (tester) async {
      final outDir = _shotsDir!;
      await _loadBundledFonts();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Future<void> renderScene({
        required Brightness brightness,
        required String initialLocation,
        required String filename,
        Future<void> Function()? interact,
      }) async {
        final repo = FakeFeatureRequestRepository();
        final prefs = await testPrefs({
          OnboardingComplete.prefsKey: true,
          SafetyPrefs.eulaAccepted: true,
        });
        final boundaryKey = GlobalKey();
        final router = GoRouter(
          initialLocation: initialLocation,
          routes: [
            GoRoute(
              path: AppRoutes.feedback,
              builder: (_, _) => const FeatureRequestsScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) => FeatureRequestDetailScreen(
                    requestId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        );

        final container = ProviderContainer(
          overrides: [
            appConfigProvider.overrideWithValue(testBackendConfig),
            sharedPreferencesProvider.overrideWithValue(prefs),
            supabaseClientProvider.overrideWithValue(null),
            authRepositoryProvider.overrideWithValue(
              FakeAuthRepository(userId: 'u-me'),
            ),
            featureRequestRepositoryProvider.overrideWithValue(repo),
          ],
        );

        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: UncontrolledProviderScope(
              container: container,
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: buildAppTheme(brightness),
                locale: const Locale('vi'),
                localizationsDelegates: ourneyLocalizationsDelegates,
                supportedLocales: ourneySupportedLocales,
                routerConfig: router,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (interact != null) {
          await interact();
        }
        await tester.runAsync(
          () => _captureShot(boundaryKey, outDir, filename),
        );
        router.dispose();
        container.dispose();
      }

      // 1 & 2: Board Light + Dark
      await renderScene(
        brightness: Brightness.light,
        initialLocation: AppRoutes.feedback,
        filename: '01_board_light.png',
      );
      await renderScene(
        brightness: Brightness.dark,
        initialLocation: AppRoutes.feedback,
        filename: '02_board_dark.png',
      );

      // 3 & 4: Detail Light (Planned + Ourney Reply) + Dark (Shipped)
      await renderScene(
        brightness: Brightness.light,
        initialLocation: AppRoutes.featureRequest('req-1'),
        filename: '03_detail_light.png',
      );
      await renderScene(
        brightness: Brightness.dark,
        initialLocation: AppRoutes.featureRequest('req-3'),
        filename: '04_detail_dark.png',
      );

      // 5 & 6: Create Sheet Light + Dark with live duplicate suggestions
      Future<void> openCreateWithDuplicates() async {
        await tester.tap(find.byKey(const ValueKey('feedback-create-cta')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('feedback-title-input')),
          'Widget màn hình khóa',
        );
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
      }

      await renderScene(
        brightness: Brightness.light,
        initialLocation: AppRoutes.feedback,
        filename: '05_create_sheet_light.png',
        interact: openCreateWithDuplicates,
      );
      await renderScene(
        brightness: Brightness.dark,
        initialLocation: AppRoutes.feedback,
        filename: '06_create_sheet_dark.png',
        interact: openCreateWithDuplicates,
      );
    },
  );
}
