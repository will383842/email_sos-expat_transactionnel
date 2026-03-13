# 🎯 COMMENCER ICI - Système de Backup MailWizz

**Créé le** : 16 février 2026
**Serveur** : mail-server (46.62.168.55)

---

## 🚀 VOUS AVEZ MAINTENANT 2 OPTIONS

### Option 1️⃣ : Backup Manuel (Immédiat)

**Quand l'utiliser** : Besoin d'un backup MAINTENANT

```powershell
cd "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing"
.\scripts\sync-production-hetzner.ps1 -ServerIP "46.62.168.55" -User "root"
```

📖 **Guide** : `RECUPERATION-RAPIDE.md`

⏱️ **Durée** : 5-10 minutes

---

### Option 2️⃣ : Backup Automatique Hebdomadaire (Configuration)

**Quand l'utiliser** : Vous voulez des backups automatiques chaque semaine

**Installation (5 minutes)** :

#### Étape 1 : Configurer SSH sans mot de passe

```powershell
# Générer clé SSH
ssh-keygen -t ed25519 -C "backup-auto"

# Copier sur serveur
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh root@46.62.168.55 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# Tester
ssh root@46.62.168.55 "echo 'Connexion OK'"
```

#### Étape 2 : Créer la tâche planifiée

1. Ouvrir le Planificateur de tâches Windows : `Windows + R` → `taskschd.msc`
2. Clic droit → "Importer une tâche..."
3. Sélectionner : `scripts\TaskScheduler-BackupHebdo.xml`
4. Configurer votre compte utilisateur
5. Enregistrer

#### Étape 3 : Tester

```powershell
# Forcer l'exécution maintenant (sans attendre dimanche)
schtasks /run /tn "MailWizz\BackupHebdomadaire"

# Suivre le log
Get-Content logs\backup-hebdo.log -Wait
```

📖 **Guide complet** : `GUIDE-BACKUP-AUTOMATIQUE-HEBDOMADAIRE.md`

⏱️ **Configuration** : 5 minutes (une seule fois)

---

## 📁 VOS BACKUPS

### Backup Manuel Actuel

```
mailwizz_transactionnel/
  ├── mailapp-production-*.sql.gz      # Base de données
  ├── mailwizz-production-*.tar.gz     # Application MailWizz
  ├── pmta-config-production-*          # Config PowerMTA
  └── pmta-dkim/                        # Clés DKIM
```

### Backups Automatiques (après configuration)

```
backups-auto/
  ├── mailwizz-backup-20260223-020000/  # Backup le plus récent
  └── mailwizz-backup-20260216-020000/  # Backup précédent
```

**Rotation automatique** : Garde seulement les 2 plus récents

---

## 📊 COMMANDES UTILES

### Vérifier les backups

```powershell
cd "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing"

# Lister les backups automatiques
Get-ChildItem backups-auto\ -Directory | Select-Object Name, CreationTime

# Voir la taille totale
Get-ChildItem backups-auto\ -Recurse -File | Measure-Object -Property Length -Sum
```

### Consulter les logs

```powershell
# Dernières 50 lignes du log
Get-Content logs\backup-hebdo.log -Tail 50

# Suivre en temps réel
Get-Content logs\backup-hebdo.log -Wait
```

### Gérer la tâche planifiée

```powershell
# Statut
Get-ScheduledTask -TaskName "BackupHebdomadaire"

# Dernière exécution
Get-ScheduledTask -TaskName "BackupHebdomadaire" | Get-ScheduledTaskInfo

# Désactiver temporairement
Disable-ScheduledTask -TaskName "MailWizz\BackupHebdomadaire"

# Réactiver
Enable-ScheduledTask -TaskName "MailWizz\BackupHebdomadaire"
```

---

## 🗂️ TOUS LES FICHIERS CRÉÉS

### 📖 Documentation

| Fichier | Description |
|---------|-------------|
| **COMMENCER-ICI.md** | ← Vous êtes ici ! Point de départ |
| **README.md** | Vue d'ensemble complète du projet |
| **RECUPERATION-RAPIDE.md** | Guide rapide 1 page (backup manuel) |
| **GUIDE-BACKUP-AUTOMATIQUE-HEBDOMADAIRE.md** | Guide complet backup auto |
| **GUIDE-RECUPERATION-PRODUCTION-HETZNER.md** | Guide détaillé 10 étapes |

### 🛠️ Scripts

| Fichier | Usage |
|---------|-------|
| **scripts/sync-production-hetzner.ps1** | Backup manuel en un clic |
| **scripts/automated-weekly-backup.ps1** | Backup automatique hebdomadaire |
| **scripts/TaskScheduler-BackupHebdo.xml** | Tâche Windows Task Scheduler |

### 📁 Répertoires

| Dossier | Contenu |
|---------|---------|
| **mailwizz_transactionnel/** | Backup manuel actuel |
| **backups-auto/** | Backups automatiques (max 2) |
| **logs/** | Logs des backups automatiques |
| **scripts/** | Scripts PowerShell |

---

## 🎯 RECOMMANDATIONS

### Pour Débuter

1. ✅ Testez d'abord un **backup manuel** (Option 1)
2. ✅ Si ça fonctionne, configurez le **backup automatique** (Option 2)
3. ✅ Vérifiez les logs chaque lundi

### Pour la Production

- **Backup manuel** : Avant toute modification importante sur le serveur
- **Backup automatique** : Pour avoir toujours un historique de 2 semaines
- **Vérification** : Testez une restauration tous les 3 mois

### Fréquence

- **Hebdomadaire** (défaut) : Suffisant pour MailWizz (peu de changements)
- **Quotidien** : Si vous faites beaucoup de modifications
- **Bi-hebdomadaire** : Alternative économe en espace

Pour changer : Task Scheduler → Propriétés → Déclencheurs

---

## ✅ CHECKLIST RAPIDE

### Installation Backup Automatique

- [ ] SSH fonctionne : `ssh root@46.62.168.55`
- [ ] Clé SSH configurée (connexion sans mot de passe)
- [ ] Script manuel testé avec succès
- [ ] Tâche planifiée créée et active
- [ ] Tâche testée manuellement (`schtasks /run`)
- [ ] Premier backup automatique dans `backups-auto/`
- [ ] Log créé dans `logs/backup-hebdo.log`

---

## 🆘 BESOIN D'AIDE ?

### Erreur Commune 1 : "SSH connection refused"

```powershell
# Vérifier que le serveur est accessible
Test-NetConnection -ComputerName 46.62.168.55 -Port 22
```

### Erreur Commune 2 : "Script bloqué"

```powershell
# Autoriser l'exécution de scripts PowerShell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### Erreur Commune 3 : "Password required" (backup auto)

➡️ Vous devez configurer la clé SSH (voir Étape 1 de l'Option 2)

---

## 📚 POUR ALLER PLUS LOIN

### Documentation Système

- `ANALYSE-COMPARATIVE-SYSTEMES-EMAILING.md` - Analyse complète des 3 systèmes
- `FLUX-ARCHITECTURE-EMAILING-VISUEL.md` - Diagrammes d'architecture
- `RESUME-EXECUTIF-SYSTEMES-EMAILING.md` - Résumé exécutif 3 minutes

### Informations Serveur

- **Panel Hetzner** : https://console.hetzner.cloud/
- **IP principale** : 46.62.168.55
- **OS** : Ubuntu 24.04.3 LTS
- **Stack** : MailWizz 2.2.11 + PowerMTA 5.0r9

---

## 🎉 VOUS ÊTES PRÊT !

Choisissez votre option :

- **Option 1** : Backup manuel immédiat → Suivez `RECUPERATION-RAPIDE.md`
- **Option 2** : Backup automatique hebdo → Suivez `GUIDE-BACKUP-AUTOMATIQUE-HEBDOMADAIRE.md`

**Questions** : Consultez le `README.md` pour plus d'infos.

---

**Document créé par Claude Code - 16 février 2026**

🚀 **Bon backup !**
