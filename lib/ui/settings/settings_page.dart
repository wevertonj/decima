import 'package:decima/config/theme/app_layout.dart';
import 'package:decima/ui/settings/settings_view_model.dart';
import 'package:decima/ui/settings/widgets/color_picker.dart';
import 'package:decima/ui/settings/widgets/decimal_separator_selector.dart';
import 'package:decima/ui/settings/widgets/language_selector.dart';
import 'package:decima/ui/settings/widgets/theme_mode_selector.dart';
import 'package:decima/utils/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';

/// Tela de configurações: modo do tema, cor de destaque, formato de número
/// e idioma. Toda mudança é persistida na hora e refletida no app via o
/// singleton compartilhado de [SettingsViewModel].
class SettingsPage extends StatefulWidget {
  final SettingsViewModel viewModel;

  const SettingsPage({super.key, required this.viewModel});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final vm = widget.viewModel;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.padding.large,
          vertical: AppLayout.padding.medium,
        ),
        children: [
          _SectionTitle(title: l10n.theme),
          SizedBox(height: AppLayout.spacing.small),
          ThemeModeSelector(selected: vm.themeMode, onChanged: vm.setThemeMode),

          SizedBox(height: AppLayout.spacing.xl),

          _SectionTitle(title: l10n.color),
          SizedBox(height: AppLayout.spacing.medium),
          ColorPicker(
            selectedIndex: vm.seedColorIndex,
            onChanged: vm.setSeedColorIndex,
          ),

          SizedBox(height: AppLayout.spacing.xl),

          _SectionTitle(title: l10n.numberFormat),
          SizedBox(height: AppLayout.spacing.small),
          DecimalSeparatorSelector(
            selected: vm.decimalSeparator,
            onChanged: vm.setDecimalSeparator,
          ),

          SizedBox(height: AppLayout.spacing.xl),

          _SectionTitle(title: l10n.language),
          SizedBox(height: AppLayout.spacing.small),
          LanguageSelector(selected: vm.locale, onChanged: vm.setLocale),

          SizedBox(height: AppLayout.spacing.xl),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: colors.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
