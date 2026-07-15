import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../models/prayer.dart';

/// Carga y sirve el catalogo local de oraciones desde
/// `assets/data/prayers_es.json`.
class PrayerRepository {
  List<Prayer>? _cache;

  Future<List<Prayer>> _loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/prayers_es.json');
    final list = jsonDecode(raw) as List;
    _cache = list
        .map((e) => Prayer.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return _cache!;
  }

  Future<List<Prayer>> all() => _loadAll();

  Future<List<Prayer>> byCategories(List<String> categorias) async {
    final all = await _loadAll();
    if (categorias.isEmpty) return all;
    return all.where((p) => categorias.contains(p.categoria)).toList();
  }

  Future<List<Prayer>> byCategory(String categoria) async {
    final all = await _loadAll();
    return all.where((p) => p.categoria == categoria).toList();
  }

  Future<Prayer?> byId(String id) async {
    final all = await _loadAll();
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// "Oracion del dia": determinista segun la fecha, para que todos los
  /// usuarios (y la misma persona a lo largo del dia) vean la misma
  /// oracion aunque no haya backend. Cambia automaticamente cada dia.
  Future<Prayer> prayerOfTheDay({List<String>? preferredCategories}) async {
    final all = await _loadAll();
    List<Prayer> pool = all;
    if (preferredCategories != null && preferredCategories.isNotEmpty) {
      // Coherencia estricta: la oracion del dia sale del PRIMER tema que
      // la persona eligio (rota dia a dia dentro de ese tema). Si ese
      // tema no tuviera oraciones, se amplia al resto de sus temas.
      final first =
          all.where((p) => p.categoria == preferredCategories.first).toList();
      final filtered = first.isNotEmpty
          ? first
          : all
              .where((p) => preferredCategories.contains(p.categoria))
              .toList();
      if (filtered.isNotEmpty) pool = filtered;
    }
    final dayIndex = DateTime.now()
        .difference(DateTime(2025, 1, 1))
        .inDays
        .abs();
    final index = dayIndex % pool.length;
    return pool[index];
  }

  Future<Prayer> randomFromCategory(String categoria) async {
    final list = await byCategory(categoria);
    if (list.isEmpty) {
      final all = await _loadAll();
      return all[Random().nextInt(all.length)];
    }
    return list[Random().nextInt(list.length)];
  }
}
