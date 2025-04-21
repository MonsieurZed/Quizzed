$sourceFolder = "D:\GIT\quizzzed\assets\images\avatars1024"
$destFolder = "D:\GIT\quizzzed\assets\images\avatars"

# Créer le dossier de destination s'il n'existe pas
if (-not (Test-Path $destFolder)) {
    New-Item -ItemType Directory -Path $destFolder | Out-Null
}

# Charger les types nécessaires
Add-Type -AssemblyName System.Drawing

# Extensions supportées
$extensions = "*.png", "*.jpg", "*.jpeg"

foreach ($ext in $extensions) {
    Get-ChildItem -Path $sourceFolder -Filter $ext -File | ForEach-Object {
        try {
            Write-Host "→ Traitement de $($_.Name)"

            $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
            $ms = New-Object System.IO.MemoryStream(, $bytes)
            $img = [System.Drawing.Image]::FromStream($ms)

            $newWidth = [int]($img.Width / 4)
            $newHeight = [int]($img.Height / 4)

            $bitmap = New-Object System.Drawing.Bitmap $newWidth, $newHeight
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.DrawImage($img, 0, 0, $newWidth, $newHeight)

            $destPath = Join-Path $destFolder $_.Name
            $bitmap.Save($destPath, $img.RawFormat)

            $graphics.Dispose()
            $bitmap.Dispose()
            $img.Dispose()
            $ms.Dispose()

            Write-Host "Image redimensionnée : $($_.Name)"
        }
        catch {
            Write-Warning ("Erreur avec l'image {0} : {1}" -f $_.Name, $_.Exception.Message)
        }
    }
}
