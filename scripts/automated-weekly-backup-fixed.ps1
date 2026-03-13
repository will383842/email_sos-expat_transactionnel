# ============================================================================
# SCRIPT DE SAUVEGARDE HEBDOMADAIRE AUTOMATIQUE - VERSION CORRIGÉE
# ============================================================================
# Description: Sauvegarde automatique avec rotation (garde 2 backups max)
# Author: Claude Code
# Date: 2026-02-16
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$ServerIP = "46.62.168.55",

    [Parameter(Mandatory=$false)]
    [string]$User = "root",

    [Parameter(Mandatory=$false)]
    [string]$BaseBackupDir = "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\backups-auto",

    [Parameter(Mandatory=$false)]
    [int]$MaxBackups = 2,

    [Parameter(Mandatory=$false)]
    [string]$LogFile = "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\logs\backup-hebdo.log"
)

# Fonctions
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    $logDir = Split-Path $LogFile -Parent
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    Write-Host $logMessage
    Add-Content -Path $LogFile -Value $logMessage
}

# Début
Write-Log "========================================" "INFO"
Write-Log "DÉBUT SAUVEGARDE HEBDOMADAIRE" "INFO"
Write-Log "========================================" "INFO"

$startTime = Get-Date
$date = Get-Date -Format "yyyyMMdd-HHmmss"
$backupName = "mailwizz-backup-$date"
$backupDir = Join-Path $BaseBackupDir $backupName

# Créer répertoire backups-auto
if (!(Test-Path $BaseBackupDir)) {
    New-Item -ItemType Directory -Path $BaseBackupDir -Force | Out-Null
    Write-Log "Répertoire backups-auto créé" "SUCCESS"
}

# Créer répertoire pour ce backup
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

# Créer script bash pour le serveur
$bashScript = @'
#!/bin/bash
set -e
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/root/backup-hebdo-$DATE"
mkdir -p $BACKUP_DIR

# Backup MySQL
mysqldump -u root mailapp 2>/dev/null | gzip > $BACKUP_DIR/mailapp-$DATE.sql.gz

# Backup MailWizz
cd /var/www/
tar -czf $BACKUP_DIR/mailwizz-$DATE.tar.gz --exclude='mailwizz/apps/*/runtime/*' --exclude='mailwizz/apps/*/cache/*' mailwizz/ 2>/dev/null

# Backup PowerMTA
[ -f /etc/pmta/config ] && cp /etc/pmta/config $BACKUP_DIR/pmta-config-$DATE
[ -f /etc/pmta/license ] && cp /etc/pmta/license $BACKUP_DIR/pmta-license-$DATE
[ -d /home/pmta/mail ] && cp -r /home/pmta/mail $BACKUP_DIR/pmta-dkim/ 2>/dev/null

# Archive
cd /root/
tar -czf backup-hebdo-$DATE.tar.gz backup-hebdo-$DATE/
rm -rf backup-hebdo-$DATE/
echo "backup-hebdo-$DATE.tar.gz"
'@

# Sauvegarder script temporairement avec line endings Unix
$tempScript = "$env:TEMP\backup-hebdo-$date.sh"
$bashScript -replace "`r`n", "`n" | Out-File -FilePath $tempScript -Encoding UTF8 -NoNewline
Add-Content -Path $tempScript -Value "`n" -NoNewline

Write-Log "[1/5] Upload et exécution script sur serveur..." "INFO"

# Upload script
scp $tempScript "${User}@${ServerIP}:/root/backup-script.sh" 2>&1 | Out-Null

# Exécuter
$output = ssh "${User}@${ServerIP}" "chmod +x /root/backup-script.sh && /root/backup-script.sh 2>&1"
$archiveName = ($output | Select-Object -Last 1).Trim()

Write-Log "Archive créée: $archiveName" "SUCCESS"

# Télécharger
Write-Log "[2/5] Téléchargement..." "INFO"
scp "${User}@${ServerIP}:/root/$archiveName" "$backupDir\" 2>&1 | Out-Null

$downloadedFile = Get-Item "$backupDir\$archiveName"
$sizeInMB = [math]::Round($downloadedFile.Length / 1MB, 2)
Write-Log "Téléchargé: $sizeInMB MB" "SUCCESS"

# Extraire
Write-Log "[3/5] Extraction..." "INFO"
Push-Location $backupDir
tar -xzf $archiveName 2>&1 | Out-Null

$extractedFolder = Get-ChildItem -Directory | Where-Object { $_.Name -like "backup-hebdo-*" } | Select-Object -First 1
if ($extractedFolder) {
    Get-ChildItem -Path $extractedFolder.FullName | Move-Item -Destination $backupDir -Force
    Remove-Item -Path $extractedFolder.FullName -Force
}
Pop-Location

Write-Log "Archive extraite" "SUCCESS"

# Rotation
Write-Log "[4/5] Rotation des backups (max: $MaxBackups)..." "INFO"

$allBackups = Get-ChildItem -Path $BaseBackupDir -Directory |
              Where-Object { $_.Name -like "mailwizz-backup-*" } |
              Sort-Object Name -Descending

Write-Log "Backups actuels: $($allBackups.Count)" "INFO"

if ($allBackups.Count -gt $MaxBackups) {
    $backupsToDelete = $allBackups | Select-Object -Skip $MaxBackups
    foreach ($oldBackup in $backupsToDelete) {
        Write-Log "Suppression: $($oldBackup.Name)" "WARNING"
        Remove-Item -Path $oldBackup.FullName -Recurse -Force
    }
}

# Nettoyage serveur
Write-Log "[5/5] Nettoyage serveur..." "INFO"
ssh "${User}@${ServerIP}" "rm -f /root/$archiveName /root/backup-script.sh" 2>&1 | Out-Null

Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue

# Récapitulatif
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Log "========================================" "INFO"
Write-Log "SAUVEGARDE TERMINÉE" "SUCCESS"
Write-Log "========================================" "INFO"
Write-Log "Durée: $($duration.TotalMinutes.ToString('0.00')) minutes" "INFO"
Write-Log "Backup: $backupName" "INFO"
Write-Log "Taille: $sizeInMB MB" "INFO"

exit 0
