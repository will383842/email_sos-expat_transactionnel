# ============================================================================
# BACKUP AUTOMATIQUE AVEC NOTIFICATIONS TELEGRAM
# ============================================================================
param(
    [string]$ServerIP = "46.62.168.55",
    [string]$User = "root",
    [string]$BaseBackupDir = "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\backups-auto",
    [int]$MaxBackups = 2,
    [string]$LogFile = "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\logs\backup-hebdo.log",
    [string]$TelegramBotToken = "8349162167:AAGlhfoIZx7cUk40ebLypjEbpK6SG_f-rAM",
    [string]$TelegramChatId = ""  # Sera récupéré automatiquement
)

# ============================================================================
# FONCTIONS TELEGRAM
# ============================================================================

function Get-TelegramChatId {
    param([string]$BotToken)

    try {
        $response = Invoke-RestMethod -Uri "https://api.telegram.org/bot$BotToken/getUpdates" -Method Get
        if ($response.ok -and $response.result.Count -gt 0) {
            $chatId = $response.result[-1].message.chat.id
            return $chatId
        }
    } catch {
        return $null
    }
    return $null
}

function Send-TelegramMessage {
    param(
        [string]$BotToken,
        [string]$ChatId,
        [string]$Message
    )

    if ([string]::IsNullOrEmpty($ChatId)) {
        Write-Log "Chat ID Telegram non configuré - Notification ignorée" "WARNING"
        return
    }

    try {
        $body = @{
            chat_id = $ChatId
            text = $Message
            parse_mode = "HTML"
        }

        $response = Invoke-RestMethod -Uri "https://api.telegram.org/bot$BotToken/sendMessage" -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"

        if ($response.ok) {
            Write-Log "Notification Telegram envoyée" "SUCCESS"
        }
    } catch {
        Write-Log "Erreur envoi Telegram: $_" "ERROR"
    }
}

# ============================================================================
# FONCTION DE LOG
# ============================================================================

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

# ============================================================================
# DÉBUT DU SCRIPT
# ============================================================================

Write-Log "========================================" "INFO"
Write-Log "BACKUP AUTOMATIQUE HEBDOMADAIRE" "INFO"
Write-Log "========================================" "INFO"

$startTime = Get-Date
$date = Get-Date -Format "yyyyMMdd-HHmmss"
$backupName = "mailwizz-backup-$date"
$backupDir = Join-Path $BaseBackupDir $backupName
$remoteDate = ssh "${User}@${ServerIP}" "date +%Y%m%d-%H%M%S"
$remoteName = "backup-prod-$remoteDate"
$success = $true
$errorMessage = ""

# Récupérer Chat ID si non fourni
if ([string]::IsNullOrEmpty($TelegramChatId)) {
    Write-Log "Tentative de récupération automatique du Chat ID Telegram..." "INFO"
    $TelegramChatId = Get-TelegramChatId -BotToken $TelegramBotToken
    if ($TelegramChatId) {
        Write-Log "Chat ID Telegram trouvé: $TelegramChatId" "SUCCESS"
    } else {
        Write-Log "Chat ID Telegram non trouvé - Envoyez un message au bot Telegram pour activer les notifications" "WARNING"
    }
}

# Message de début
if ($TelegramChatId) {
    $startMessage = "🔄 <b>Backup MailWizz Démarré</b>`n`nServeur: $ServerIP`nDate: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Send-TelegramMessage -BotToken $TelegramBotToken -ChatId $TelegramChatId -Message $startMessage
}

# Créer répertoires
if (!(Test-Path $BaseBackupDir)) {
    New-Item -ItemType Directory -Path $BaseBackupDir -Force | Out-Null
}
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

try {
    # Backup MySQL
    Write-Log "[1/6] Création backup MySQL sur serveur..." "INFO"
    ssh "${User}@${ServerIP}" "mysqldump -u root mailapp 2>/dev/null | gzip > /root/${remoteName}-mailapp.sql.gz && ls -lh /root/${remoteName}-mailapp.sql.gz"

    # Backup MailWizz
    Write-Log "[2/6] Backup MailWizz sur serveur..." "INFO"
    ssh "${User}@${ServerIP}" "cd /var/www && tar -czf /root/${remoteName}-mailwizz.tar.gz --exclude='mailwizz/apps/*/runtime/*' --exclude='mailwizz/apps/*/cache/*' mailwizz/ 2>/dev/null && ls -lh /root/${remoteName}-mailwizz.tar.gz"

    # Backup PowerMTA
    Write-Log "[3/6] Backup PowerMTA sur serveur..." "INFO"
    ssh "${User}@${ServerIP}" "cp /etc/pmta/config /root/${remoteName}-pmta-config 2>/dev/null; cp /etc/pmta/license /root/${remoteName}-pmta-license 2>/dev/null; echo 'PowerMTA copié'"

    # Téléchargements
    Write-Log "[4/6] Téléchargement des fichiers..." "INFO"

    Write-Log "  -> Base de données..." "INFO"
    scp "${User}@${ServerIP}:/root/${remoteName}-mailapp.sql.gz" "$backupDir\${remoteName}-mailapp.sql.gz" 2>&1 | Out-Null
    $sqlFile = Get-Item "$backupDir\${remoteName}-mailapp.sql.gz" -ErrorAction SilentlyContinue
    if ($sqlFile) {
        Write-Log "  OK: $([math]::Round($sqlFile.Length / 1MB, 2)) MB" "SUCCESS"
    } else {
        throw "Échec téléchargement MySQL"
    }

    Write-Log "  -> Application MailWizz..." "INFO"
    scp "${User}@${ServerIP}:/root/${remoteName}-mailwizz.tar.gz" "$backupDir\${remoteName}-mailwizz.tar.gz" 2>&1 | Out-Null
    $mwFile = Get-Item "$backupDir\${remoteName}-mailwizz.tar.gz" -ErrorAction SilentlyContinue
    if ($mwFile) {
        Write-Log "  OK: $([math]::Round($mwFile.Length / 1MB, 2)) MB" "SUCCESS"
    } else {
        throw "Échec téléchargement MailWizz"
    }

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

    # Rotation
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

    # Nettoyage serveur
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

    # Notification Telegram de succès
    if ($TelegramChatId) {
        $successMessage = @"
✅ <b>Backup MailWizz Réussi</b>

📊 <b>Résumé:</b>
• MySQL: $([math]::Round($sqlFile.Length / 1MB, 2)) MB
• MailWizz: $([math]::Round($mwFile.Length / 1MB, 2)) MB
• Total: $([math]::Round($totalSize, 2)) MB

⏱️ <b>Durée:</b> $([math]::Round($duration.TotalSeconds, 0)) secondes

💾 <b>Backups conservés:</b> $($allBackups.Count)

🕐 <b>Date:</b> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
        Send-TelegramMessage -BotToken $TelegramBotToken -ChatId $TelegramChatId -Message $successMessage
    }

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

} catch {
    $success = $false
    $errorMessage = $_.Exception.Message

    Write-Log "========================================" "ERROR"
    Write-Log "BACKUP ÉCHOUÉ" "ERROR"
    Write-Log "Erreur: $errorMessage" "ERROR"
    Write-Log "========================================" "ERROR"

    # Notification Telegram d'échec
    if ($TelegramChatId) {
        $failMessage = @"
🚨 <b>Backup MailWizz Échoué</b>

❌ <b>Erreur:</b>
$errorMessage

🕐 <b>Date:</b> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

💡 <b>Action:</b> Vérifiez les logs
"@
        Send-TelegramMessage -BotToken $TelegramBotToken -ChatId $TelegramChatId -Message $failMessage
    }

    exit 1
}
