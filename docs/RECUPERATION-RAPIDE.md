# ⚡ Récupération Rapide - Production Hetzner

**Mise à jour rapide de mailwizz_transactionnel depuis le serveur de production**

---

## 🚀 MÉTHODE AUTOMATISÉE (Recommandée)

### Une seule commande

```powershell
# Ouvrir PowerShell
cd "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing"

# Exécuter le script avec VOTRE IP Hetzner
.\scripts\sync-production-hetzner.ps1 -ServerIP "46.62.168.55" -User "root"

# Entrer le mot de passe SSH quand demandé
# Le script fait tout automatiquement !
```

### Ce que fait le script

1. ✅ Vérifie la connexion au serveur
2. ✅ Crée un backup complet sur le serveur (MySQL + MailWizz + PowerMTA)
3. ✅ Télécharge l'archive (~150 MB)
4. ✅ Sauvegarde l'ancien backup-cold
5. ✅ Extrait et organise les nouveaux fichiers
6. ✅ Crée un fichier d'information
7. ✅ Propose de nettoyer le serveur

**Durée** : 5-10 minutes (selon connexion internet)

---

## ⏰ BACKUP AUTOMATIQUE HEBDOMADAIRE (Recommandé pour utilisation continue)

**Vous voulez des backups automatiques chaque semaine ?**

✅ **Installation en 5 minutes** : Backups tous les dimanches à 2h00
✅ **Rotation automatique** : Garde seulement les 2 backups les plus récents
✅ **Aucune intervention manuelle** : Tout est géré automatiquement

📖 **Voir le guide complet** : `GUIDE-BACKUP-AUTOMATIQUE-HEBDOMADAIRE.md`

**Installation rapide** :

```powershell
# 1. Configurer clé SSH (une seule fois)
ssh-keygen -t ed25519 -C "backup-auto"
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh root@46.62.168.55 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# 2. Créer la tâche planifiée Windows
# Voir le guide GUIDE-BACKUP-AUTOMATIQUE-HEBDOMADAIRE.md
```

**Bénéfices** :
- Plus besoin de faire les backups manuellement
- Historique des 2 dernières semaines conservé
- Logs complets de toutes les opérations
- Vérification automatique de l'intégrité

---

## 🛠️ MÉTHODE MANUELLE (Si script échoue)

### Étape 1 : Connexion SSH

```powershell
ssh root@VOTRE_IP_SERVEUR
# Remplacer VOTRE_IP_SERVEUR par l'IP réelle
```

### Étape 2 : Créer le backup sur le serveur

```bash
# Créer répertoire
DATE=$(date +%Y%m%d)
mkdir -p /root/backup-mailwizz-$DATE
cd /root/backup-mailwizz-$DATE

# Backup MySQL
mysqldump -u root -p mailapp | gzip > mailapp-production-$DATE.sql.gz

# Backup MailWizz
cd /var/www/
tar -czf /root/backup-mailwizz-$DATE/mailwizz-production-$DATE.tar.gz \
  --exclude='mailwizz/apps/*/runtime/*' \
  --exclude='mailwizz/apps/*/cache/*' \
  mailwizz/

# Backup PowerMTA
cp /etc/pmta/config /root/backup-mailwizz-$DATE/pmta-config-production-$DATE
cp -r /home/pmta/mail /root/backup-mailwizz-$DATE/pmta-dkim/

# Créer archive
cd /root/
tar -czf backup-mailwizz-hetzner-$DATE.tar.gz backup-mailwizz-$DATE/

# Vérifier
ls -lh backup-mailwizz-hetzner-$DATE.tar.gz
```

### Étape 3 : Télécharger

**Option A : SCP (ligne de commande)**

```powershell
cd "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\backup-cold"
scp root@VOTRE_IP_SERVEUR:/root/backup-mailwizz-hetzner-*.tar.gz .
```

**Option B : WinSCP (GUI - Recommandé)**

1. Télécharger WinSCP : https://winscp.net/eng/download.php
2. Ouvrir WinSCP
3. Nouvelle session :
   - Host : VOTRE_IP_SERVEUR
   - User : root
   - Password : (votre mot de passe)
4. Se connecter
5. Naviguer vers `/root/`
6. Glisser-déposer `backup-mailwizz-hetzner-*.tar.gz` vers votre PC

### Étape 4 : Extraire et remplacer

```powershell
cd "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing"

# Sauvegarder l'ancien
Rename-Item "backup-cold" "backup-cold-OLD-$(Get-Date -Format 'yyyyMMdd')"

# Extraire le nouveau
tar -xzf backup-cold\backup-mailwizz-hetzner-*.tar.gz

# Renommer
Rename-Item "backup-mailwizz-*" "backup-cold"
```

---

## 📋 CHECKLIST DE VÉRIFICATION

Après récupération, vérifier :

```powershell
cd "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\backup-cold"

# Lister les fichiers
Get-ChildItem | Select-Object Name, Length

# Doit contenir au minimum :
# ✅ mailapp-production-*.sql.gz        (1-2 MB)
# ✅ mailwizz-production-*.tar.gz       (140-150 MB)
# ✅ pmta-config-production-*            (50-100 KB)
# ✅ pmta-dkim/                          (dossier avec clés)
# ✅ BACKUP-INFO-*.txt                   (fichier info)
```

---

## 🆘 DÉPANNAGE RAPIDE

### Problème : Connexion SSH refusée

```powershell
# Vérifier si le serveur est accessible
Test-NetConnection -ComputerName VOTRE_IP_SERVEUR -Port 22

# Si échec :
# 1. Vérifier l'IP dans le Panel Hetzner
# 2. Vérifier le firewall (autoriser votre IP sur port 22)
```

### Problème : Script PowerShell bloqué

```powershell
# Autoriser l'exécution de scripts (une seule fois)
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

# Puis réessayer le script
.\scripts\sync-production-hetzner.ps1 -ServerIP "VOTRE_IP" -User "root"
```

### Problème : MySQL dump échoue

```bash
# Sur le serveur, vérifier si MySQL tourne
systemctl status mariadb
systemctl status mysql

# Si arrêté, démarrer
systemctl start mariadb
# ou
systemctl start mysql
```

### Problème : Fichier corrompu

```powershell
# Vérifier l'intégrité de l'archive
tar -tzf backup-mailwizz-hetzner-*.tar.gz | Select-Object -First 20

# Si erreur, retélécharger
```

---

## 📞 BESOIN D'AIDE ?

### Informations utiles

**Panel Hetzner** : https://console.hetzner.cloud/
- Login : votre email
- Voir : Servers → Cliquer sur votre serveur → Noter l'IP

**Vérifier les IPs actuelles dans backup-cold** :
```powershell
Select-String -Path ".\backup-cold\pmta-*\config" -Pattern "smtp-listener" | Select-Object -First 5
```

### Commandes de diagnostic

```powershell
# Tester la connexion
Test-NetConnection -ComputerName VOTRE_IP_SERVEUR -Port 22

# Vérifier SSH
ssh -V

# Vérifier SCP
scp

# Vérifier tar
tar --version
```

---

## 📚 DOCUMENTATION COMPLÈTE

Pour plus de détails, voir :
- **Guide complet** : `GUIDE-RECUPERATION-PRODUCTION-HETZNER.md`
- **Plan de migration** : `PLAN_MIGRATION_HETZNER.md`
- **Analyse des systèmes** : `../ANALYSE-COMPARATIVE-SYSTEMES-EMAILING.md`

---

**Dernière mise à jour** : 16 février 2026
**Script version** : 1.0.0
