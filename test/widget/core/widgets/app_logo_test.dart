import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:decima/ui/core/widgets/app_logo.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('AppLogo', () {
    testWidgets('should render an Image widget', (tester) async {
      await tester.pumpApp(const AppLogo());

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should use the branding logo asset path', (tester) async {
      await tester.pumpApp(const AppLogo());

      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as AssetImage;

      expect(provider.assetName, 'assets/branding/logo.png');
    });

    testWidgets('should apply size when provided', (tester) async {
      const size = 64.0;
      await tester.pumpApp(const AppLogo(size: size));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);

      expect(sizedBox.width, size);
      expect(sizedBox.height, size);
    });

    testWidgets('should use default size when not provided', (tester) async {
      await tester.pumpApp(const AppLogo());

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);

      expect(sizedBox.width, AppLogo.defaultSize);
      expect(sizedBox.height, AppLogo.defaultSize);
    });
  });
}
