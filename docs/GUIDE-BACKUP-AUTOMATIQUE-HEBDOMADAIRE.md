# 🔄 Guide : Backup Automatique Hebdomadaire

**Objectif** : Sauvegarder automatiquement le serveur MailWizz de production (Hetzner) chaque semaine, avec rotation automatique (garde 2 backups max).

**Date** : 16 février 2026
**Serveur** : mail-server (46.62.168.55)

---

## 📋 CE QUE ÇA FAIT

- ✅ **Backup automatique** : Tous les **dimanches à 2h00**
- ✅ **Rotation intelligente** : Garde **seulement les 2 backups les plus récents**
- ✅ **Nettoyage automatique** : Supprime les anciens backups (> 2)
- ✅ **Logging complet** : Toutes les actions enregistrées dans `logs/backup-hebdo.log`
- ✅ **Vérification intégrité** : Contrôle que tous les fichiers sont présents
- ✅ **Nettoyage serveur** : Supprime le backup du serveur après téléchargement

---

## 🚀 INSTALLATION RAPIDE (5 MINUTES)

### Étape 1 : Tester le script manuellement

Avant de l'automatiser, testez-le une fois :

```powershell
cd "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing"

# Exécuter le script
.\scripts\automated-weekly-backup.ps1

# Vous devrez entrer le mot de passe SSH du serveur
```

**Résultat attendu** :
- Un nouveau dossier `backups-auto/mailwizz-backup-YYYYMMDD-HHMMSS/` créé
- Fichiers : `mailapp-*.sql.gz`, `mailwizz-*.tar.gz`, `pmta-config-*`
- Log créé dans `logs/backup-hebdo.log`

✅ **Si tout est OK, passez à l'étape 2**

---

### Étape 2 : Configurer l'authentification SSH sans mot de passe

**Pourquoi ?** Pour que le script s'exécute automatiquement sans interaction.

#### Option A : Clé SSH (Recommandé - Plus sécurisé)

```powershell
# 1. Générer une paire de clés SSH (si pas déjà fait)
ssh-keygen -t ed25519 -C "backup-automatique"
# Appuyez sur Entrée 3 fois (pas de passphrase pour automation)

# 2. Copier la clé publique sur le serveur
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh root@46.62.168.55 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# 3. Tester la connexion sans mot de passe
ssh root@46.62.168.55 "echo 'Connexion SSH sans mot de passe OK'"
```

✅ **Si ça affiche "Connexion SSH sans mot de passe OK", c'est bon !**

#### Option B : Credential Manager (Alternative)

Si vous préférez ne pas utiliser de clé SSH, vous pouvez utiliser un gestionnaire de mots de passe PowerShell :

```powershell
# Enregistrer le mot de passe dans Windows Credential Manager
# (à implémenter si nécessaire - moins sécurisé)
```

---

### Étape 3 : Créer la tâche planifiée Windows

#### Méthode 1 : Interface graphique (Facile)

1. **Ouvrir le Planificateur de tâches** :
   - Appuyez sur `Windows + R`
   - Tapez `taskschd.msc`
   - Appuyez sur Entrée

2. **Importer la tâche** :
   - Clic droit sur "Bibliothèque du Planificateur de tâches"
   - Sélectionnez "Importer une tâche..."
   - Naviguez vers : `C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\scripts\TaskScheduler-BackupHebdo.xml`
   - Cliquez sur "Ouvrir"

3. **Configurer le compte** :
   - Dans l'onglet "Général", cliquez sur "Modifier l'utilisateur ou le groupe..."
   - Sélectionnez votre compte utilisateur
   - Cochez "Exécuter avec les autorisations maximales"

4. **Vérifier le déclencheur** :
   - Onglet "Déclencheurs" : Vérifiez "Tous les dimanches à 02:00"
   - Si vous voulez changer l'horaire, modifiez-le ici

5. **Enregistrer** :
   - Cliquez sur "OK"
   - Entrez votre mot de passe Windows si demandé

#### Méthode 2 : Ligne de commande (Avancé)

```powershell
# Importer la tâche
schtasks /create /tn "MailWizz\BackupHebdomadaire" /xml "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\scripts\TaskScheduler-BackupHebdo.xml"

# Vérifier que la tâche est créée
schtasks /query /tn "MailWizz\BackupHebdomadaire" /fo LIST
```

---

### Étape 4 : Tester la tâche planifiée

```powershell
# Exécuter manuellement la tâche (ne pas attendre dimanche 2h !)
schtasks /run /tn "MailWizz\BackupHebdomadaire"

# Suivre le log en temps réel
Get-Content "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\logs\backup-hebdo.log" -Wait
```

**Résultat attendu** :
- Backup créé dans `backups-auto/`
- Log mis à jour avec toutes les étapes
- Pas d'erreurs

✅ **Si tout fonctionne, votre backup automatique est opérationnel !**

---

## 📁 STRUCTURE DES FICHIERS

Après installation, vous aurez :

```
Outils d'emailing/
├── backups-auto/                           # Backups automatiques (rotation 2 max)
│   ├── mailwizz-backup-20260216-020000/   # Backup le plus récent
│   │   ├── mailapp-20260216-020000.sql.gz
│   │   ├── mailwizz-20260216-020000.tar.gz
│   │   ├── pmta-config-20260216-020000
│   │   ├── pmta-dkim/
│   │   └── BACKUP-INFO.txt
│   └── mailwizz-backup-20260209-020000/   # Backup précédent
│
├── mailwizz_transactionnel/                # Backup manuel actuel
│
├── logs/
│   └── backup-hebdo.log                    # Log complet de tous les backups
│
└── scripts/
    ├── automated-weekly-backup.ps1         # Script de backup automatique
    ├── sync-production-hetzner.ps1         # Script de sync manuel
    └── TaskScheduler-BackupHebdo.xml       # Tâche Windows
```

---

## ⚙️ CONFIGURATION AVANCÉE

### Changer la fréquence

Par défaut : **Tous les dimanches à 2h00**

Pour changer :

1. Ouvrir le Planificateur de tâches
2. Clic droit sur "MailWizz\BackupHebdomadaire" → Propriétés
3. Onglet "Déclencheurs" → Modifier
4. Changer le jour ou l'heure

**Exemples** :
- **Tous les jours à 3h** : Quotidien, 03:00
- **Tous les lundis et jeudis à minuit** : Hebdomadaire, Lundi + Jeudi, 00:00

### Changer le nombre de backups conservés

Par défaut : **2 backups**

Pour garder plus (ex: 4 backups) :

```powershell
# Modifier le script
notepad "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\scripts\automated-weekly-backup.ps1"

# Ligne 17, changer :
[int]$MaxBackups = 4
```

### Activer les notifications email

Le script a une fonction `Send-EmailNotification` préparée mais non implémentée.

Pour l'activer, modifiez la fonction (ligne 43-50) :

```powershell
function Send-EmailNotification {
    param(
        [string]$Subject,
        [string]$Body,
        [bool]$IsError = $false
    )

    $emailParams = @{
        From       = "backup@votre-domaine.com"
        To         = "admin@votre-domaine.com"
        Subject    = $Subject
        Body       = $Body
        SmtpServer = "smtp.votre-domaine.com"
        Port       = 587
        Credential = (Get-Credential)
        UseSsl     = $true
    }

    Send-MailMessage @emailParams
}
```

---

## 📊 SURVEILLANCE ET LOGS

### Consulter le log

```powershell
# Log complet
Get-Content "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\logs\backup-hebdo.log"

# Dernières 50 lignes
Get-Content "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\logs\backup-hebdo.log" -Tail 50

# Suivre en temps réel
Get-Content "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\logs\backup-hebdo.log" -Wait
```

### Vérifier les backups

```powershell
cd "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\backups-auto"

# Lister tous les backups avec taille
Get-ChildItem -Directory | Select-Object Name, CreationTime, @{Name="Size (MB)"; Expression={(Get-ChildItem $_.FullName -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB | ForEach-Object { "{0:N2}" -f $_ }}}
```

### Vérifier l'historique de la tâche

```powershell
# Dernière exécution
Get-ScheduledTask -TaskName "BackupHebdomadaire" | Get-ScheduledTaskInfo

# Historique complet (Event Viewer)
Get-WinEvent -LogName "Microsoft-Windows-TaskScheduler/Operational" -FilterXPath "*[EventData[Data[@Name='TaskName']='\MailWizz\BackupHebdomadaire']]" | Select-Object -First 10
```

---

## 🔧 DÉPANNAGE

### Problème : Script ne s'exécute pas automatiquement

**Vérifications** :

1. **Tâche activée ?**
   ```powershell
   Get-ScheduledTask -TaskName "BackupHebdomadaire"
   # State doit être "Ready"
   ```

2. **Compte correct ?**
   - Planificateur de tâches → Propriétés → Général
   - Doit être votre compte utilisateur
   - Cocher "Exécuter avec les autorisations maximales"

3. **Politique d'exécution PowerShell ?**
   ```powershell
   Get-ExecutionPolicy -List
   # CurrentUser doit être RemoteSigned ou Unrestricted
   ```

### Problème : Demande mot de passe SSH

**Cause** : Clé SSH non configurée

**Solution** : Refaire l'Étape 2 (Authentification SSH)

### Problème : Backup corrompu ou incomplet

**Diagnostic** :

```powershell
cd "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\backups-auto"

# Trouver le dernier backup
$lastBackup = Get-ChildItem -Directory | Sort-Object Name -Descending | Select-Object -First 1

# Vérifier les fichiers
Get-ChildItem $lastBackup.FullName -Recurse | Select-Object Name, Length
```

**Fichiers requis** :
- ✅ `mailapp-*.sql.gz` (0.5-2 MB)
- ✅ `mailwizz-*.tar.gz` (100-150 MB)
- ✅ `pmta-config-*` (50-100 KB)

### Problème : Espace disque

**Calcul de l'espace nécessaire** :

Avec 2 backups conservés :
- 1 backup ≈ 150 MB
- 2 backups ≈ 300 MB
- **+ 20% marge = 360 MB requis**

**Vérifier l'espace disponible** :

```powershell
Get-PSDrive C | Select-Object Used, Free, @{Name="Free (GB)"; Expression={[math]::Round($_.Free / 1GB, 2)}}
```

---

## 🔄 RESTAURATION D'UN BACKUP

Si besoin de restaurer un backup automatique :

### 1. Identifier le backup à restaurer

```powershell
cd "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\backups-auto"

# Lister les backups disponibles
Get-ChildItem -Directory | Select-Object Name, CreationTime
```

### 2. Extraire les fichiers

```powershell
# Exemple : backup du 16 février 2026
$backupDir = "mailwizz-backup-20260216-020000"

# Extraire la base de données
cd $backupDir
gunzip -k mailapp-20260216-020000.sql.gz
# Vous obtenez : mailapp-20260216-020000.sql

# Extraire MailWizz
tar -xzf mailwizz-20260216-020000.tar.gz
# Vous obtenez : dossier mailwizz/
```

### 3. Utiliser les fichiers restaurés

Voir le guide principal pour upload vers serveur :
- `GUIDE-RECUPERATION-PRODUCTION-HETZNER.md`

---

## 📈 STATISTIQUES

Pour analyser vos backups :

```powershell
# Taille totale de tous les backups
Get-ChildItem "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\backups-auto" -Recurse -File |
    Measure-Object -Property Length -Sum |
    Select-Object @{Name="Total (MB)"; Expression={[math]::Round($_.Sum / 1MB, 2)}}

# Évolution de la taille
Get-ChildItem "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\backups-auto" -Directory |
    ForEach-Object {
        $size = (Get-ChildItem $_.FullName -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
        [PSCustomObject]@{
            Date     = $_.CreationTime.ToString("yyyy-MM-dd HH:mm")
            Name     = $_.Name
            SizeMB   = [math]::Round($size, 2)
        }
    } | Sort-Object Date
```

---

## ✅ CHECKLIST FINALE

Avant de considérer l'installation terminée :

- [ ] Script testé manuellement avec succès
- [ ] Clé SSH configurée (connexion sans mot de passe)
- [ ] Tâche planifiée créée et activée
- [ ] Tâche testée manuellement avec succès
- [ ] Log créé et lisible dans `logs/backup-hebdo.log`
- [ ] Premier backup présent dans `backups-auto/`
- [ ] Fichiers vérifiés (SQL, MailWizz, PowerMTA)

---

## 📚 DOCUMENTATION CONNEXE

- **Récupération manuelle rapide** : `RECUPERATION-RAPIDE.md`
- **Guide complet de récupération** : `GUIDE-RECUPERATION-PRODUCTION-HETZNER.md`
- **Analyse des systèmes** : `ANALYSE-COMPARATIVE-SYSTEMES-EMAILING.md`

---

## 📞 SUPPORT

### Commandes utiles

```powershell
# Désactiver temporairement
Disable-ScheduledTask -TaskName "MailWizz\BackupHebdomadaire"

# Réactiver
Enable-ScheduledTask -TaskName "MailWizz\BackupHebdomadaire"

# Supprimer la tâche
Unregister-ScheduledTask -TaskName "MailWizz\BackupHebdomadaire"

# Modifier le script
notepad "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\scripts\automated-weekly-backup.ps1"
```

---

**Dernière mise à jour** : 16 février 2026
**Version du script** : 1.0.0
**Testé sur** : Windows 10/11, PowerShell 5.1+

**Document créé par Claude Code**
