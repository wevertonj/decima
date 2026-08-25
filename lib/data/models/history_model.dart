import 'dart:convert';

import 'package:decima/domain/entities/history_entry.dart';
import 'package:decima/domain/entities/history_line.dart';

class HistoryModel {
  final int? id;
  final String linesJson;
  final String result;
  final int createdAt;
  final String? name;
  final bool isFavorite;

  const HistoryModel({
    this.id,
    required this.linesJson,
    required this.result,
    required this.createdAt,
    this.name,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'expression': linesJson,
      'result': result,
      'created_at': createdAt,
      'name': name,
      'is_favorite': isFavorite ? 1 : 0,
    };
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory HistoryModel.fromMap(Map<String, dynamic> map) {
    return HistoryModel(
      id: map['id'] as int?,
      linesJson: map['expression'] as String,
      result: map['result'] as String,
      createdAt: map['created_at'] as int,
      name: map['name'] as String?,
      isFavorite: (map['is_favorite'] as int?) == 1,
    );
  }

  HistoryEntry toEntity() {
    List<HistoryLine> lines;

    // Tenta o formato novo (array JSON); fallback para o formato legado de
    // expressão única.
    try {
      final decoded = jsonDecode(linesJson);
      if (decoded is List) {
        lines = decoded
            .cast<Map<String, dynamic>>()
            .map((e) => HistoryLine.fromJson(e))
            .toList();
      } else {
        // Não deveria acontecer — tratado como legado.
        lines = [HistoryLine(expression: linesJson, result: result)];
      }
    } catch (_) {
      // Formato legado: string de expressão pura.
      lines = [HistoryLine(expression: linesJson, result: result)];
    }

    return HistoryEntry(
      id: id,
      lines: lines,
      result: result,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      name: name,
      isFavorite: isFavorite,
    );
  }

  factory HistoryModel.fromEntity(HistoryEntry entity) {
    final linesJson = jsonEncode(entity.lines.map((l) => l.toJson()).toList());

    return HistoryModel(
      id: entity.id,
      linesJson: linesJson,
      result: entity.result,
      createdAt: entity.createdAt.millisecondsSinceEpoch,
      name: entity.name,
      isFavorite: entity.isFavorite,
    );
  }
}
