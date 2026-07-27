import 'package:flutter/widgets.dart';

import 'package:wevacalc/ui/core/widgets/app_title_bar.dart';
import 'package:wevacalc/utils/platform_info.dart';

/// Envolve o conteúdo do app com a [AppTitleBar] em plataformas desktop.
///
/// Em mobile e web o [child] é renderizado sem alterações.
class DesktopShell extends StatelessWidget {
  const DesktopShell({super.key, required this.child});

  final Widget child;

  /// True quando rodando em desktop (Windows, Linux ou macOS).
  static bool get isDesktop => PlatformInfo.isDesktop;

  @override
  Widget build(BuildContext context) {
    if (!isDesktop) return child;

    return Column(
      children: [
        const AppTitleBar(),
        Expanded(child: child),
      ],
    );
  }
}
