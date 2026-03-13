# ============================================================================
# BACKUP AUTOMATIQUE - Exécution directe SSH
# ============================================================================
param(
    [string]$ServerIP = "46.62.168.55",
    [string]$User = "root",
    [string]$BaseBackupDir = "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\backups-auto",
    [int]$MaxBackups = 2,
    [string]$LogFile = "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\logs\backup-hebdo.log"
)

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

Write-Log "========================================" "INFO"
Write-Log "BACKUP AUTOMATIQUE HEBDOMADAIRE" "INFO"
Write-Log "========================================" "INFO"

$startTime = Get-Date
$date = Get-Date -Format "yyyyMMdd-HHmmss"
$backupName = "mailwizz-backup-$date"
$backupDir = Join-Path $BaseBackupDir $backupName
$remoteDate = ssh "${User}@${ServerIP}" "date +%Y%m%d-%H%M%S"
$remoteName = "backup-prod-$remoteDate"

# Créer répertoires
if (!(Test-Path $BaseBackupDir)) {
    New-Item -ItemType Directory -Path $BaseBackupDir -Force | Out-Null
}
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

Write-Log "[1/6] Création backup MySQL sur serveur..." "INFO"
ssh "${User}@${ServerIP}" "mysqldump -u root mailapp 2>/dev/null | gzip > /root/${remoteName}-mailapp.sql.gz && ls -lh /root/${remoteName}-mailapp.sql.gz"

Write-Log "[2/6] Backup MailWizz sur serveur..." "INFO"
ssh "${User}@${ServerIP}" "cd /var/www && tar -czf /root/${remoteName}-mailwizz.tar.gz --exclude='mailwizz/apps/*/runtime/*' --exclude='mailwizz/apps/*/cache/*' mailwizz/ 2>/dev/null && ls -lh /root/${remoteName}-mailwizz.tar.gz"

Write-Log "[3/6] Backup PowerMTA sur serveur..." "INFO"
ssh "${User}@${ServerIP}" "cp /etc/pmta/config /root/${remoteName}-pmta-config 2>/dev/null; cp /etc/pmta/license /root/${remoteName}-pmta-license 2>/dev/null; echo 'PowerMTA copié'"

Write-Log "[4/6] Téléchargement des fichiers..." "INFO"

# Télécharger MySQL
Write-Log "  -> Base de données..." "INFO"
$scpOutput = scp "${User}@${ServerIP}:/root/${remoteName}-mailapp.sql.gz" "$backupDir\${remoteName}-mailapp.sql.gz" 2>&1
$sqlFile = Get-Item "$backupDir\${remoteName}-mailapp.sql.gz" -ErrorAction SilentlyContinue
if ($sqlFile) {
    Write-Log "  OK: $([math]::Round($sqlFile.Length / 1MB, 2)) MB" "SUCCESS"
} else {
    Write-Log "  ERREUR téléchargement MySQL: $scpOutput" "ERROR"
}

# Télécharger MailWizz
Write-Log "  -> Application MailWizz..." "INFO"
$scpOutput = scp "${User}@${ServerIP}:/root/${remoteName}-mailwizz.tar.gz" "$backupDir\${remoteName}-mailwizz.tar.gz" 2>&1
$mwFile = Get-Item "$backupDir\${remoteName}-mailwizz.tar.gz" -ErrorAction SilentlyContinue
if ($mwFile) {
    Write-Log "  OK: $([math]::Round($mwFile.Length / 1MB, 2)) MB" "SUCCESS"
} else {
    Write-Log "  ERREUR téléchargement MailWizz: $scpOutput" "ERROR"
}

# Télécharger PowerMTA
Write-Log "  -> Config PowerMTA..." "INFO"
scp "${User}@${ServerIP}:/root/${remoteName}-pmta-config" "$backupDir\${remoteName}-pmta-config" 2>&1 | Out-Null
scp "${User}@${ServerIP}:/root/${remoteName}-pmta-license" "$backupDir\${remoteName}-pmta-license" 2>&1 | Out-Null -ErrorAction SilentlyContinue

$pmtaFile = Get-Item "$backupDir\${remoteName}-pmta-config" -ErrorAction SilentlyContinue
if ($pmtaFile) {
    Write-Log "  OK: Config PowerMTA" "SUCCESS"
}

# Calculer taille totale
$totalSize = (Get-ChildItem $backupDir -File | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Log "  Taille totale: $([math]::Round($totalSize, 2)) MB" "SUCCESS"

Write-Log "[5/6] Rotation des backups (max: $MaxBackups)..." "INFO"
$allBackups = Get-ChildItem -Path $BaseBackupDir -Directory |
              Where-Object { $_.Name -like "mailwizz-backup-*" } |
              Sort-Object Name -Descending

Write-Log "  Backups actuels: $($allBackups.Count)" "INFO"

if ($allBackups.Count -gt $MaxBackups) {
    $backupsToDelete = $allBackups | Select-Object -Skip $MaxBackups
    foreach ($oldBackup in $backupsToDelete) {
        Write-Log "  Suppression: $($oldBackup.Name)" "WARNING"
        Remove-Item -Path $oldBackup.FullName -Recurse -Force
    }
}

Write-Log "[6/6] Nettoyage serveur..." "INFO"
ssh "${User}@${ServerIP}" "rm -f /root/${remoteName}-* 2>/dev/null; echo 'Nettoyé'"

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Log "========================================" "INFO"
Write-Log "BACKUP TERMINÉ AVEC SUCCÈS" "SUCCESS"
Write-Log "========================================" "INFO"
Write-Log "Durée: $($duration.TotalMinutes.ToString('0.00')) minutes" "INFO"
Write-Log "Backup: $backupName" "INFO"
Write-Log "Taille: $([math]::Round($totalSize, 2)) MB" "INFO"
Write-Log "Backups conservés: $($allBackups.Count)" "INFO"

# Créer fichier info
$infoContent = @"
BACKUP AUTOMATIQUE HEBDOMADAIRE
================================
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Serveur: $ServerIP
Durée: $($duration.TotalMinutes.ToString('0.00')) minutes
Taille: $([math]::Round($totalSize, 2)) MB

Fichiers:
$(Get-ChildItem -Path $backupDir -File | ForEach-Object { "- $($_.Name) ($([math]::Round($_.Length / 1MB, 2)) MB)" } | Out-String)

Backups dans backups-auto:
$(Get-ChildItem -Path $BaseBackupDir -Directory | Where-Object { $_.Name -like "mailwizz-backup-*" } | Sort-Object Name -Descending | ForEach-Object { "- $($_.Name)" } | Out-String)
"@

$infoContent | Out-File -FilePath "$backupDir\BACKUP-INFO.txt" -Encoding UTF8

exit 0
