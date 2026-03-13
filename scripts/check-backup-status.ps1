# ============================================================================
# SCRIPT DE VÉRIFICATION - STATUT DES BACKUPS
# ============================================================================
# Description: Affiche un dashboard rapide de l'état des backups
# Author: Claude Code
# Date: 2026-02-16
# Usage: .\check-backup-status.ps1
# ============================================================================

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

# Chemins
$baseDir = "C:\Users\willi\Documents\Projets\VS_CODE\email_sos-expat_transactionnel"
$backupsAutoDir = Join-Path $baseDir "backups-auto"
$mailwizzTransDir = Join-Path $baseDir "mailwizz_transactionnel"
$logFile = Join-Path $baseDir "logs\backup-hebdo.log"

# Header
Clear-Host
Write-Host ""
Write-Host "=============================================="
Write-Host "  STATUT DES BACKUPS MAILWIZZ"
Write-Host "=============================================="
Write-Host ""
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

# ============================================================================
# 1. CONNEXION SERVEUR
# ============================================================================

Write-Info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Info "  1. CONNEXION SERVEUR"
Write-Info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

$serverIP = "46.62.168.55"
$testConnection = Test-NetConnection -ComputerName $serverIP -Port 22 -WarningAction SilentlyContinue -InformationLevel Quiet

if ($testConnection) {
    Write-Success "✅ Serveur accessible ($serverIP:22)"
} else {
    Write-Error "❌ Serveur INACCESSIBLE ($serverIP:22)"
}

# Test SSH
try {
    $sshVersion = ssh -V 2>&1
    Write-Success "✅ SSH disponible: $sshVersion"
} catch {
    Write-Error "❌ SSH non disponible"
}

# Test clé SSH
$hasSSHKey = Test-Path "$env:USERPROFILE\.ssh\id_ed25519.pub"
if ($hasSSHKey) {
    Write-Success "✅ Clé SSH trouvée (~\.ssh\id_ed25519.pub)"
} else {
    Write-Warning "⚠️  Clé SSH non trouvée (backup auto nécessite une clé)"
}

Write-Host ""

# ============================================================================
# 2. BACKUP MANUEL ACTUEL
# ============================================================================

Write-Info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Info "  2. BACKUP MANUEL ACTUEL"
Write-Info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if (Test-Path $mailwizzTransDir) {
    $mailwizzTransInfo = Get-Item $mailwizzTransDir
    $mailwizzTransSize = (Get-ChildItem $mailwizzTransDir -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB

    Write-Success "✅ mailwizz_transactionnel trouvé"
    Write-Host "   Créé le: $($mailwizzTransInfo.CreationTime.ToString('yyyy-MM-dd HH:mm'))"
    Write-Host "   Taille: $([math]::Round($mailwizzTransSize, 2)) MB"

    # Vérifier les fichiers requis
    $sqlGz = Get-ChildItem $mailwizzTransDir -Filter "*.sql.gz" -File
    $mailwizzTarGz = Get-ChildItem $mailwizzTransDir -Filter "mailwizz-*.tar.gz" -File
    $pmtaConfig = Get-ChildItem $mailwizzTransDir -Filter "pmta-config-*" -File

    if ($sqlGz) {
        Write-Success "   ✅ Base de données: $($sqlGz.Name) ($([math]::Round($sqlGz.Length / 1MB, 2)) MB)"
    } else {
        Write-Error "   ❌ Base de données manquante"
    }

    if ($mailwizzTarGz) {
        Write-Success "   ✅ Application MailWizz: $($mailwizzTarGz.Name) ($([math]::Round($mailwizzTarGz.Length / 1MB, 2)) MB)"
    } else {
        Write-Error "   ❌ Application MailWizz manquante"
    }

    if ($pmtaConfig) {
        Write-Success "   ✅ Config PowerMTA: $($pmtaConfig.Name)"
    } else {
        Write-Warning "   ⚠️  Config PowerMTA manquante"
    }

} else {
    Write-Warning "⚠️  mailwizz_transactionnel non trouvé"
}

Write-Host ""

# ============================================================================
# 3. BACKUPS AUTOMATIQUES
# ============================================================================

Write-Info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Info "  3. BACKUPS AUTOMATIQUES"
Write-Info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if (Test-Path $backupsAutoDir) {
    $autoBackups = Get-ChildItem $backupsAutoDir -Directory | Where-Object { $_.Name -like "mailwizz-backup-*" } | Sort-Object Name -Descending

    if ($autoBackups) {
        Write-Success "✅ $($autoBackups.Count) backup(s) automatique(s) trouvé(s)"
        Write-Host ""

        foreach ($backup in $autoBackups) {
            $backupSize = (Get-ChildItem $backup.FullName -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB
            $age = (Get-Date) - $backup.CreationTime

            $ageText = if ($age.TotalDays -lt 1) {
                "$([math]::Round($age.TotalHours, 1)) heures"
            } else {
                "$([math]::Round($age.TotalDays, 1)) jours"
            }

            Write-Info "   📦 $($backup.Name)"
            Write-Host "      Créé: $($backup.CreationTime.ToString('yyyy-MM-dd HH:mm')) (il y a $ageText)"
            Write-Host "      Taille: $([math]::Round($backupSize, 2)) MB"

            # Vérifier intégrité
            $hasSQL = Get-ChildItem $backup.FullName -Filter "*.sql.gz" -File
            $hasMailwizz = Get-ChildItem $backup.FullName -Filter "mailwizz-*.tar.gz" -File
            $hasPMTA = Get-ChildItem $backup.FullName -Filter "pmta-config-*" -File

            $integrity = @()
            if ($hasSQL) { $integrity += "SQL✓" } else { $integrity += "SQL✗" }
            if ($hasMailwizz) { $integrity += "MW✓" } else { $integrity += "MW✗" }
            if ($hasPMTA) { $integrity += "PMTA✓" } else { $integrity += "PMTA✗" }

            Write-Host "      Intégrité: $($integrity -join ', ')"
            Write-Host ""
        }

        # Taille totale
        $totalSize = ($autoBackups | ForEach-Object { (Get-ChildItem $_.FullName -Recurse -File | Measure-Object -Property Length -Sum).Sum }) | Measure-Object -Sum
        Write-Host "   Taille totale: $([math]::Round($totalSize.Sum / 1MB, 2)) MB"

    } else {
        Write-Warning "⚠️  Aucun backup automatique trouvé"
        Write-Host "   Lancez: schtasks /run /tn `"MailWizz\BackupHebdomadaire`""
    }

} else {
    Write-Warning "⚠️  Répertoire backups-auto non trouvé"
}

Write-Host ""

# ============================================================================
# 4. TÂCHE PLANIFIÉE
# ============================================================================

Write-Info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Info "  4. TÂCHE PLANIFIÉE"
Write-Info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

try {
    $task = Get-ScheduledTask -TaskName "BackupHebdomadaire" -ErrorAction SilentlyContinue

    if ($task) {
        $taskInfo = Get-ScheduledTaskInfo -TaskName "BackupHebdomadaire"

        Write-Success "✅ Tâche planifiée trouvée"
        Write-Host "   État: $($task.State)"

        if ($task.State -eq "Ready") {
            Write-Success "   ✓ Tâche activée"
        } else {
            Write-Warning "   ⚠️  Tâche désactivée ou en erreur"
        }

        Write-Host "   Dernière exécution: $($taskInfo.LastRunTime)"
        Write-Host "   Résultat: $($taskInfo.LastTaskResult) $(if ($taskInfo.LastTaskResult -eq 0) { '(Succès)' } else { '(Erreur)' })"
        Write-Host "   Prochaine exécution: $($taskInfo.NextRunTime)"

        # Trigger info
        $triggers = $task.Triggers
        if ($triggers) {
            Write-Host "   Fréquence: Tous les dimanches à 02:00"
        }

    } else {
        Write-Warning "⚠️  Tâche planifiée non trouvée"
        Write-Host "   Pour créer: Importer scripts\TaskScheduler-BackupHebdo.xml"
    }

} catch {
    Write-Error "❌ Erreur lors de la vérification de la tâche: $_"
}

Write-Host ""

# ============================================================================
# 5. LOGS
# ============================================================================

Write-Info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Info "  5. LOGS"
Write-Info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if (Test-Path $logFile) {
    $logInfo = Get-Item $logFile
    $logLines = (Get-Content $logFile | Measure-Object -Line).Lines

    Write-Success "✅ Fichier log trouvé"
    Write-Host "   Fichier: logs\backup-hebdo.log"
    Write-Host "   Taille: $([math]::Round($logInfo.Length / 1KB, 2)) KB"
    Write-Host "   Lignes: $logLines"
    Write-Host "   Dernière modification: $($logInfo.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))"

    # Dernières lignes significatives
    Write-Host ""
    Write-Info "   Dernières 10 lignes:"
    Get-Content $logFile -Tail 10 | ForEach-Object { Write-Host "   $_" }

} else {
    Write-Warning "⚠️  Fichier log non trouvé (aucun backup auto exécuté)"
}

Write-Host ""

# ============================================================================
# 6. ESPACE DISQUE
# ============================================================================

Write-Info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Info "  6. ESPACE DISQUE"
Write-Info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

$drive = Get-PSDrive C
$freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)
$usedSpaceGB = [math]::Round($drive.Used / 1GB, 2)
$totalSpaceGB = [math]::Round(($drive.Used + $drive.Free) / 1GB, 2)
$percentFree = [math]::Round(($drive.Free / ($drive.Used + $drive.Free)) * 100, 1)

Write-Host "   Disque C:"
Write-Host "   Total: $totalSpaceGB GB"
Write-Host "   Utilisé: $usedSpaceGB GB"
Write-Host "   Libre: $freeSpaceGB GB ($percentFree%)"

if ($percentFree -lt 10) {
    Write-Error "   ❌ ATTENTION: Espace disque faible (<10%)"
} elseif ($percentFree -lt 20) {
    Write-Warning "   ⚠️  Espace disque limité (<20%)"
} else {
    Write-Success "   ✅ Espace disque suffisant"
}

Write-Host ""

# ============================================================================
# 7. RECOMMANDATIONS
# ============================================================================

Write-Info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Info "  7. RECOMMANDATIONS"
Write-Info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

$recommendations = @()

# Vérifier si clé SSH configurée
if (!$hasSSHKey) {
    $recommendations += "⚠️  Configurer clé SSH pour backup auto: ssh-keygen -t ed25519"
}

# Vérifier si tâche planifiée existe
if (!$task) {
    $recommendations += "⚠️  Créer la tâche planifiée (voir GUIDE-BACKUP-AUTOMATIQUE-HEBDOMADAIRE.md)"
}

# Vérifier si backups automatiques existent
if (!(Test-Path $backupsAutoDir) -or !$autoBackups) {
    $recommendations += "⚠️  Aucun backup automatique - Tester: schtasks /run /tn `"MailWizz\BackupHebdomadaire`""
}

# Vérifier dernière exécution
if ($task -and $taskInfo) {
    $daysSinceLastRun = ((Get-Date) - $taskInfo.LastRunTime).TotalDays
    if ($daysSinceLastRun -gt 8) {
        $recommendations += "⚠️  Dernier backup il y a $([math]::Round($daysSinceLastRun, 1)) jours (>7j)"
    }
}

# Vérifier espace disque
if ($percentFree -lt 20) {
    $recommendations += "⚠️  Libérer de l'espace disque (< 20% libre)"
}

if ($recommendations) {
    foreach ($rec in $recommendations) {
        Write-Warning $rec
    }
} else {
    Write-Success "✅ Tout est OK - Aucune action nécessaire"
}

Write-Host ""

# ============================================================================
# FOOTER
# ============================================================================

Write-Info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Info "  COMMANDES UTILES"
Write-Info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

Write-Host ""
Write-Host "Backup manuel immédiat:"
Write-Host "  .\scripts\sync-production-hetzner.ps1 -ServerIP `"46.62.168.55`" -User `"root`""
Write-Host ""
Write-Host "Forcer backup automatique:"
Write-Host "  schtasks /run /tn `"MailWizz\BackupHebdomadaire`""
Write-Host ""
Write-Host "Suivre le log en temps réel:"
Write-Host "  Get-Content logs\backup-hebdo.log -Wait"
Write-Host ""
Write-Host "Voir les backups:"
Write-Host "  Get-ChildItem backups-auto\ -Directory | Select-Object Name, CreationTime"
Write-Host ""

Write-Host "=============================================="
Write-Host ""

# Offrir de voir le log complet
if (Test-Path $logFile) {
    $viewLog = Read-Host "Afficher le log complet ? (Y/n)"
    if ($viewLog -ne "n" -and $viewLog -ne "N") {
        Get-Content $logFile
    }
}
