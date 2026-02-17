import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/overlord_model.dart';

class OverlordRepository {
  
  // 1. Ottiene la lista di tutti i boss disponibili
  Future<List<OverlordLoadout>> getAvailableOverlords() async {
    List<String> filePaths = [];

    try {
      // Tenta di caricare il manifesto automatico
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest = json.decode(manifestContent);

      filePaths = manifest.keys
          .where((String key) => key.contains('assets/data/overlords/'))
          .where((String key) => key.endsWith('.json'))
          .toList();

    } catch (e) {
      // SE FALLISCE (Errore 404), USA QUESTA LISTA MANUALE
      print("⚠️ AssetManifest non trovato. Uso lista manuale di fallback.");
      filePaths = [
        'assets/data/overlords/exo_01.json',
        'assets/data/overlords/ignis_02.json',
      ];
    }

    List<OverlordLoadout> overlords = [];
    for (String path in filePaths) {
      try {
        final String content = await rootBundle.loadString(path);
        final Map<String, dynamic> data = json.decode(content);
        overlords.add(OverlordLoadout.fromJson(data));
      } catch (e) {
        print("Errore caricamento file $path: $e");
      }
    }
    return overlords;
  }
}