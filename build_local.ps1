# ─── ProximityShark v1.1.0 — Script build locale ─────────────────────────────
# Esegui questo script in PowerShell dalla root del progetto
# Richiede: Flutter SDK + Android SDK installati

param(
    [string]$AndroidSdkPath = ""
)

$version = "1.1.0"
$buildNumber = "9"
$outDir = "RELEASES\ProximityShark_v$version"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  🦈 ProximityShark v$version — Build Locale          ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── Check Flutter ──────────────────────────────────────────────────────────────
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Flutter non trovato nel PATH. Installalo da https://flutter.dev" -ForegroundColor Red
    exit 1
}

# ── Set Android SDK se passato come argomento ──────────────────────────────────
if ($AndroidSdkPath -ne "") {
    $env:ANDROID_HOME = $AndroidSdkPath
    $env:ANDROID_SDK_ROOT = $AndroidSdkPath
    Write-Host "✔ ANDROID_HOME impostato a: $AndroidSdkPath" -ForegroundColor Green
}

# ── Check Android SDK ──────────────────────────────────────────────────────────
$sdkCheck = flutter doctor 2>&1 | Select-String "Android toolchain"
if ($sdkCheck -match "\[X\]") {
    Write-Host ""
    Write-Host "❌ Android SDK non trovato!" -ForegroundColor Red
    Write-Host "   Installa Android Studio da: https://developer.android.com/studio" -ForegroundColor Yellow
    Write-Host "   oppure esegui: .\build_local.ps1 -AndroidSdkPath 'C:\path\al\sdk'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   In alternativa, usa GitHub Actions:" -ForegroundColor Cyan
    Write-Host "   → Vai su github.com/morterix01/Proximity-Shark/actions" -ForegroundColor Cyan
    Write-Host "   → Seleziona 'Build ProximityShark APKs'" -ForegroundColor Cyan
    Write-Host "   → Clicca 'Run workflow'" -ForegroundColor Cyan
    Write-Host "   → Scarica l'APK dagli Artifacts" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

# ── Crea cartella output ───────────────────────────────────────────────────────
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Write-Host "📁 Output: $outDir" -ForegroundColor Cyan
Write-Host ""

# ── flutter pub get ────────────────────────────────────────────────────────────
Write-Host "📦 Installazione dipendenze..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) { Write-Host "❌ flutter pub get fallito" -ForegroundColor Red; exit 1 }

# ── Patch flutter_wear_os_connectivity per AGP 8.0 ─────────────────────────────
Write-Host "🔧 Applicazione patch namespace per flutter_wear_os_connectivity..." -ForegroundColor Yellow
# Path can be in PUB_CACHE environment variable or LocalAppData
$pubCache = if ($env:PUB_CACHE) { $env:PUB_CACHE } else { "$env:LOCALAPPDATA\Pub\Cache" }
$pluginDir = "$pubCache\hosted\pub.dev\flutter_wear_os_connectivity-1.0.0\android\src\main"
$manifestPath = "$pluginDir\AndroidManifest.xml"

if (Test-Path $manifestPath) {
    $content = Get-Content $manifestPath -Raw
    if ($content -match 'package="com\.sstonn\.flutter_wear_os_connectivity"') {
        $content = $content -replace 'package="com\.sstonn\.flutter_wear_os_connectivity"', ''
        Set-Content -Path $manifestPath -Value $content
        Write-Host "✅ Patch applicata con successo." -ForegroundColor Green
    } else {
        Write-Host "ℹ️ Patch già applicata o attributo package non trovato." -ForegroundColor DarkGray
    }
} else {
    Write-Host "⚠️ Impossibile trovare AndroidManifest.xml del plugin per la patch." -ForegroundColor Yellow
}

# ── Build Android APK (arm64) ──────────────────────────────────────────────────
Write-Host ""
Write-Host "🔨 Build Android APK (arm64)..." -ForegroundColor Yellow
flutter build apk --release --target-platform android-arm64 `
    --build-name=$version --build-number=$buildNumber

if ($LASTEXITCODE -ne 0) { Write-Host "❌ Build Android fallita" -ForegroundColor Red; exit 1 }

$apkSrc = "build\app\outputs\flutter-apk\app-release.apk"
$apkDst = "$outDir\ProximityShark_v${version}_android.apk"
Copy-Item $apkSrc $apkDst
Write-Host "✅ APK Android → $apkDst" -ForegroundColor Green

# ── Riepilogo ──────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅ Build completata!                                 ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "File prodotti:" -ForegroundColor White
Get-ChildItem $outDir | ForEach-Object {
    $size = [math]::Round($_.Length / 1MB, 1)
    Write-Host "  📦 $($_.Name)  ($size MB)" -ForegroundColor Cyan
}
Write-Host ""
