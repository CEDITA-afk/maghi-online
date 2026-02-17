# 🧙‍♂️ Maghi del Destino - Digital Sandbox

**Maghi del Destino** è una piattaforma di test "Digital Tabletop" sviluppata in Flutter per simulare sessioni di gioco tattico. Il progetto nasce come strumento sandbox per testare bilanciamenti, magie e movimenti in tempo reale, offrendo un'esperienza fluida sia in locale che in multiplayer online.

## 🚀 Caratteristiche principali

* **Multiplayer Online Real-time**: Sincronizzazione istantanea delle posizioni, degli HP e dei dadi tramite Firebase Firestore.
* **Mappa Tattica Interattiva**: Gestione Sandbox con trascinamento dei token (Snap to Grid), creazione di muri, ostacoli e arredi colorabili.
* **Sistema di Misurazione (LOS)**: Strumento righello integrato per calcolare gittate e linee di vista (Line of Sight) in metri/caselle.
* **Grimori Dinamici**: Selezione e gestione dei mazzi di incantesimi basati sugli elementi (Fuoco, Acqua, Terra, Aria).
* **Dice Tray**: Lancio di dadi mana personalizzati con gestione dell'energia e ririoll.
* **Gestione Minion**: Spawn rapido di sgherri numerati con gestione degli HP indipendente.

## 🛠️ Setup Tecnico

Il progetto utilizza **Firebase** per la gestione del multiplayer. Per farlo funzionare correttamente nel tuo ambiente:

1.  Crea un progetto su [Firebase Console](https://console.firebase.google.com/).
2.  Abilita **Cloud Firestore** in modalità test.
3.  Registra un'app Web e ottieni l'oggetto `firebaseConfig`.
4.  Inserisci le tue chiavi nel file `lib/main.dart` all'interno della funzione `Firebase.initializeApp`.
5.  Esegui `flutter pub get` per installare le dipendenze.
6.  Esegui `flutter run -d chrome` per avviare l'app su browser.

## 🎮 Come Giocare Online

1.  Avvia l'applicazione.
2.  Nella schermata di **Setup**, inserisci un **ID Stanza** univoco (es. `Partita_Domenica`).
3.  Condividi l'ID con i tuoi amici.
4.  Una volta che tutti sono entrati con lo stesso ID, ogni movimento sulla mappa o cambio di HP sarà visibile a tutti i partecipanti in tempo reale.

---
*Sviluppato con ❤️ come strumento di supporto per appassionati di boardgame tattici.*