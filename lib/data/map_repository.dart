import 'dart:convert';
import 'package:flutter/services.dart'; // Necessario per rootBundle e AssetManifest
import '../models/map_model.dart';

class MapRepository {
  
  // LISTA MANUALE DI SICUREZZA
  // Questa viene usata se il caricamento dinamico fallisce o se siamo su Web in modalità che non espone il manifest
  final List<MapScenario> _manualMaps = [
    MapScenario(
      id: "forest_manual",
      name: "Foresta",
      description: "Accampamento nella foresta.",
      backgroundAsset: "assets/maps/ForestEncampment_digital_day_grid.jpg",
      rows: 14,
      cols: 12,
      initialObjects: []
    ),
    MapScenario(
      id: "beach_manual",
      name: "Spiaggia",
      description: "Costa tropicale.",
      backgroundAsset: "assets/maps/Tropical_Beach_digital_grid.jpg",
      rows: 14,
      cols: 12,
      initialObjects: []
    )
  ];

  Future<List<MapScenario>> getAvailableScenarios() async {
    List<String> imagePaths = [];

    try {
      print("🔍 MAP REPO: Ricerca asset mappe...");

      // TENTATIVO 1: Metodo Moderno (Classe AssetManifest)
      // Funziona su Flutter 3.13+ e gestisce automaticamente .bin o .json
      try {
        final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
        final assets = manifest.listAssets();
        
        imagePaths = assets
            .where((String key) => key.contains('assets/maps/') &&
                (key.toLowerCase().endsWith('.jpg') || 
                 key.toLowerCase().endsWith('.jpeg') || 
                 key.toLowerCase().endsWith('.png')))
            .toList();
            
      } catch (e) {
        // TENTATIVO 2: Metodo Legacy (Parsing JSON manuale)
        // Se il metodo sopra fallisce (vecchie versioni SDK), proviamo a leggere il JSON grezzo
        // Questo potrebbe generare il 404 su Web recenti, ma lo catturiamo.
        final manifestContent = await rootBundle.loadString('AssetManifest.json');
        final Map<String, dynamic> manifestMap = json.decode(manifestContent);
        
        imagePaths = manifestMap.keys
            .where((String key) => key.contains('assets/maps/') &&
                (key.toLowerCase().endsWith('.jpg') || 
                 key.toLowerCase().endsWith('.jpeg') || 
                 key.toLowerCase().endsWith('.png')))
            .toList();
      }

      print("✅ MAP REPO: Trovate ${imagePaths.length} mappe dinamiche.");

      // Se non abbiamo trovato nulla dinamicamente, usiamo i manuali
      if (imagePaths.isEmpty) {
        print("ℹ️ MAP REPO: Nessuna mappa dinamica trovata. Uso elenco manuale.");
        return _manualMaps;
      }

      // Convertiamo i percorsi in Scenari
      return imagePaths.map((path) {
        String filename = path.split('/').last;
        String rawName = filename.split('.').first;
        String displayName = rawName
            .replaceAll('_', ' ')
            .replaceAll('digital', '')
            .replaceAll('grid', '')
            .replaceAll('day', '')
            .trim();

        // Capitalizza le parole
        displayName = displayName.split(' ').map((str) => 
          str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1)}' : ''
        ).join(' ');

        return MapScenario(
          id: rawName,
          name: displayName.isEmpty ? "Mappa" : displayName,
          description: "Scenario: $filename",
          backgroundAsset: path,
          rows: 14,
          cols: 12,
          initialObjects: [], 
        );
      }).toList();

    } catch (e) {
      // 3. FALLBACK FINALE SILENZIOSO
      // Se tutto fallisce (es. 404 su Web), restituiamo i manuali senza lanciare errori critici.
      // Il print è informativo, non di errore.
      print("ℹ️ MAP REPO: AssetManifest non accessibile ($e). Uso mappe predefinite.");
      return _manualMaps;
    }
  }
}