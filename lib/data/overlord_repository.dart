import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/overlord_model.dart';

class OverlordRepository {
  Future<List<OverlordLoadout>> getAvailableOverlords() async {
    List<OverlordLoadout> overlords = [];

    try {
      // 1. Carica il manifest di tutti gli asset
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      // 2. Filtra i file. Cerchiamo file .json nella cartella overlords.
      // Usiamo una logica flessibile che ignora se il percorso inizia con 'assets/' o meno
      final List<String> overlordPaths = manifestMap.keys
          .where((String key) => 
            (key.contains('data/overlords/') || key.contains('overlords/')) && 
            key.endsWith('.json'))
          .toList();

      print("DEBUG: File JSON trovati nel manifest: $overlordPaths");

      if (overlordPaths.isEmpty) {
        print("ATTENZIONE: Nessun file trovato nella cartella assets/data/overlords/. Controlla pubspec.yaml");
      }

      // 3. Cicla sui file trovati e caricali
      for (String path in overlordPaths) {
        try {
          final String response = await rootBundle.loadString(path);
          final data = json.decode(response);
          
          // Usiamo l'ID del file come ID del boss se non presente nel JSON
          if (data['id'] == null) {
            data['id'] = path.split('/').last.replaceAll('.json', '');
          }
          
          overlords.add(OverlordLoadout.fromJson(data));
          print("DEBUG: Boss caricato correttamente: ${data['name']} ($path)");
        } catch (e) {
          print("ERRORE: Problema nel parsing del file $path: $e");
        }
      }
    } catch (e) {
      print("ERRORE CRITICO: Impossibile leggere AssetManifest.json: $e");
      // Se fallisce il caricamento dinamico, qui potresti mettere un backup hardcoded 
      // per evitare che l'app sia inutilizzabile, ma risolviamo il problema alla radice.
    }

    // Ordina i boss per nome per comodità dell'utente
    overlords.sort((a, b) => a.nome.compareTo(b.nome));
    return overlords;
  }
}