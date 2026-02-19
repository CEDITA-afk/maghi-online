import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? sessionId;
  String? myUserId;

  FirebaseService() {
    // Genera un ID utente univoco per questa sessione/dispositivo
    myUserId = "user_${Random().nextInt(99999)}";
  }

  // --- STREAM IN TEMPO REALE ---

  // Ascolta i dati della stanza (usato sia in Lobby che in Gioco)
  Stream<DocumentSnapshot> get lobbyStream {
    if (sessionId == null) throw Exception("Session ID non impostato");
    return _db.collection('sessions').doc(sessionId).snapshots();
  }

  // --- GESTIONE LOBBY (Creazione e Partecipazione) ---

  // Crea una nuova stanza con un ID stile ROOM-1234
  Future<String> createLobby() async {
    String roomId = "ROOM-${Random().nextInt(9000) + 1000}";
    sessionId = roomId;
    
    await _db.collection('sessions').doc(roomId).set({
      'created_at': FieldValue.serverTimestamp(),
      'status': 'LOBBY',
      'hostId': myUserId,
      'players': [myUserId],
      'roles': {},      // Mappa Ruolo -> UserId
      'ready': [],      // Lista UserId pronti
      'mapIndex': 0,    // Impostazione host
      'bossIndex': 0,   // Impostazione host
    });
    return roomId;
  }

  // Si unisce a una stanza esistente
  Future<bool> joinLobby(String roomId) async {
    DocumentSnapshot doc = await _db.collection('sessions').doc(roomId).get();
    if (!doc.exists) return false;
    
    sessionId = roomId;
    await _db.collection('sessions').doc(roomId).update({
      'players': FieldValue.arrayUnion([myUserId])
    });
    return true;
  }

  // Prende un ruolo (es. 'rosso', 'overlord')
  Future<void> claimRole(String role) async {
    if (sessionId == null) return;
    await _db.collection('sessions').doc(sessionId).update({
      'roles.$role': myUserId
    });
  }

  // Rilascia un ruolo
  Future<void> unclaimRole(String role) async {
    if (sessionId == null) return;
    await _db.collection('sessions').doc(sessionId).update({
      'roles.$role': FieldValue.delete()
    });
  }

  // Cambia lo stato "Pronto"
  Future<void> toggleReady(bool isReady) async {
    if (sessionId == null) return;
    if (isReady) {
      await _db.collection('sessions').doc(sessionId).update({
        'ready': FieldValue.arrayUnion([myUserId])
      });
    } else {
      await _db.collection('sessions').doc(sessionId).update({
        'ready': FieldValue.arrayRemove([myUserId])
      });
    }
  }

  // Aggiorna impostazioni mappa/boss (solo host)
  Future<void> updateSettings(String key, int index) async {
    if (sessionId == null) return;
    await _db.collection('sessions').doc(sessionId).update({key: index});
  }

  // Avvia la partita (passa da LOBBY a PLAYING)
  Future<void> startGame() async {
    if (sessionId == null) return;
    await _db.collection('sessions').doc(sessionId).update({
      'status': 'PLAYING'
    });
  }

  // --- GESTIONE GAMEPLAY (Sincronizzazione Online) ---

  // Aggiorna la posizione di un token (Eroe, Boss, Minion)
  Future<void> updatePosition(String id, int x, int y) async {
    if (sessionId == null) return;
    await _db.collection('sessions').doc(sessionId).set({
      'positions': {
        id: {'x': x, 'y': y}
      }
    }, SetOptions(merge: true));
  }

  // Sincronizza lo stato globale (HP, dadi, minions)
  Future<void> updateFullState(Map<String, dynamic> data) async {
    if (sessionId == null) return;
    await _db.collection('sessions').doc(sessionId).set(data, SetOptions(merge: true));
  }
}