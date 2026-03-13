# ============================================================================
# SCRIPT DE SYNCHRONISATION - PRODUCTION HETZNER → LOCAL
# ============================================================================
# Description: Récupère automatiquement le backup de production depuis Hetzner
# Author: Claude Code
# Date: 2026-02-16
# Usage: .\sync-production-hetzner.ps1 -ServerIP "89.167.26.169" -User "root"
# ============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$ServerIP,

    [Parameter(Mandatory=$false)]
    [string]$User = "root",

    [Parameter(Mandatory=$false)]
    [string]$LocalBackupDir = "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\backup-cold"
)

# Couleurs pour output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Success { Write-ColorOutput Green $args }
function Write-Info { Write-ColorOutput Cyan $args }
function Write-Warning { Write-ColorOutput Yellow $args }
function Write-Error { Write-ColorOutput Red $args }

# Header
Write-Host ""
Write-Host "=============================================="
Write-Host "  SYNCHRONISATION PRODUCTION HETZNER"
Write-Host "=============================================="
Write-Host ""

# Vérifications préalables
Write-Info "[1/8] Vérifications préalables..."

# Vérifier si SSH est disponible
try {
    $sshVersion = ssh -V 2>&1
    Write-Success "  ✅ SSH disponible: $sshVersion"
} catch {
    Write-Error "  ❌ SSH non disponible. Installer OpenSSH Client."
    Write-Error "     Run: Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0"
    exit 1
}

# Vérifier si SCP est disponible
try {
    $scpHelp = scp 2>&1
    Write-Success "  ✅ SCP disponible"
} catch {
    Write-Error "  ❌ SCP non disponible."
    exit 1
}

# Tester la connexion au serveur
Write-Info "[2/8] Test de connexion au serveur $ServerIP..."
$testConnection = Test-NetConnection -ComputerName $ServerIP -Port 22 -WarningAction SilentlyContinue

if ($testConnection.TcpTestSucceeded) {
    Write-Success "  ✅ Serveur accessible (port 22 ouvert)"
} else {
    Write-Error "  ❌ Serveur inaccessible. Vérifier IP et firewall."
    exit 1
}

# Connexion SSH et création du backup
Write-Info "[3/8] Connexion SSH et création du backup sur le serveur..."
Write-Warning "  ⚠️  Vous allez devoir entrer le mot de passe SSH..."

$date = Get-Date -Format "yyyyMMdd"
$backupDir = "backup-mailwizz-$date"
$backupArchive = "backup-mailwizz-hetzner-production-$date.tar.gz"

# Script bash à exécuter sur le serveur
$bashScript = @"
#!/bin/bash
set -e

echo '==> Création du répertoire de backup...'
mkdir -p /root/$backupDir
cd /root/$backupDir

echo '==> Backup base de données MySQL...'
if systemctl is-active --quiet mariadb || systemctl is-active --quiet mysql; then
    mysqldump -u root mailapp 2>/dev/null | gzip > mailapp-production-$date.sql.gz
    echo '✅ Base de données sauvegardée'
else
    echo '❌ MySQL/MariaDB non actif'
    exit 1
fi

echo '==> Backup application MailWizz...'
if [ -d /var/www/mailwizz ]; then
    cd /var/www/
    tar -czf /root/$backupDir/mailwizz-production-$date.tar.gz \
      --exclude='mailwizz/apps/*/runtime/*' \
      --exclude='mailwizz/apps/*/cache/*' \
      mailwizz/ 2>/dev/null
    echo '✅ MailWizz sauvegardé'
else
    echo '❌ MailWizz non trouvé'
    exit 1
fi

echo '==> Backup configuration PowerMTA...'
if [ -f /etc/pmta/config ]; then
    cp /etc/pmta/config /root/$backupDir/pmta-config-production-$date
    cp /etc/pmta/license /root/$backupDir/pmta-license-production-$date 2>/dev/null || true
    echo '✅ Config PowerMTA sauvegardée'
else
    echo '⚠️  PowerMTA config non trouvée'
fi

echo '==> Backup clés DKIM...'
if [ -d /home/pmta/mail ]; then
    cp -r /home/pmta/mail /root/$backupDir/pmta-dkim/ 2>/dev/null || true
    echo '✅ Clés DKIM sauvegardées'
else
    echo '⚠️  Clés DKIM non trouvées'
fi

echo '==> Collecte informations système...'
pmta show version > /root/$backupDir/pmta-version.txt 2>/dev/null || echo 'pmta not installed' > /root/$backupDir/pmta-version.txt
pmta show status > /root/$backupDir/pmta-status.txt 2>/dev/null || echo 'pmta not running' > /root/$backupDir/pmta-status.txt
ip addr show | grep 'inet ' > /root/$backupDir/server-ips.txt

echo '==> Création archive finale...'
cd /root/
tar -czf $backupArchive $backupDir/
echo '✅ Archive créée: $backupArchive'

echo '==> Taille archive:'
ls -lh $backupArchive

echo '==> BACKUP TERMINÉ'
"@

# Sauvegarder le script bash temporairement
$tempBashScript = "$env:TEMP\backup-script-$date.sh"
$bashScript | Out-File -FilePath $tempBashScript -Encoding ASCII

# Transférer et exécuter le script sur le serveur
Write-Info "  → Upload du script de backup..."
scp $tempBashScript "${User}@${ServerIP}:/root/backup-script.sh"

Write-Info "  → Exécution du backup sur le serveur..."
ssh "${User}@${ServerIP}" "chmod +x /root/backup-script.sh && /root/backup-script.sh"

# Vérifier si le backup a réussi
Write-Info "[4/8] Vérification du backup sur le serveur..."
$remoteFileCheck = ssh "${User}@${ServerIP}" "ls -lh /root/$backupArchive 2>/dev/null"

if ($remoteFileCheck) {
    Write-Success "  ✅ Backup créé: $remoteFileCheck"
} else {
    Write-Error "  ❌ Backup non trouvé sur le serveur"
    exit 1
}

# Téléchargement du backup
Write-Info "[5/8] Téléchargement du backup..."
Write-Warning "  ⚠️  Cela peut prendre plusieurs minutes selon la taille..."

$tempDownloadPath = "$env:TEMP\$backupArchive"

try {
    scp "${User}@${ServerIP}:/root/$backupArchive" $tempDownloadPath
    Write-Success "  ✅ Téléchargement réussi"
} catch {
    Write-Error "  ❌ Échec du téléchargement: $_"
    exit 1
}

# Vérifier le fichier téléchargé
$downloadedFile = Get-Item $tempDownloadPath
Write-Info "  Taille téléchargée: $([math]::Round($downloadedFile.Length / 1MB, 2)) MB"

# Sauvegarder l'ancien backup-cold
Write-Info "[6/8] Sauvegarde de l'ancien backup-cold..."

if (Test-Path $LocalBackupDir) {
    $oldBackupName = "backup-cold-OLD-$date"
    $oldBackupPath = Join-Path (Split-Path $LocalBackupDir) $oldBackupName

    if (Test-Path $oldBackupPath) {
        Write-Warning "  ⚠️  $oldBackupName existe déjà, suppression..."
        Remove-Item -Path $oldBackupPath -Recurse -Force
    }

    Rename-Item -Path $LocalBackupDir -NewName $oldBackupName
    Write-Success "  ✅ Ancien backup sauvegardé: $oldBackupName"
} else {
    Write-Info "  → Pas d'ancien backup-cold à sauvegarder"
}

# Créer nouveau répertoire backup-cold
New-Item -ItemType Directory -Path $LocalBackupDir -Force | Out-Null
Write-Success "  ✅ Nouveau répertoire backup-cold créé"

# Extraire l'archive
Write-Info "[7/8] Extraction de l'archive..."

# Déplacer l'archive dans backup-cold
Move-Item -Path $tempDownloadPath -Destination $LocalBackupDir -Force

# Extraire avec tar (Windows 10+ natif)
Push-Location $LocalBackupDir
try {
    tar -xzf $backupArchive
    Write-Success "  ✅ Archive extraite"

    # Déplacer le contenu du sous-dossier vers la racine
    $extractedFolder = Join-Path $LocalBackupDir $backupDir
    if (Test-Path $extractedFolder) {
        Get-ChildItem -Path $extractedFolder | Move-Item -Destination $LocalBackupDir -Force
        Remove-Item -Path $extractedFolder -Force
        Write-Success "  ✅ Fichiers organisés"
    }

    # Supprimer l'archive tar.gz (optionnel)
    # Remove-Item -Path $backupArchive -Force

} catch {
    Write-Error "  ❌ Erreur lors de l'extraction: $_"
    Pop-Location
    exit 1
}
Pop-Location

# Créer fichier d'information
Write-Info "[8/8] Création du fichier d'information..."

$backupInfo = @"
==========================================================
BACKUP RÉCUPÉRÉ DEPUIS PRODUCTION HETZNER
==========================================================

Date backup : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Serveur source : $ServerIP
Utilisateur : $User
Taille archive : $([math]::Round($downloadedFile.Length / 1MB, 2)) MB

Contenu :
- Base de données MailWizz : mailapp-production-$date.sql.gz
- Application MailWizz : mailwizz-production-$date.tar.gz
- Config PowerMTA : pmta-config-production-$date
- Clés DKIM : pmta-dkim/ (si présent)
- Info système : pmta-version.txt, pmta-status.txt, server-ips.txt

Script utilisé : sync-production-hetzner.ps1
Archive originale : $backupArchive (conservée)

==========================================================
"@

$backupInfo | Out-File -FilePath "$LocalBackupDir\BACKUP-INFO-$date.txt" -Encoding UTF8
Write-Success "  ✅ Fichier d'information créé"

# Nettoyage serveur (optionnel)
Write-Info ""
Write-Warning "NETTOYAGE SERVEUR (recommandé) :"
$cleanup = Read-Host "Supprimer le backup du serveur ? (y/N)"

if ($cleanup -eq "y" -or $cleanup -eq "Y") {
    Write-Info "→ Suppression du backup sur le serveur..."
    ssh "${User}@${ServerIP}" "rm -rf /root/$backupDir /root/$backupArchive /root/backup-script.sh"
    Write-Success "✅ Backup supprimé du serveur"
} else {
    Write-Warning "⚠️  Backup conservé sur le serveur : /root/$backupArchive"
    Write-Warning "   Pensez à le supprimer manuellement pour libérer l'espace"
}

# Nettoyage local temporaire
Remove-Item -Path $tempBashScript -Force -ErrorAction SilentlyContinue

# Récapitulatif final
Write-Host ""
Write-Host "=============================================="
Write-Success "  SYNCHRONISATION TERMINÉE"
Write-Host "=============================================="
Write-Host ""
Write-Info "Nouveau backup-cold :"
Write-Host "  📁 $LocalBackupDir"
Write-Host ""
Write-Info "Ancien backup sauvegardé :"
Write-Host "  📁 backup-cold-OLD-$date"
Write-Host ""
Write-Info "Contenu récupéré :"
Get-ChildItem -Path $LocalBackupDir -File | ForEach-Object {
    Write-Host "  - $($_.Name) ($([math]::Round($_.Length / 1MB, 2)) MB)"
}
Write-Host ""
Write-Success "✅ Votre backup-cold est maintenant à jour avec la production Hetzner!"
Write-Host ""

# Ouvrir l'explorateur de fichiers
$openExplorer = Read-Host "Ouvrir le dossier backup-cold ? (Y/n)"
if ($openExplorer -ne "n" -and $openExplorer -ne "N") {
    explorer.exe $LocalBackupDir
}
