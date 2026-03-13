# ============================================================================
# SCRIPT DE PREPARATION DES FICHIERS POUR UPLOAD HETZNER
#
# Execute ce script pour preparer tous les fichiers necessaires au deploiement
# ============================================================================

$ErrorActionPreference = "Stop"

# Chemin de base
$OutilsPath = Split-Path -Parent $PSScriptRoot
$BackupPath = Join-Path $OutilsPath "backup-cold"
$OutputPath = Join-Path $OutilsPath "upload-package"

Write-Host "=========================================="
Write-Host "  PREPARATION UPLOAD HETZNER"
Write-Host "=========================================="
Write-Host ""

# Creer le dossier de sortie
if (Test-Path $OutputPath) {
    Remove-Item -Recurse -Force $OutputPath
}
New-Item -ItemType Directory -Path $OutputPath | Out-Null

Write-Host "[1/6] Copie du package PowerMTA..."
Copy-Item (Join-Path $BackupPath "rpm-install-pmta-5.zip") $OutputPath

Write-Host "[2/6] Copie du package MailWizz..."
Copy-Item (Join-Path $BackupPath "mailwizz.zip") $OutputPath

Write-Host "[3/6] Copie du dump SQL..."
Copy-Item (Join-Path $BackupPath "mailapp-reference.sql") $OutputPath

Write-Host "[4/6] Copie de la configuration PMTA..."
$PmtaEtcDest = Join-Path $OutputPath "pmta-etc"
New-Item -ItemType Directory -Path $PmtaEtcDest | Out-Null
Copy-Item (Join-Path $BackupPath "pmta-etc\config.hetzner.template") $PmtaEtcDest
Copy-Item (Join-Path $BackupPath "pmta-etc\bounce-classifications") $PmtaEtcDest
Copy-Item (Join-Path $BackupPath "pmta-etc\license") $PmtaEtcDest
Copy-Item (Join-Path $BackupPath "pmta-etc\routing-domains") $PmtaEtcDest

Write-Host "[5/6] Copie des cles DKIM..."
$DkimDest = Join-Path $OutputPath "pmta-dkim"
New-Item -ItemType Directory -Path $DkimDest | Out-Null
New-Item -ItemType Directory -Path (Join-Path $DkimDest "mail\ulixai-expat.com") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $DkimDest "mail\mail-ulixai.com") -Force | Out-Null

Copy-Item (Join-Path $BackupPath "pmta-dkim\mail\ulixai-expat.com\dkim.pem") (Join-Path $DkimDest "mail\ulixai-expat.com\")
Copy-Item (Join-Path $BackupPath "pmta-dkim\mail\mail-ulixai.com\dkim.pem") (Join-Path $DkimDest "mail\mail-ulixai.com\")

Write-Host "[6/6] Copie du script de deploiement..."
Copy-Item (Join-Path $OutilsPath "scripts\deploy-hetzner.sh") $OutputPath

Write-Host ""
Write-Host "=========================================="
Write-Host "  PACKAGE PRET!"
Write-Host "=========================================="
Write-Host ""
Write-Host "Dossier: $OutputPath"
Write-Host ""
Write-Host "Fichiers a uploader sur le serveur Hetzner:"
Get-ChildItem -Recurse $OutputPath | ForEach-Object {
    $relativePath = $_.FullName.Replace($OutputPath, "").TrimStart("\")
    if (-not $_.PSIsContainer) {
        $size = [math]::Round($_.Length / 1MB, 2)
        Write-Host "  - $relativePath ($size MB)"
    }
}
Write-Host ""
Write-Host "COMMANDE SCP (depuis PowerShell):"
Write-Host "  scp -r `"$OutputPath\*`" root@VOTRE_IP_HETZNER:/root/"
Write-Host ""
Write-Host "PUIS SUR LE SERVEUR:"
Write-Host "  1. Editer deploy-hetzner.sh (IPs, mots de passe)"
Write-Host "  2. chmod +x deploy-hetzner.sh"
Write-Host "  3. ./deploy-hetzner.sh"
Write-Host ""
