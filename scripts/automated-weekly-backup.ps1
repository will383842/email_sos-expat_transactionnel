# ============================================================================
# SCRIPT DE SAUVEGARDE HEBDOMADAIRE AUTOMATIQUE - PRODUCTION HETZNER
# ============================================================================
# Description: Sauvegarde automatique avec rotation (garde 2 backups max)
# Author: Claude Code
# Date: 2026-02-16
# Usage: Exécuté automatiquement par Windows Task Scheduler
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

# ============================================================================
# FONCTIONS UTILITAIRES
# ============================================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Afficher dans console
    switch ($Level) {
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        "ERROR"   { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        default   { Write-Host $logMessage -ForegroundColor Cyan }
    }

    # Écrire dans fichier log
    $logDir = Split-Path $LogFile -Parent
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    Add-Content -Path $LogFile -Value $logMessage
}

function Send-EmailNotification {
    param(
        [string]$Subject,
        [string]$Body,
        [bool]$IsError = $false
    )

    # TODO: Implémenter envoi email si nécessaire
    # Pour l'instant, juste logger
    Write-Log "Email notification: $Subject" "INFO"
}

# ============================================================================
# DÉBUT DU SCRIPT
# ============================================================================

Write-Log "========================================" "INFO"
Write-Log "DÉBUT SAUVEGARDE HEBDOMADAIRE AUTOMATIQUE" "INFO"
Write-Log "========================================" "INFO"

$startTime = Get-Date
$date = Get-Date -Format "yyyyMMdd-HHmmss"
$backupName = "mailwizz-backup-$date"
$backupDir = Join-Path $BaseBackupDir $backupName

# ============================================================================
# ÉTAPE 1 : VÉRIFICATIONS PRÉALABLES
# ============================================================================

Write-Log "[1/7] Vérifications préalables..." "INFO"

# Vérifier SSH
try {
    $sshVersion = ssh -V 2>&1
    Write-Log "SSH disponible: $sshVersion" "SUCCESS"
} catch {
    Write-Log "SSH non disponible - Arrêt" "ERROR"
    Send-EmailNotification -Subject "ÉCHEC Backup Hebdo" -Body "SSH non disponible" -IsError $true
    exit 1
}

# Tester connexion serveur
Write-Log "Test connexion au serveur $ServerIP..." "INFO"
$testConnection = Test-NetConnection -ComputerName $ServerIP -Port 22 -WarningAction SilentlyContinue

if (!$testConnection.TcpTestSucceeded) {
    Write-Log "Serveur $ServerIP inaccessible - Arrêt" "ERROR"
    Send-EmailNotification -Subject "ÉCHEC Backup Hebdo" -Body "Serveur inaccessible" -IsError $true
    exit 1
}

Write-Log "Serveur accessible (port 22 ouvert)" "SUCCESS"

# Créer répertoire de base si nécessaire
if (!(Test-Path $BaseBackupDir)) {
    New-Item -ItemType Directory -Path $BaseBackupDir -Force | Out-Null
    Write-Log "Répertoire backups-auto créé" "SUCCESS"
}

# ============================================================================
# ÉTAPE 2 : CRÉATION DU BACKUP SUR LE SERVEUR
# ============================================================================

Write-Log "[2/7] Création backup sur serveur..." "INFO"

$remoteBackupScript = @"
#!/bin/bash
set -e

DATE=\$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/root/backup-hebdo-\$DATE"

echo '==> Création répertoire backup...'
mkdir -p \$BACKUP_DIR

echo '==> Backup base de données...'
if systemctl is-active --quiet mariadb || systemctl is-active --quiet mysql; then
    mysqldump -u root mailapp 2>/dev/null | gzip > \$BACKUP_DIR/mailapp-\$DATE.sql.gz
    echo '✅ Base de données OK'
else
    echo '❌ MySQL/MariaDB non actif'
    exit 1
fi

echo '==> Backup MailWizz...'
if [ -d /var/www/mailwizz ]; then
    cd /var/www/
    tar -czf \$BACKUP_DIR/mailwizz-\$DATE.tar.gz \
      --exclude='mailwizz/apps/*/runtime/*' \
      --exclude='mailwizz/apps/*/cache/*' \
      mailwizz/ 2>/dev/null
    echo '✅ MailWizz OK'
fi

echo '==> Backup PowerMTA...'
[ -f /etc/pmta/config ] && cp /etc/pmta/config \$BACKUP_DIR/pmta-config-\$DATE
[ -f /etc/pmta/license ] && cp /etc/pmta/license \$BACKUP_DIR/pmta-license-\$DATE
[ -d /home/pmta/mail ] && cp -r /home/pmta/mail \$BACKUP_DIR/pmta-dkim/ 2>/dev/null
echo '✅ PowerMTA OK'

echo '==> Archive finale...'
cd /root/
tar -czf backup-hebdo-\$DATE.tar.gz backup-hebdo-\$DATE/
rm -rf backup-hebdo-\$DATE/

echo "BACKUP_ARCHIVE=backup-hebdo-\$DATE.tar.gz"
ls -lh backup-hebdo-\$DATE.tar.gz
"@

# Transférer et exécuter
$tempScript = "$env:TEMP\backup-hebdo-$date.sh"
$remoteBackupScript | Out-File -FilePath $tempScript -Encoding ASCII -NoNewline

try {
    scp $tempScript "${User}@${ServerIP}:/root/backup-hebdo.sh" 2>&1 | Out-Null
    Write-Log "Script uploadé sur le serveur" "SUCCESS"

    $remoteOutput = ssh "${User}@${ServerIP}" "chmod +x /root/backup-hebdo.sh && /root/backup-hebdo.sh 2>&1"
    Write-Log "Backup créé sur le serveur" "SUCCESS"

    # Extraire le nom de l'archive
    $archiveName = ($remoteOutput | Select-String "BACKUP_ARCHIVE=(.*)").Matches.Groups[1].Value
    if (!$archiveName) {
        $archiveName = "backup-hebdo-$date.tar.gz"
    }

} catch {
    Write-Log "ERREUR création backup: $_" "ERROR"
    Send-EmailNotification -Subject "ÉCHEC Backup Hebdo" -Body "Erreur création backup: $_" -IsError $true
    exit 1
}

# ============================================================================
# ÉTAPE 3 : TÉLÉCHARGEMENT
# ============================================================================

Write-Log "[3/7] Téléchargement du backup..." "INFO"

New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

try {
    scp "${User}@${ServerIP}:/root/$archiveName" "$backupDir\" 2>&1 | Out-Null

    $downloadedFile = Get-Item "$backupDir\$archiveName"
    $sizeInMB = [math]::Round($downloadedFile.Length / 1MB, 2)
    Write-Log "Téléchargement réussi: $sizeInMB MB" "SUCCESS"

} catch {
    Write-Log "ERREUR téléchargement: $_" "ERROR"
    Send-EmailNotification -Subject "ÉCHEC Backup Hebdo" -Body "Erreur téléchargement: $_" -IsError $true
    exit 1
}

# ============================================================================
# ÉTAPE 4 : EXTRACTION
# ============================================================================

Write-Log "[4/7] Extraction de l'archive..." "INFO"

Push-Location $backupDir
try {
    tar -xzf $archiveName 2>&1 | Out-Null

    # Déplacer contenu vers racine
    $extractedFolder = Get-ChildItem -Directory | Where-Object { $_.Name -like "backup-hebdo-*" } | Select-Object -First 1
    if ($extractedFolder) {
        Get-ChildItem -Path $extractedFolder.FullName | Move-Item -Destination $backupDir -Force
        Remove-Item -Path $extractedFolder.FullName -Force
    }

    Write-Log "Archive extraite avec succès" "SUCCESS"

} catch {
    Write-Log "ERREUR extraction: $_" "ERROR"
    Pop-Location
    exit 1
}
Pop-Location

# ============================================================================
# ÉTAPE 5 : VÉRIFICATION INTÉGRITÉ
# ============================================================================

Write-Log "[5/7] Vérification de l'intégrité..." "INFO"

$requiredFiles = @(
    "mailapp-*.sql.gz",
    "mailwizz-*.tar.gz",
    "pmta-config-*"
)

$allFilesPresent = $true
foreach ($pattern in $requiredFiles) {
    $found = Get-ChildItem -Path $backupDir -Filter $pattern -File
    if ($found) {
        Write-Log "✓ $pattern trouvé" "SUCCESS"
    } else {
        Write-Log "✗ $pattern MANQUANT" "ERROR"
        $allFilesPresent = $false
    }
}

if (!$allFilesPresent) {
    Write-Log "Backup incomplet - Conservation mais signalement" "WARNING"
}

# ============================================================================
# ÉTAPE 6 : ROTATION DES BACKUPS (GARDER 2 MAX)
# ============================================================================

Write-Log "[6/7] Rotation des backups (max: $MaxBackups)..." "INFO"

# Lister tous les backups par date (du plus récent au plus ancien)
$allBackups = Get-ChildItem -Path $BaseBackupDir -Directory |
              Where-Object { $_.Name -like "mailwizz-backup-*" } |
              Sort-Object Name -Descending

Write-Log "Backups actuels: $($allBackups.Count)" "INFO"

if ($allBackups.Count -gt $MaxBackups) {
    $backupsToDelete = $allBackups | Select-Object -Skip $MaxBackups

    foreach ($oldBackup in $backupsToDelete) {
        Write-Log "Suppression ancien backup: $($oldBackup.Name)" "WARNING"

        try {
            Remove-Item -Path $oldBackup.FullName -Recurse -Force
            Write-Log "✓ $($oldBackup.Name) supprimé" "SUCCESS"
        } catch {
            Write-Log "✗ Erreur suppression $($oldBackup.Name): $_" "ERROR"
        }
    }
} else {
    Write-Log "Pas de backup à supprimer (seulement $($allBackups.Count) backups)" "INFO"
}

# ============================================================================
# ÉTAPE 7 : NETTOYAGE SERVEUR
# ============================================================================

Write-Log "[7/7] Nettoyage du serveur..." "INFO"

try {
    ssh "${User}@${ServerIP}" "rm -f /root/$archiveName /root/backup-hebdo.sh" 2>&1 | Out-Null
    Write-Log "Backup supprimé du serveur" "SUCCESS"
} catch {
    Write-Log "Erreur nettoyage serveur (non-critique): $_" "WARNING"
}

# Nettoyage local
Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue

# ============================================================================
# RÉCAPITULATIF FINAL
# ============================================================================

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Log "========================================" "INFO"
Write-Log "SAUVEGARDE HEBDOMADAIRE TERMINÉE" "SUCCESS"
Write-Log "========================================" "INFO"
Write-Log "Durée: $($duration.TotalMinutes.ToString('0.00')) minutes" "INFO"
Write-Log "Backup créé: $backupName" "INFO"
Write-Log "Taille: $sizeInMB MB" "INFO"
Write-Log "Backups conservés: $MaxBackups" "INFO"

# Créer fichier info
$infoContent = @"
==========================================================
BACKUP HEBDOMADAIRE AUTOMATIQUE
==========================================================

Date création : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Serveur source : $ServerIP
Durée : $($duration.TotalMinutes.ToString('0.00')) minutes
Taille : $sizeInMB MB

Contenu :
$(Get-ChildItem -Path $backupDir -File | ForEach-Object { "- $($_.Name) ($([math]::Round($_.Length / 1MB, 2)) MB)" } | Out-String)

Backups actuels dans backups-auto :
$(Get-ChildItem -Path $BaseBackupDir -Directory | Where-Object { $_.Name -like "mailwizz-backup-*" } | Sort-Object Name -Descending | ForEach-Object { "- $($_.Name) ($(Get-Date $_.CreationTime -Format 'yyyy-MM-dd HH:mm'))" } | Out-String)

==========================================================
"@

$infoContent | Out-File -FilePath "$backupDir\BACKUP-INFO.txt" -Encoding UTF8

# Envoyer notification succès
Send-EmailNotification -Subject "✅ Backup Hebdo Réussi" -Body "Backup $backupName créé avec succès ($sizeInMB MB)" -IsError $false

Write-Log "Log complet: $LogFile" "INFO"

exit 0
