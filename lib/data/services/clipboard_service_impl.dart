import 'package:flutter/services.dart';

import 'package:decima/data/services/clipboard_service.dart';

class ClipboardServiceImpl implements ClipboardService {
  @override
  Future<void> copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  @override
  Future<String?> readText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return null;

    return text;
  }
}
