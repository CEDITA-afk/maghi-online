import 'package:flutter/services.dart' show rootBundle;
import 'package:excel/excel.dart';
import '../models/spell.dart';

class DataRepository {
  
  Future<List<Spell>> loadAllSpells() async {
    List<Spell> allSpells = [];

    // Nomi dei file ESATTI che hai in assets/data
    final files = [
      'Lista Rossa.xlsx',
      'Lista Blu.xlsx',
      'Lista Verde.xlsx',
      'Lista Giallo.xlsx'
    ];

    for (var fileName in files) {
      try {
        // 1. Carica i byte del file
        final bytes = await rootBundle.load('assets/data/$fileName');
        
        // 2. Decodifica Excel
        var excel = Excel.decodeBytes(bytes.buffer.asUint8List());

        // 3. Itera sul primo foglio (Sheet1 o il nome del foglio)
        // Prendiamo la prima tabella disponibile
        final table = excel.tables[excel.tables.keys.first];

        if (table != null) {
          // Salta la riga 0 (Intestazioni) -> parte da 1
          for (int i = 1; i < table.rows.length; i++) {
            var row = table.rows[i];
            
            // Controllo base: se la riga ha meno di 4 colonne o il nome è vuoto, saltala
            if (row.length > 3 && row[3]?.value != null) {
               allSpells.add(Spell.fromExcelRow(row, fileName.split('.').first));
            }
          }
        }
      } catch (e) {
        print("⚠️ Errore caricamento $fileName: $e");
      }
    }
    return allSpells;
  }
}