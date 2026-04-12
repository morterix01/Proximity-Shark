# 🦈 Proximity Shark – The Official Wiki 🌊

Benvenuto nell'abisso! Preparati a trasformare il tuo telefono (e il tuo inseparabile smartwatch) in uno strumento di pentesting Bluetooth che farebbe invidia a un agente segreto. 🕵️‍♂️🔥

Con **Proximity Shark**, non serve nessun dongle USB o hardware costoso. Sfrutti i chip Bluetooth del tuo dispositivo per colpire in incognito, emulando una vera e propria tastiera fisica a distanza. Pronto ad azzannare? Sincronizza l'orologio. ⌚🦈

---

## 📑 Indice dell'Abisso

1. [Benvenuto a Bordo! 🌊](#1-benvenuto-a-bordo-)
2. [Equipaggiamento Rapido 🛠️](#2-equipaggiamento-rapido-)
3. [I Tuoi Nuovi Superpoteri 🧠](#3-i-tuoi-nuovi-superpoteri-)
4. [L'Arte dei Payload & Layout Magici ⌨️](#4-larte-dei-payload--layout-magici-)
5. [Agente 007 al Polso: Guidare Wear OS 🎯](#5-agente-007-al-polso-guidare-wear-os-)
6. [Modalità Fantasma: Lo Stealth Hub 👻](#6-modalit-fantasma-lo-stealth-hub-)
7. [Pronto Soccorso (F.A.Q.) 🚑](#7-pronto-soccorso-faq-)
8. [Il Patto di Sangue (Disclaimer) 📜](#8-il-patto-di-sangue-disclaimer-)

---

## 1. Benvenuto a Bordo! 🌊
Ti sei mai chiesto come sarebbe poter controllare PC, tablet, e perfino lavagne interattive LIM senza mai farti vedere? **Proximity Shark** è la risposta. Funziona trasmettendo script furtivi tramite una finta connessione tastiera (HID - Human Interface Device) via Bluetooth. Non lasci impronte fisiche. Non infili chiavette USB. 

**I tuoi vantaggi:**
- **Zero Tracce Hardware:** Nessun dongle da comprare, usi solo quello che hai in tasca. 📱
- **Il Controllo Assoluto sull'Orologio:** Fai partire l'attacco senza nemmeno sbloccare lo smartphone. Boom. 💥
- **Intelligenza Multi-Layout:** Algoritmi folli in grado di ingannare tastiere virtuali Windows, Android o standard d'oltreoceano e inserire il payload alla perfezione!

## 2. Equipaggiamento Rapido 🛠️
Vuoi tuffarti subito? Ecco cosa fare:
1. **Per lo Smartphone:** Vai fiondato nella sezione [Releases](https://github.com/morterix01/Proximity-Shark/releases) e scarica `app-release.apk`.
2. **Per l'Orologio (Wear OS):** Procurati anche il file Companion. Lo installi sullo smartwatch tramite ADB via Wi-Fi o app di debug (es. `adb -s <IP_WATCH:PORT> install Proximity-Shark-WearOS.apk`). 
3. **Dammi i Permessi!** Al primo avvio dovrai concedere tutti i permessi Bluetooth, Posizione e Notifiche. Sii generoso, o il tuo Squalo non avrà i denti per azzannare (si disattiverà il profilo della tastiera)! 🦈

## 3. I Tuoi Nuovi Superpoteri 🧠

🖥️ **Lo Smartphone (Il Cervello):**
Qui prepari il colpo.
- Organizzi comodamente migliaia di script (anche dividendoli in pratiche cartelle). 📂
- Assumi identità fittizie Bluetooth o tieni d'occhio lo stato ip all'interno dell'app. 🕵️‍♀️

⌚ **Lo Smartwatch (Il Grilletto):**
Il braccio armato del piano.
- Sincronizza al volo, e magicamente senza ritardi (è compresso in *GZIP/Base64*!) le tua intera struttura di cartelle personalizzate.
- Selezioni il layout, prendi la mira verso il PC associato, e ordini il via del Payload. 
- Avrai sempre feedback istantaneo! Verde ✅ *Payload inserito*, Rosso ❌ *Qualcosa è andato storto*.

## 4. L'Arte dei Payload & Layout Magici ⌨️

### Smetti di cliccare a vuoto: Il Tuo Target Conta! 🎯
Sapevi che la lettera `@` in un computer americano viene scritta diversamente da uno italiano? Ecco perché Proximity Shark possiede un motore di trascrizione chirurgico:
- 🍕 **PC (IT)**: L'asso nella manica in Italia. Gestisce magistralmente Shift e AltGr standard per qualsiasi PC Windows italiano che trovi di fronte.
- 🤖 **Android (IT)**: Questa è vera magia. Supera firewall virtuali ignorando vecchi schemi AltGr di Android. Perfetto per hackerare le grosse **Lavagne Interattive e LIM (tipo Helgi)** a scuola o in ufficio!
- 🦅 **Standard (US)**: Ottimo per sistemi Linux e configurazioni estere pulite.
- 🌐 **US INTL**: Modifica internazionale avanzata. Perfetto come coltellino svizzero.

### Parla Serio con DuckyScript 🦆
Il linguaggio che parla lo Squalo:
```duckyscript
REM Questo comando non serve a nulla, è solo un commento! 😉
DELAY 1000
GUI r
DELAY 300
STRING notepad.exe
ENTER
DELAY 500
STRING Lo Squalo di prossimità ha colpito ancora! 🦈💦
ENTER
```
> [!TIP]
> 💡 Sii saggio: raggruppa i tuoi script testuali `.txt` sul telefono in mega-cartelle (es. `Mac_Payloads`, `Windows`, `Scherzi_Epici`). L'Orologio li sfoglierà comodamente uno per uno in tempo reale!

## 5. Agente 007 al Polso: Guidare Wear OS 🎯

Niente panico, usare l'orologio è come giocare a tris:
1. Collega normalmente il telefono al watch. Accendi l'app Proximity dal telefono, poi apri la companion sull'orologio.
2. Scorri verticalmente e orizzontalmente in modo naturalissimo:
   - 📁 **Centro Comandi:** Ti appare "Sincronizzazione..." per mezzo secondo (seleziona quindi cartelle e Payload).
   - 📡 **Menu Destra/Sinistra:** Gestisci il tuo Target corrente con la spunta verde (quale dispositivo colpirai) e la tua modalità d'attacco preferita (il famigerato Layout IT/US).

> [!IMPORTANT]
> 🔥 La UI sull'orologio vola. Se l'hai scaricata ufficialmente (Modalità *Release R8*), viaggerà fluidissima a 60 FPS senza mai battere ciglio, indipendentemente dalla grandezza folle delle tue cartelle Script!

## 6. Modalità Fantasma: Lo Stealth Hub 👻
L'Hub è il tuo radar di sicurezza privato.
Sei collegato a un hotspot losco? Verifica nel radar del tuo Stealth Hub l'IP di aggancio prima di lanciare payload compromettenti.
Vuoi essere meno sospetto di una chiavetta "BadUSB" col nome in formato alieno? Trascina l'Identità Bluetooth in basso e cambia istantaneamente il tuo finto nome.
Sei "Proximity Shark", ma per il PC del bersaglio puoi comodamente diventare la sua dolce *"Logitech MX Master"* in due tap. 🦇💻

## 7. Pronto Soccorso (F.A.Q.) 🚑

**D: Ops! Il telefono / il pc della vittima non rileva la finta tastiera!**
*R: Fiammata improvvisa! Spegni e riaccendi lo "Shark Control" in cima all'app, forzerà il target a vedere il tuo nuovo, finto "Identity" e ti paleserai nella sua lista Bluetooth.*

**D: L'orologio lagga stranamente e scatta.**
*R: Questo significa che hai compilato a mano l'app in modalità DEBUG! Torna da bravo programmatore ad Android Studio, esci dalla caverna e compila l'app Wear OS come build di "**Release**". Rivedrai i 60fps!*

**D: Ho scritto un payload favoloso ma mi sputa accenti a vanvera (`&/?...`)!**
*R: Non dare la colpa allo Squalo! Probabilmente il server/PC su cui stai digitando i Payload ha un'impostazione di sistema in Inglese (US), ma tu hai forzato nel polso Proximity Shark su Layout `PC (IT)`. Switcha il profilo all'ultimo secondo!*

## 8. Il Patto di Sangue (Disclaimer) 📜
> [!CAUTION]
> **IL VANGELO DELL'HACKER ETICO (SOLO SCOPI EDUCATIVI)**🚨
> Noi adoriamo Proximity Shark, ma le cose in chiaro: questo strumento è una navicella progettata unicamente per la Ricerca, la Cybersecurity e i Red Team (Pentesting). 
> Penetrare un computer a cui il proprietario NON ti ha esplicitamente dato il consenso è un **reato reale e ti sbatte nei guai seriamente**. Nessuno degli sviluppatori vi rimborserà, si assumerà la colpa o scriverà lettere per giustificarvi.
> Fai l'Hacker, non il Criminale. Usa i tuoi superpoteri in maniera responsabile! 🤍🦈
