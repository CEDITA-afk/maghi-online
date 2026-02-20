import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/overlord_model.dart';

class OverlordRepository {
  Future<List<OverlordLoadout>> getAvailableOverlords() async {
    List<OverlordLoadout> overlords = [];

    try {
      // 1. Carica il manifest di tutti gli asset dell'app
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      // 2. Filtra solo i file che si trovano nella cartella corretta e sono .json
      final List<String> overlordPaths = manifestMap.keys
          .where((String key) => 
            key.startsWith('assets/data/overlords/') && 
            key.endsWith('.json'))
          .toList();

      // 3. Cicla sui file trovati e caricali
      for (String path in overlordPaths) {
        try {
          final String response = await rootBundle.loadString(path);
          final data = json.decode(response);
          overlords.add(OverlordLoadout.fromJson(data));
          print("Caricato Boss dinamicamente: $path");
        } catch (e) {
          print("Errore durante il parsing del file $path: $e");
        }
      }
    } catch (e) {
      print("Errore critico durante la scansione della cartella overlords: $e");
    }

    return overlords;
  }
}