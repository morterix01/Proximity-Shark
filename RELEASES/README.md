# ProximityShark Releases

Questa cartella contiene gli APK di rilascio di **Proximity Shark**.

---

## 📁 Struttura

```
RELEASES/
└── ProximityShark_v1.1.0/
    ├── ProximityShark_v1.1.0_android.apk   ← App per telefono Android
    └── (futuro) ProximityShark_v1.1.0_OS.apk  ← App Wear OS
```

---

## 📦 Come ottenere gli APK

### Metodo 1 — GitHub Actions (consigliato, nessun SDK richiesto)
1. Vai su [github.com/morterix01/Proximity-Shark/actions](https://github.com/morterix01/Proximity-Shark/actions)
2. Clicca su **"Build ProximityShark APKs"**
3. Clicca **"Run workflow"** → **"Run workflow"**
4. Aspetta ~3 minuti
5. Scarica l'APK dalla sezione **Artifacts**

### Metodo 2 — Build locale (richiede Android SDK)
```powershell
# Dalla root del progetto:
.\build_local.ps1

# Se il SDK è in una cartella personalizzata:
.\build_local.ps1 -AndroidSdkPath "C:\path\al\AndroidSdk"
```

---

## 🗂 Versioni

| Versione | Data | Note |
|---|---|---|
| v1.1.0 | 2026-05-04 | Panic Button, Taskkill slide, Ghiera Wear OS, Win11 stability |
| v1.0.8 | precedente | Base release |
