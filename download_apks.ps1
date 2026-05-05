$folder = "$HOME\Desktop\ProximityShark_APKs"
New-Item -ItemType Directory -Force -Path $folder | Out-Null

$androidUrl = "https://github.com/morterix01/Proximity-Shark/releases/download/v1.1.0/ProximityShark_v1.1.0_android.apk"
$osUrl = "https://github.com/morterix01/Proximity-Shark-WearOS/releases/download/v1.1.0/ProximityShark_v1.1.0_OS.apk"

$androidDest = "$folder\ProximityShark_v1.1.0_android.apk"
$osDest = "$folder\ProximityShark_v1.1.0_OS.apk"

function Wait-And-Download {
    param([string]$Url, [string]$Dest)
    Write-Host "In attesa che l'APK sia pronto sul server ($Url)..."
    $maxRetries = 30
    $retry = 0
    while ($retry -lt $maxRetries) {
        try {
            $response = Invoke-WebRequest -Uri $Url -Method Head -ErrorAction Stop
            if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 302) {
                Write-Host "L'APK è pronto. Download in corso..."
                Invoke-WebRequest -Uri $Url -OutFile $Dest
                Write-Host "Download completato: $Dest"
                return
            }
        } catch {
            # Attendiamo
        }
        Start-Sleep -Seconds 15
        $retry++
    }
    Write-Host "Timeout per il download di $Url"
}

Wait-And-Download -Url $androidUrl -Dest $androidDest
Wait-And-Download -Url $osUrl -Dest $osDest

# Apre la cartella alla fine
Invoke-Item $folder
