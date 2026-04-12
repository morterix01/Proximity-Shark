# 🦈 Proximity Shark – Wiki Ufficiale

Benvenuto nella Wiki Ufficiale di **Proximity Shark**. Abbiamo trasformato un normale smartphone (e il corrispondente smartwatch Wear OS) in un potentissimo vettore di attacco via Bluetooth (BadUSB tramite BLE HID). In questa wiki troverai tutte le informazioni per configurare l'ecosistema, scrivere i tuoi payload e scatenarli in silenzio.

---

## 📑 Indice dei Contenuti

1. [Panoramica e Obiettivi](#1-panoramica-e-obiettivi)
2. [Installazione e Setup](#2-installazione-e-setup)
3. [Componenti Core: Smartphone e Smartwatch](#3-componenti-core-smartphone-e-smartwatch)
4. [Sintassi degli Script e Layout Tastiere](#4-sintassi-degli-script-e-layout-tastiere)
5. [Guida alla Wear OS Companion App](#5-guida-alla-wear-os-companion-app)
6. [Stealth Hub & Privacy](#6-stealth-hub--privacy)
7. [F.A.Q. e Risoluzione dei Problemi](#7-faq-e-risoluzione-dei-problemi)
8. [Disclaimer Legale](#8-disclaimer-legale)

---

## 1. Panoramica e Obiettivi
**Proximity Shark** è specializzato nella trasmissione rapida, silenziosa e programmabile di macro e sequenze di tasti. Funziona emulando a livello hardware una tastiera Bluetooth (HID - Human Interface Device). 

**Punti di forza:**
- Nessun dongle richiesto: sfrutta i chip Bluetooth nativi.
- Estremamente furtivo: triggerabile da Watch.
- Interprete nativo di **DuckyScript** ottimizzato al 100% per Layout specifici fisici o virtuali.

## 2. Installazione e Setup
1. **Scarica l'ultima release:** Naviga nella sezione [Releases](https://github.com/morterix01/Proximity-Shark/releases) e scarica `app-release.apk`.
2. **Wear OS:** Scarica il rispettivo `.apk` della companion app per lo smartwatch direttamente da Github tramite ADB al device, oppure utilizzando app per il ridirezionamento dell'installazione.
   - Esempio ADB: `adb -s <IP_WATCH:PORT> install Proximity-Shark-WearOS.apk`
3. **Permessi iniziali:** Al primo avvio sul telefono, concedi tassativamente i permessi per il Bluetooth (`BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN`, `BLUETOOTH_ADVERTISE`). In caso contrario, l'HID profile non si attiverà.

## 3. Componenti Core: Smartphone e Smartwatch

L'app per Smartphone funge da **Cervello Centrale**. Qui gestisci:
- L'importazione di migliaia di script nelle directory (file `.txt` classici).
- La gestione dei DuckyScript modificabili nell'editor integrato.
- L'associazione al target Bluetooth (Desktop/Laptop o Dispositivi smart vulnerabili).
- Le impostazioni del MAC Address e dell'identità broadcastata.

L'app per Smartwatch (Wear OS) funge da **Grilletto in Remoto**.
- Mostra in tempo reale (e a 60 fps) tutta l'intera la libreria Script aggiornata salvata nel telefono.
- Ti permette di innescare l'attacco senza mai guardare il telefono.
- Ti dà un feedback immediato (✅ / ❌) sulla riuscita o il fallimento dell'iniezione dei payload.

## 4. Sintassi degli Script e Layout Tastiere

### L'importanza del Layout
I caratteri inviati via Bluetooth HID viaggiano come "coordinate fisiche" di una tastiera (Scancode), e **non** come semplici lettere. Se non imposti il giusto target, un comando come `/` si scriverà come `&` a seconda del computer della vittima.

Proximity Shark ha 4 formidabili algoritmi di mapping:
- **PC (IT)**: Ottimizzato per bersagli Windows localizzati in Italia. Usa la logica di Shift e AltGr standard europei.
- **Android (IT)**: Altamente specifico. Utile per bersagli con Android Base, incluse **Lavagne Interattive e LIM (come i pannelli Helgi)** che alterano o ignorano alcuni "Alt Gr" tipici dei desktop.
- **Standard (US)**: Ottimo per sistemi Linux e configurazioni hardware d'oltreoceano.
- **US INTL**: Modifica internazionale per gli shortcut combinati.

### Struttura Generale DuckyScript
Tutti gli script accettano i normali comandi standard:
```duckyscript
REM Questo è un commento
DELAY 1000
GUI r
DELAY 300
STRING notepad.exe
ENTER
DELAY 500
STRING Sei stato colpito dal Proximity Shark!
ENTER
```
> [!TIP]
> Sfrutta le tue cartelle sul telefono per categorizzare gli script in (es. `Windows`, `Linux`, `Pranks`, `Recon`).

## 5. Guida alla Wear OS Companion App

### Come Usare lo Smartwatch
1. Assicurati che il telefono e lo smartwatch siano nativamente connessi via Bluetooth nelle impostazioni di sistema e che Proximity Shark sia aperto sul telefono.
2. Apri `Proximity Shark` sul Wear OS.
   - **Pagina 1 (Sezione Scripts):** Vedrai "Sincronizzazione...", che dura pochi istanti; poi naviga nelle tue cartelle e tocca il payload desiderato.
   - **Pagina 2 (Dispositivi Paired):** Puoi dire al telefono a quale dispositivo obbiettivo collegarsi con un tap sull'orologio.
   - **Pagina 3 (Layouts):** Switch rapido e furtivo del layout a seconda del bersaglio.

> [!IMPORTANT]
> Proximity Shark Wear OS dispone di un'ottimizzazione estrema GZIP per la sincronizzazione simultanea di cartelle multiple. Puoi avere infinite cartelle al volo senza problemi di blocco o memory leak!

## 6. Stealth Hub & Privacy
Essendo uno strumento di Red Teaming avanzato:
- Ricorda di controllare il log del monitoraggio della Rete o l'indirizzo IP locale mostrato nell'Hub per confermare tunnel VPN / hotspot anonimi.
- Puoi cambiare al volo il nome Bluetooth fittizio (Broadcast Identity) (es. da "Proximity Shark" a "Logitech Keyboard" o "Apple Magic Mouse") affinché le vittime credano di associare una periferica innocua.

## 7. F.A.Q. e Risoluzione dei Problemi

**D: Il target non trova l'applicazione Bluetooth!**
*R: Spegni e riaccendi la modalità Discovery col pulsante apposito dall'app sul telefono per forzare l'Advertising dell'identità HID. Inoltre, verifica di aver accettato tutti i permessi nelle info dell'app.*

**D: Lo smartwatch rimane perennemente fermo su "Sincronizzazione..."**
*R: Significa che il layer DataClient di WearOS ha perso il bridge. Riapri l'applicazione sul telefono. Il telefono trasmette istantaneamente l'infrastruttura GZIP all'orologio ad ogni riapertura dell'app o aggiunta script.*

**D: Alcuni caratteri escono sbagliati (es. `?` o `_`)**
*R: Stai colpendo il target con un Layout di decodifica errato. Usare l'ambiente `Android (IT)` è vitale se stai penetrando LIM Helgi fisiche o Android Target custom.*

**D: La companion Wear OS va a scatti!**
*R: Assicurati di non star testando su Android Studio l'eseguibile di Debug. Le animazioni Jetpack Compose Wear OS girano a 60 FPS unicamente dopo aver buildato in Rilasciato (Release con R8 Minifier attivo).*

## 8. Disclaimer Legale
> [!CAUTION]
> **ESCLUSIONE DI RESPONSABILITÀ (EDUCATIONAL ONLY)**
> Questo strumento software, le routine del Parser e le istruzioni ad esso collegate sono fornite **solo ed esclusivamente per scopi di ricerca sulla sicurezza informatica (Red Teaming/Pentesting Etico)**.
> Qualsiasi uso non autorizzato per colpire sistemi, reti o device di cui non si possiede l'autorizzazione scritta costituisce un **reato informatico severamente punibile dalla legge**. Sviluppatore e contributori declinano esplicitamente ogni tipo di responsabilità per danni derivanti dall'utilizzo improprio. Usalo a tuo rischio.
