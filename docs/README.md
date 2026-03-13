# 📧 Outils d'Emailing - Documentation

**Serveur de production** : mail-server (Hetzner CPX22)
**IP principale** : 46.62.168.55
**Stack** : MailWizz 2.2.11 + PowerMTA 5.0r9 + MySQL

---

## 📁 STRUCTURE DU PROJET

```
Outils d'emailing/
├── 📁 backups-auto/              # Backups automatiques hebdomadaires (max 2)
├── 📁 mailwizz_transactionnel/   # Backup manuel actuel de production
├── 📁 scripts/                   # Scripts d'automatisation
├── 📁 logs/                      # Logs des backups automatiques
└── 📄 Documentation (voir ci-dessous)
```

---

## 🚀 DÉMARRAGE RAPIDE

### Option 1 : Backup Manuel (5-10 minutes)

```powershell
cd "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing"
.\scripts\sync-production-hetzner.ps1 -ServerIP "46.62.168.55" -User "root"
```

📖 **Voir** : `RECUPERATION-RAPIDE.md`

### Option 2 : Backup Automatique Hebdomadaire (Installation 5 min)

1. Configurer clé SSH (une seule fois)
2. Créer tâche planifiée Windows
3. Backups tous les dimanches à 2h00 automatiquement

📖 **Voir** : `GUIDE-BACKUP-AUTOMATIQUE-HEBDOMADAIRE.md`

---

## 📚 DOCUMENTATION DISPONIBLE

### 🔴 Essentiels

| Fichier | Description | Quand l'utiliser |
|---------|-------------|------------------|
| **RECUPERATION-RAPIDE.md** | Guide rapide 1 page | Besoin d'un backup maintenant |
| **GUIDE-BACKUP-AUTOMATIQUE-HEBDOMADAIRE.md** | Installation backup auto | Configuration initiale |

### 🟡 Complémentaires

| Fichier | Description |
|---------|-------------|
| **GUIDE-RECUPERATION-PRODUCTION-HETZNER.md** | Guide complet 10 étapes détaillées |
| **ANALYSE-COMPARATIVE-SYSTEMES-EMAILING.md** | Analyse complète des 3 systèmes d'emailing |
| **FLUX-ARCHITECTURE-EMAILING-VISUEL.md** | Diagrammes et schémas d'architecture |
| **RESUME-EXECUTIF-SYSTEMES-EMAILING.md** | Résumé exécutif (3 minutes) |

---

## 🛠️ SCRIPTS DISPONIBLES

### `scripts/sync-production-hetzner.ps1`

**Backup manuel avec un seul clic**

```powershell
.\scripts\sync-production-hetzner.ps1 -ServerIP "46.62.168.55" -User "root"
```

**Fonctionnalités** :
- ✅ Connexion SSH automatique
- ✅ Backup complet (MySQL + MailWizz + PowerMTA)
- ✅ Téléchargement et extraction
- ✅ Sauvegarde ancien backup
- ✅ Nettoyage serveur

**Durée** : 5-10 minutes

---

### `scripts/automated-weekly-backup.ps1`

**Backup automatique hebdomadaire**

Exécuté automatiquement par Windows Task Scheduler.

**Fonctionnalités** :
- ✅ Backup automatique chaque dimanche 2h00
- ✅ Rotation intelligente (garde 2 backups max)
- ✅ Logging complet
- ✅ Vérification intégrité
- ✅ Nettoyage automatique

**Configuration** : Voir `GUIDE-BACKUP-AUTOMATIQUE-HEBDOMADAIRE.md`

---

## 📊 INFORMATIONS SERVEUR

### Configuration Actuelle

- **Serveur** : mail-server (Hetzner CPX22)
- **IP principale** : 46.62.168.55
- **IP secondaire** : 95.216.179.163
- **OS** : Ubuntu 24.04.3 LTS
- **CPU** : 2 vCPU
- **RAM** : 4 GB
- **Stockage** : 40 GB SSD

### Stack Logicielle

- **MailWizz** : 2.2.11 (PHP 8.x)
- **PowerMTA** : 5.0r9
- **MySQL/MariaDB** : 10.x
- **Nginx/Apache** : Web server
- **PHP-FPM** : PHP processor

### Base de Données

- **Nom** : `mailapp`
- **Tables** : 150+
- **Campagnes** : 77 autoresponders
- **Templates** : 106 templates emails
- **Taille** : ~1-2 MB (compressé)

### Contenu Backups

Chaque backup contient :

1. **Base de données** (`mailapp-*.sql.gz`) : 0.5-2 MB
2. **Application MailWizz** (`mailwizz-*.tar.gz`) : 100-150 MB
3. **Config PowerMTA** (`pmta-config-*`) : 50-100 KB
4. **Licence PowerMTA** (`pmta-license-*`) : Quelques KB
5. **Clés DKIM** (`pmta-dkim/`) : 5-50 KB par domaine

**Taille totale** : ~110-150 MB par backup

---

## 🔐 SÉCURITÉ

### Fichiers Sensibles (JAMAIS commit Git)

Le `.gitignore` est configuré pour exclure :

```
# Backups sensibles
mailwizz_transactionnel/*.sql*
mailwizz_transactionnel/*.tar.gz
backups-auto/**/*.sql*
backups-auto/**/*.tar.gz
*.tar.gz

# Configs sensibles
pmta-config-*
pmta-license-*
pmta-dkim/

# Logs et temporaires
logs/*.log
*.tmp
*.bak
```

### Authentification SSH

**Méthode recommandée** : Clé SSH (pas de mot de passe dans scripts)

```powershell
# Générer clé (si pas déjà fait)
ssh-keygen -t ed25519 -C "backup-automatique"

# Copier sur serveur
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh root@46.62.168.55 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# Tester
ssh root@46.62.168.55 "echo 'OK'"
```

---

## 📈 SURVEILLANCE

### Vérifier le dernier backup automatique

```powershell
cd "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing"

# Lister les backups
Get-ChildItem backups-auto\ -Directory | Select-Object Name, CreationTime

# Voir le log
Get-Content logs\backup-hebdo.log -Tail 50
```

### Vérifier la tâche planifiée

```powershell
# Statut
Get-ScheduledTask -TaskName "BackupHebdomadaire" | Get-ScheduledTaskInfo

# Dernière exécution
Get-ScheduledTask -TaskName "BackupHebdomadaire" | Select-Object TaskName, State, @{Name="LastRun"; Expression={(Get-ScheduledTaskInfo $_).LastRunTime}}
```

---

## 🆘 DÉPANNAGE RAPIDE

### Connexion SSH refusée

```powershell
# Tester la connectivité
Test-NetConnection -ComputerName 46.62.168.55 -Port 22

# Vérifier SSH
ssh -V
```

### Script PowerShell bloqué

```powershell
# Autoriser l'exécution (une seule fois)
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### Backup corrompu

```powershell
# Vérifier intégrité d'une archive
tar -tzf .\backups-auto\mailwizz-backup-*\*.tar.gz | Select-Object -First 20
```

### Espace disque insuffisant

```powershell
# Vérifier l'espace disponible
Get-PSDrive C | Select-Object Used, Free

# Supprimer vieux backups manuellement
Remove-Item backups-auto\mailwizz-backup-VIEUX-DATE -Recurse -Force
```

---

## 🔄 WORKFLOW TYPIQUE

### Utilisation Quotidienne

1. **Laisser les backups automatiques tourner** (chaque dimanche 2h00)
2. **Consulter les logs** hebdomadairement
3. **Vérifier l'espace disque** mensuellement

### En cas de besoin urgent

```powershell
# Backup manuel immédiat
.\scripts\sync-production-hetzner.ps1 -ServerIP "46.62.168.55" -User "root"
```

### Restauration

1. Identifier le backup à restaurer dans `backups-auto/`
2. Extraire les fichiers nécessaires
3. Upload vers serveur (voir guide complet)

---

## 🎯 RECOMMANDATIONS

### Fréquence de Backup

- ✅ **Automatique hebdomadaire** : Suffisant pour MailWizz (faible changement)
- ⚠️ **Si nombreuses modifications** : Passer à quotidien ou bi-hebdomadaire

Modifier dans Task Scheduler : Propriétés → Déclencheurs

### Rétention

- ✅ **2 backups** : Recommandé (balance sécurité/espace)
- ⚠️ **Si espace disponible** : Augmenter à 4-6 backups

Modifier dans `automated-weekly-backup.ps1` ligne 17 : `$MaxBackups = 4`

### Surveillance

- ✅ Vérifier le log chaque lundi (après backup dimanche)
- ✅ Tester une restauration tous les 3 mois
- ✅ Valider l'intégrité des backups mensuellement

---

## 📞 SUPPORT ET RESSOURCES

### Commandes Utiles

```powershell
# Tester backup manuel
.\scripts\sync-production-hetzner.ps1 -ServerIP "46.62.168.55" -User "root"

# Forcer backup automatique maintenant
schtasks /run /tn "MailWizz\BackupHebdomadaire"

# Voir log en temps réel
Get-Content logs\backup-hebdo.log -Wait

# Lister tous les backups
Get-ChildItem backups-auto\ -Directory | Sort-Object CreationTime -Descending

# Taille totale des backups
Get-ChildItem backups-auto\ -Recurse -File | Measure-Object -Property Length -Sum | Select-Object @{Name="Total (GB)"; Expression={[math]::Round($_.Sum / 1GB, 2)}}
```

### Documentation Externe

- **MailWizz Docs** : https://www.mailwizz.com/kb/
- **PowerMTA Docs** : Port25 Documentation
- **Hetzner Panel** : https://console.hetzner.cloud/

---

## 📝 CHANGELOG

### 2026-02-16
- ✅ Création du système de backup automatique hebdomadaire
- ✅ Script `automated-weekly-backup.ps1` avec rotation
- ✅ Tâche planifiée Windows configurée
- ✅ Documentation complète (3 guides)
- ✅ Renommage `backup-cold` → `mailwizz_transactionnel`

### 2026-02-15
- ✅ Premier backup manuel de production réussi
- ✅ Script `sync-production-hetzner.ps1` créé
- ✅ Guide de récupération rapide créé

---

## ✅ CHECKLIST DE CONFIGURATION

### Installation Initiale

- [ ] Tester connexion SSH au serveur
- [ ] Configurer clé SSH pour auth sans mot de passe
- [ ] Tester script manuel `sync-production-hetzner.ps1`
- [ ] Installer la tâche planifiée Windows
- [ ] Tester la tâche planifiée manuellement
- [ ] Vérifier le premier backup automatique (dimanche suivant)
- [ ] Valider la rotation (suppression anciens backups)

### Maintenance Continue

- [ ] Vérifier les logs chaque lundi
- [ ] Tester une restauration tous les 3 mois
- [ ] Valider l'espace disque disponible mensuellement
- [ ] Mettre à jour la doc si changements

---

**Dernière mise à jour** : 16 février 2026
**Version** : 1.0.0
**Maintenu par** : Claude Code

---

## 🎉 VOUS ÊTES PRÊT !

Votre système de backup est maintenant opérationnel. Pour toute question, consultez les guides détaillés ci-dessus.

**Prochaines étapes** :
1. Lire `GUIDE-BACKUP-AUTOMATIQUE-HEBDOMADAIRE.md`
2. Configurer l'authentification SSH
3. Installer la tâche planifiée
4. Tester le premier backup

Bon courage ! 🚀
