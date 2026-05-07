# 🦈 Proximity Shark v2.0.0 — "DEEP BLUE EVOLUTION" 🌊

Siamo lieti di annunciare la versione **2.0.0** di **Proximity Shark**, un aggiornamento massiccio che porta la stabilità, l'estetica e le funzionalità ad un nuovo livello professionale. Questa release risolve bug storici relativi all'identità del dispositivo e introduce l'integrazione diretta con il cloud per gli script.

## 🚀 Novità Principali

### 📂 GitHub Script Library Hub
*   **Install from GitHub**: Aggiunto un nuovo pulsante nel Library Hub che permette di scaricare e installare istantaneamente l'intera collezione di script dal repository ufficiale [DuckyScript-Library](https://github.com/morterix01/DuckyScript-Library).
*   **Sincronizzazione Automatica**: Gli script vengono organizzati automaticamente in cartelle locali, pronti per essere eseguiti o modificati.

### 💬 Shark Chat 2.0 & WearOS
*   **Background Mode**: Implementato un servizio Android in primo piano (Foreground Service) che mantiene attiva la chat e la ricerca Bluetooth anche quando l'app è in background o lo schermo è spento.
*   **Watch Integration**: Ottimizzata la comunicazione con WearOS. Ora puoi associare il dispositivo una volta e inviare comandi/messaggi direttamente dal tuo orologio senza interruzioni.
*   **Stabilità P2P**: Risolti i conflitti di sessione "Already Advertising" durante il cambio di identità.

### 🛡️ Device Identity & Stealth
*   **Dynamic Renaming**: Corretto il bug che sovrascriveva il nome Bluetooth del dispositivo. Ora l'identità scelta (es. "Iphone di Lorenzo") viene mantenuta persistentemente grazie a un sistema di monitoraggio attivo.
*   **HID Profile Fix**: Migliorata la compatibilità del profilo tastiera Bluetooth con Windows e sistemi target.

## 🔧 Bug Fixes & Ottimizzazioni
*   **Android 14 Compatibility**: Risolti i crash relativi ai nuovi requisiti di sicurezza per i servizi in background su Android 14+.
*   **Fix SocketException**: Aggiunti i permessi Internet mancanti per il download degli script.
*   **Permission Handling**: Migliorata la gestione dei permessi Bluetooth e Posizione per una ricerca dei dispositivi più fluida.
*   **UI/UX**: Refactoring del design con micro-animazioni e gestione degli errori migliorata.

---

**Nota per l'installazione:** 
Assicurarsi di concedere tutti i permessi (Bluetooth, Posizione, Notifiche) al primo avvio per garantire il corretto funzionamento dei servizi di background.
