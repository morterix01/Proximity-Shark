# 🦈 Note di Rilascio: Proximity Shark

---

## 🛠️ Release v1.0.8 — "The Persistence & Stealth Update" (v2)
*Un aggiornamento massiccio focalizzato su controllo remoto, navigazione e stabilità Win11.*

### 🌟 Novità Assolute
- **🛡️ Stealth Shutdown**: Introdotta una terza scheda tattica che permette lo spegnimento forzato del PC target. Il comando viene eseguito via PowerShell con finestra nascosta (`-WindowStyle Hidden`), garantendo un'azione totalmente invisibile all'utente target.
- **🔄 Navigazione Circolare (Infinite Loop)**: Implementata la navigazione infinita tra le pagine *Panic*, *Taskkill* e *Shutdown*. Ora puoi scorrere verso l'alto dall'ultima pagina per tornare alla prima e viceversa, sia su smartphone che su Wear OS.
- **⚓ Win11 Stability Fix**: Risolto il bug critico della "connessione di mezzo secondo" su Windows 11. Il sistema ora esegue un reset automatico del profilo HID e un periodo di grazia (grace period) dinamico per garantire che il target accetti sempre il link.
- **⌚ WearOS Sync 2.0**: Sincronizzazione totale degli stati di "Linking". L'orologio ora riceve feedback in tempo reale sul progresso della connessione dal telefono e interrompe correttamente l'animazione di caricamento se la connessione fallisce o termina.
- **🧹 UI/UX Cleanup**: 
    - Rimozione dei dispositivi "Unknown" dalla lista scansione per un accoppiamento rapido.
    - Rimozione del layout "US" ridondante su Wear OS per una navigazione più snella.

---

## 🛠️ Pre-Release (Beta): Phone v1.0.7 & Wear OS v1.0.1
*Aggiornamento di stabilità critico per il modulo Wear OS.*

### 🚀 Bug Fixes & Ottimizzazioni
- **Sincronizzazione Wear OS a 60 FPS**: Abilitato R8 Shrink (ProGuard) e state immutabili in Jetpack Compose, garantendo massime performance grafiche a 60fps abolendo i lag di sistema riscontrati nell'orologio.
- **Supporto Massivo Script (GZIP Base64)**: Abbattimento dei limiti dell'API Wear OS (100KB); la struttura delle librerie inviata dall'app smartphone viene ora super-compressa offrendo scalabilità infinita per centinaia di script.
- **Fix "Crash Subito" (Duplicate Key)**: Risolto un grave bug logico al parse del path delle directory (che in precedenza risultava vacante causando conflitti in UI) e portato il runtime del parse nel thread in background `Dispatchers.IO` eliminando errori causati dal freeze dell'Activity (ANR).Il predatore si evolve. Proximity Shark non è più solo un'applicazione, ma un sistema di attacco coordinato e letale. 

---

## 📱 Applicazione Telefono: v1.0.6 — "Total Control"
Questa versione trasforma il tuo smartphone nell'hub centrale di un ecosistema HID senza precedenti.

### 🌟 Novità Assolute
- **⌚ Integrazione Wear OS**: La rivoluzione è arrivata. Ora puoi comandare Proximity Shark direttamente dal tuo smartwatch. Sfoglia la libreria, seleziona il layout e lancia payload senza mai estrarre il telefono dalla tasca.
- **🌍 Dominio dei Layout**: Espansione totale della compatibilità. Abbiamo aggiunto i layout **Standard US** e **US International**, fondamentali per la piena compatibilità con dispositivi e board interattive come **Helgi LIM**, aggirando le restrizioni della tastiera fisica predefinita. Questi si affiancano ai già potenti **PC IT** e **Android IT**. Nessun sistema target è più al sicuro.
- **⚙️ Mechanical Shark UI**: Un'interfaccia ridisegnata per i professionisti. Estetica hacker, animazioni ultra-fluide e un'esperienza utente rifinita per la massima efficienza operativa.
- **🛡️ Stealth Hub 2.0**: Il controllo della tua impronta digitale non è mai stato così granulare. Monitoraggio IP in tempo reale e gestione avanzata dell'identità Bluetooth (MAC) per operare nell'ombra.
- **🛠️ Stabilità Core**: Risolti i bug di compilazione AAPT2 e ottimizzate le performance per un'esecuzione dei payload più rapida e affidabile.

---

## ⌚ Wear OS Companion: v1.0.0 — "Power on your Wrist"
Il tuo smartwatch diventa uno strumento d'attacco tattico. La companion app ufficiale porta il potere di Proximity Shark direttamente al tuo polso.

### 🚀 Caratteristiche Tattiche
- **⚡ Remote Triggering**: Lancia i tuoi DuckyScript con un solo tocco dall'orologio. Silenzioso, immediato, letale.
- **📂 Sincronizzazione Totale**: La tua intera libreria di script presente sul telefono è ora navigabile direttamente dallo schermo del tuo orologio.
- **⌨️ Layout Switcher**: Cambia il layout della tastiera target (PC IT, US, Android IT) direttamente dal polso prima di lanciare l'attacco.
- **📊 Feedback Visivo Critico**: Ricevi conferme istantanee (✅/❌) sull'esito dell'invio del payload tramite overlay a tutto schermo ottimizzati per display OLED.

---

## 🛠️ Istruzioni per il Deployment
1. Builda l'APK del telefono: `flutter build apk --release`.
2. Builda l'APK Wear OS tramite Android Studio (Galaxy Watch 4+ raccomandato).
3. Accoppia i dispositivi via Bluetooth: la sincronizzazione della libreria e dei comandi avverrà automaticamente.

---

*Solo a scopo educativo. L'autore non è responsabile per qualsiasi uso improprio di questo strumento.*
