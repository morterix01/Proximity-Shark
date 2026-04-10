# 🦈 Proximity Shark® 

> Trasforma il tuo Android in una **tastiera Bluetooth wireless** — esegui payload DuckyScript senza alcun hardware aggiuntivo.

---

## 🚀 Cos'è Proximity Shark?

Proximity Shark è un'app Android sviluppata con Flutter che emula una **tastiera HID Bluetooth Classic**. Connettiti a qualsiasi PC Windows, Linux o macOS già accoppiato e inietta sequenze di tasti tramite script DuckyScript — tutto dal tuo telefono, senza bisogno di dongle o cavi.

---

## ✨ Funzionalità

| | |
|---|---|
| 🔵 **Emulazione HID** | Il telefono viene riconosciuto come tastiera Bluetooth dal PC host |
| 📝 **Parser DuckyScript** | Supporto per `STRING`, `DELAY`, `GUI`, `CTRL`, `ALT`, `SHIFT`, `ENTER`, `TAB` e combinazioni di tasti |
| 🇮🇹 **Layout Italiano** | Parser ottimizzato per la tastiera italiana |
| 📂 **Libreria Script** | Importa file o intere cartelle di payload, organizzali e lanciali con un tap |
| ⚡ **Esecuzione Rapida** | Un tocco per iniettare il payload sul dispositivo connesso |
| 🔁 **Riconnessione Automatica** | Riconnessione intelligente per un link HID sempre stabile |
| 🌙 **UI Dark** | Interfaccia scura e minimalista, pensata per l'uso sul campo |

---

## 📋 Come si usa

**1. Accoppia i dispositivi**
Vai in *Impostazioni → Bluetooth* sul tuo Android, individua il PC target e completa il pairing.

**2. Connettiti dall'app**
Apri Proximity Shark, tocca **Scansione** nella schermata di connessione e seleziona il tuo PC. Attendi lo stato **"Connesso"**.

**3. Importa un payload**
Vai nella tab **Libreria Script**, tocca **➕ Importa** e seleziona un file `.txt` DuckyScript — o un'intera cartella di script.

**4. Esegui**
Tocca il tuo script e premi **▶ Esegui** — i tasti vengono iniettati sul PC in tempo reale.

---

## 🛠️ Build dal sorgente

```bash
git clone https://github.com/morterix01/Proximity-Shark.git
cd Proximity-Shark
flutter pub get
flutter build apk --release
```

> Richiede Flutter ≥ 3.x, Android SDK API 28+ e un **dispositivo fisico** (l'emulazione HID non funziona su emulatori Android).

---

## ⚠️ Disclaimer

Questo progetto è sviluppato **esclusivamente a scopo educativo e di ricerca**.
L'autore declina ogni responsabilità per danni, conseguenze legali o usi impropri derivanti dall'utilizzo di questo software.
Utilizzare questo strumento su dispositivi o sistemi senza il consenso esplicito del proprietario è **illegale**.

Vedi [LICENSE](LICENSE) per i termini completi.

---

## 👤 Autore

**Luissrome** — [GitHub](https://github.com/morterix01)

*Proximity Shark non è affiliato con Hak5 o DuckyScript™. DuckyScript è un marchio registrato di Hak5 LLC.*
