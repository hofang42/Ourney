import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';

void main() {
  test('share route carries Wrapped choices as query parameters (U4)', () {
    expect(AppRoutes.share('j1'), '/share/j1');
    final uri = Uri.parse(
      AppRoutes.share(
        'j1',
        format: 'feed',
        blur: false,
        hideBrand: true,
        hideMetric: true,
      ),
    );
    expect(uri.path, '/share/j1');
    expect(uri.queryParameters, {
      'format': 'feed',
      'blur': 'false',
      'hideBrand': 'true',
      'hideMetric': 'true',
    });
  });
}
