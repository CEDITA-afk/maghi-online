import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? sessionId;
  String? myUserId;

  // Accetta il sessionId opzionale per risolvere l'errore di compilazione
  FirebaseService([this.sessionId]) {
    myUserId = "user_${Random().nextInt(99999)}";
  }

  // Alias per gameStream richiesto da GamePage
  Stream<DocumentSnapshot> get gameStream => lobbyStream;

  Stream<DocumentSnapshot> get lobbyStream {
    if (sessionId == null) throw Exception("Session ID non impostato");
    return _db.collection('sessions').doc(sessionId!).snapshots();
  }

  // --- LOGICA LOBBY ---

  Future<String> createLobby() async {
    String roomId = "ROOM-${Random().nextInt(9000) + 1000}";
    sessionId = roomId;
    await _db.collection('sessions').doc(roomId).set({
      'status': 'LOBBY',
      'hostId': myUserId,
      'players': [myUserId],
      'roles': {}, 
      'ready': [],
      'mapIndex': 0,
      'bossIndex': 0,
    });
    return roomId;
  }

  Future<bool> joinLobby(String roomId) async {
    DocumentSnapshot doc = await _db.collection('sessions').doc(roomId).get();
    if (!doc.exists) return false;
    sessionId = roomId;
    await _db.collection('sessions').doc(roomId).update({
      'players': FieldValue.arrayUnion([myUserId])
    });
    return true;
  }

  Future<void> claimRole(String role) async {
    if (sessionId == null) return;
    await _db.collection('sessions').doc(sessionId!).update({'roles.$role': myUserId});
  }

  Future<void> unclaimRole(String role) async {
    if (sessionId == null) return;
    await _db.collection('sessions').doc(sessionId!).update({'roles.$role': FieldValue.delete()});
  }

  Future<void> toggleReady(bool isReady) async {
    if (sessionId == null) return;
    await _db.collection('sessions').doc(sessionId!).update({
      'ready': isReady ? FieldValue.arrayUnion([myUserId]) : FieldValue.arrayRemove([myUserId])
    });
  }

  Future<void> updateSettings(String key, int index) async {
    if (sessionId == null) return;
    await _db.collection('sessions').doc(sessionId!).update({key: index});
  }

  Future<void> startGame() async {
    if (sessionId == null) return;
    await _db.collection('sessions').doc(sessionId!).update({'status': 'PLAYING'});
  }

  // --- LOGICA GIOCO ---
  Future<void> updatePosition(String id, int x, int y) async {
    if (sessionId == null) return;
    await _db.collection('sessions').doc(sessionId!).set({
      'positions': { id: {'x': x, 'y': y} }
    }, SetOptions(merge: true));
  }

  Future<void> updateFullState(Map<String, dynamic> data) async {
    if (sessionId == null) return;
    await _db.collection('sessions').doc(sessionId!).set(data, SetOptions(merge: true));
  }
}