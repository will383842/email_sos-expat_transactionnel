# 📥 Guide de Récupération - Production Hetzner vers Local

**Date** : 16 février 2026
**Objectif** : Récupérer la version de production MailWizz + PowerMTA depuis Hetzner et synchroniser avec backup-cold local

---

## 📋 TABLE DES MATIÈRES

1. [Prérequis](#1-prérequis)
2. [Étape 1 : Connexion au serveur](#étape-1--connexion-au-serveur)
3. [Étape 2 : Backup base de données](#étape-2--backup-base-de-données)
4. [Étape 3 : Backup MailWizz](#étape-3--backup-mailwizz)
5. [Étape 4 : Backup PowerMTA](#étape-4--backup-powermta)
6. [Étape 5 : Téléchargement local](#étape-5--téléchargement-local)
7. [Étape 6 : Mise à jour backup-cold](#étape-6--mise-à-jour-backup-cold)
8. [Vérification](#vérification)

---

## 1. PRÉREQUIS

### Informations nécessaires

**Vous devez avoir** :
- ✅ IP du serveur Hetzner de production
- ✅ Accès SSH (user + mot de passe ou clé SSH)
- ✅ Accès root ou sudo
- ✅ ~500 MB d'espace libre sur votre PC Windows

### Logiciels requis (Windows)

```powershell
# Vérifier si vous avez SSH (inclus dans Windows 10+)
ssh -V

# Si absent, installer via PowerShell (admin)
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

# Installer WinSCP (GUI pour transfert fichiers)
# Télécharger : https://winscp.net/eng/download.php
```

---

## ÉTAPE 1 : CONNEXION AU SERVEUR

### 1.1 Identifier le serveur de production

**Option A : Via Panel Hetzner**
1. Connexion : https://console.hetzner.cloud/
2. Login avec vos credentials
3. Aller dans **Servers**
4. Identifier votre serveur MailWizz (probablement nommé "mailwizz" ou "mail-server")
5. Noter l'**IP publique**

**Option B : Si vous avez déjà l'IP**
```powershell
# Tester la connexion
ping VOTRE_IP_SERVEUR

# Exemple
ping 89.167.26.169
```

### 1.2 Connexion SSH

```powershell
# Ouvrir PowerShell ou Terminal Windows
# Remplacer VOTRE_IP_SERVEUR par l'IP réelle
ssh root@VOTRE_IP_SERVEUR

# Si vous avez un utilisateur non-root
ssh votre_user@VOTRE_IP_SERVEUR
```

**Exemple** :
```bash
ssh root@89.167.26.169
# Entrer le mot de passe quand demandé
```

### 1.3 Vérifier le système

```bash
# Une fois connecté, vérifier l'OS
cat /etc/os-release

# Vérifier les services
systemctl status pmta
systemctl status nginx
systemctl status mariadb  # ou mysql
systemctl status php-fpm

# Vérifier MailWizz
ls -lh /var/www/mailwizz

# Vérifier PowerMTA
ls -lh /etc/pmta/
pmta show status
```

---

## ÉTAPE 2 : BACKUP BASE DE DONNÉES

### 2.1 Identifier la base de données MailWizz

```bash
# Lister les bases de données
mysql -u root -p -e "SHOW DATABASES;"

# Trouver la base MailWizz (généralement "mailapp" ou "mailwizz")
# Vérifier la taille
mysql -u root -p -e "SELECT
  table_schema AS 'Database',
  ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
FROM information_schema.TABLES
WHERE table_schema = 'mailapp'
GROUP BY table_schema;"
```

### 2.2 Dump de la base de données

```bash
# Créer un répertoire temporaire
mkdir -p /root/backup-mailwizz-$(date +%Y%m%d)
cd /root/backup-mailwizz-$(date +%Y%m%d)

# Backup de la base mailapp
mysqldump -u root -p mailapp > mailapp-production-$(date +%Y%m%d).sql

# Compresser pour gagner de l'espace
gzip mailapp-production-$(date +%Y%m%d).sql

# Vérifier la taille
ls -lh mailapp-production-*.sql.gz
```

**Exemple de sortie** :
```
-rw-r--r-- 1 root root 1.2M Feb 16 10:30 mailapp-production-20260216.sql.gz
```

---

## ÉTAPE 3 : BACKUP MAILWIZZ

### 3.1 Localiser MailWizz

```bash
# Vérifier l'emplacement (généralement /var/www/mailwizz)
ls -lh /var/www/mailwizz/

# Vérifier la version
cat /var/www/mailwizz/apps/common/data/version-info.php | grep -i version
```

### 3.2 Créer une archive MailWizz

```bash
# Se positionner dans /var/www/
cd /var/www/

# Créer une archive (exclure cache et logs volumineux)
tar -czf /root/backup-mailwizz-$(date +%Y%m%d)/mailwizz-production-$(date +%Y%m%d).tar.gz \
  --exclude='mailwizz/apps/common/runtime/*' \
  --exclude='mailwizz/apps/frontend/runtime/*' \
  --exclude='mailwizz/apps/customer/runtime/*' \
  --exclude='mailwizz/apps/backend/runtime/*' \
  --exclude='mailwizz/apps/common/cache/*' \
  mailwizz/

# Vérifier la taille
ls -lh /root/backup-mailwizz-*/mailwizz-production-*.tar.gz
```

**Exemple de sortie** :
```
-rw-r--r-- 1 root root 145M Feb 16 10:35 mailwizz-production-20260216.tar.gz
```

---

## ÉTAPE 4 : BACKUP POWERMTA

### 4.1 Backup configuration PowerMTA

```bash
# Créer backup config
cd /root/backup-mailwizz-$(date +%Y%m%d)

# Copier la config principale
cp /etc/pmta/config pmta-config-production-$(date +%Y%m%d)

# Copier la licence
cp /etc/pmta/license pmta-license-production-$(date +%Y%m%d)

# Si vous avez des configs supplémentaires
cp -r /etc/pmta/ pmta-etc-production-$(date +%Y%m%d)/
```

### 4.2 Backup clés DKIM

```bash
# Trouver les clés DKIM (généralement dans /home/pmta/ ou /etc/pmta/)
find /home/pmta -name "dkim.pem" 2>/dev/null
find /etc/pmta -name "*.pem" 2>/dev/null

# Créer répertoire DKIM
mkdir -p /root/backup-mailwizz-$(date +%Y%m%d)/pmta-dkim/

# Copier les clés DKIM (ajuster le chemin si nécessaire)
cp -r /home/pmta/mail/ /root/backup-mailwizz-$(date +%Y%m%d)/pmta-dkim/ 2>/dev/null
cp -r /home/pmta/conf/ /root/backup-mailwizz-$(date +%Y%m%d)/pmta-dkim/ 2>/dev/null
```

### 4.3 Informations système PowerMTA

```bash
# Récupérer les infos PowerMTA
pmta show version > /root/backup-mailwizz-$(date +%Y%m%d)/pmta-version.txt
pmta show status > /root/backup-mailwizz-$(date +%Y%m%d)/pmta-status.txt

# Lister les Virtual MTAs
pmta show vmtas > /root/backup-mailwizz-$(date +%Y%m%d)/pmta-vmtas.txt

# Lister les IPs
ip addr show | grep "inet " > /root/backup-mailwizz-$(date +%Y%m%d)/server-ips.txt
```

---

## ÉTAPE 5 : TÉLÉCHARGEMENT LOCAL

### 5.1 Créer une archive complète

```bash
# Sur le serveur, créer une archive finale
cd /root/
tar -czf backup-mailwizz-hetzner-production-$(date +%Y%m%d).tar.gz backup-mailwizz-$(date +%Y%m%d)/

# Vérifier la taille finale
ls -lh backup-mailwizz-hetzner-production-*.tar.gz
```

### 5.2 Télécharger via SCP (Windows PowerShell)

**Option A : Via SCP (ligne de commande)**

```powershell
# Ouvrir PowerShell sur votre PC Windows
# Naviguer vers le dossier cible
cd "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\backup-cold"

# Télécharger l'archive (remplacer VOTRE_IP_SERVEUR)
scp root@VOTRE_IP_SERVEUR:/root/backup-mailwizz-hetzner-production-*.tar.gz .

# Exemple
scp root@89.167.26.169:/root/backup-mailwizz-hetzner-production-20260216.tar.gz .
```

**Option B : Via WinSCP (GUI - Recommandé pour gros fichiers)**

1. Ouvrir **WinSCP**
2. Créer nouvelle session :
   - **File protocol** : SCP
   - **Host name** : VOTRE_IP_SERVEUR
   - **Port** : 22
   - **User name** : root
   - **Password** : votre_mot_de_passe
3. Cliquer **Login**
4. Naviguer côté serveur : `/root/`
5. Naviguer côté local : `C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\backup-cold`
6. Glisser-déposer le fichier `backup-mailwizz-hetzner-production-*.tar.gz`
7. Attendre la fin du téléchargement (peut prendre 5-10 min selon la taille)

### 5.3 Télécharger fichiers individuels (optionnel)

Si l'archive est trop grosse, télécharger séparément :

```powershell
# Base de données seule
scp root@VOTRE_IP_SERVEUR:/root/backup-mailwizz-*/mailapp-production-*.sql.gz .

# MailWizz seul
scp root@VOTRE_IP_SERVEUR:/root/backup-mailwizz-*/mailwizz-production-*.tar.gz .

# Config PowerMTA
scp root@VOTRE_IP_SERVEUR:/root/backup-mailwizz-*/pmta-config-production-* .
```

---

## ÉTAPE 6 : MISE À JOUR BACKUP-COLD

### 6.1 Extraire l'archive

```powershell
# Dans PowerShell (si vous avez 7-Zip ou tar installé)
cd "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\backup-cold"

# Extraire avec 7-Zip (si installé)
7z x backup-mailwizz-hetzner-production-20260216.tar.gz
7z x backup-mailwizz-hetzner-production-20260216.tar

# Ou avec tar (Windows 10+ natif)
tar -xzf backup-mailwizz-hetzner-production-20260216.tar.gz
```

**Ou via Windows Explorer** :
1. Clic droit sur `backup-mailwizz-hetzner-production-*.tar.gz`
2. Extraire tout → Choisir dossier actuel

### 6.2 Remplacer les fichiers existants

```powershell
# Sauvegarder l'ancien backup-cold (au cas où)
cd "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing"
Rename-Item "backup-cold" "backup-cold-OLD-$(Get-Date -Format 'yyyyMMdd')"

# Renommer le nouveau backup
Rename-Item "backup-mailwizz-20260216" "backup-cold"
```

**Ou manuellement** :
1. Renommer `backup-cold` → `backup-cold-OLD-20260216`
2. Renommer `backup-mailwizz-20260216` → `backup-cold`

### 6.3 Organiser les fichiers

```powershell
cd backup-cold

# Structure finale souhaitée
# backup-cold/
# ├── mailapp-production-20260216.sql.gz
# ├── mailwizz-production-20260216.tar.gz
# ├── pmta-config-production-20260216
# ├── pmta-etc-production-20260216/
# ├── pmta-dkim/
# ├── pmta-version.txt
# └── BACKUP-INFO.txt

# Créer un fichier d'information
@"
==========================================================
BACKUP RÉCUPÉRÉ DEPUIS PRODUCTION HETZNER
==========================================================

Date backup : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Serveur source : VOTRE_IP_SERVEUR
OS serveur : Rocky Linux 9 / AlmaLinux 9
Taille totale : $(Get-ChildItem -Recurse | Measure-Object -Property Length -Sum | Select-Object -ExpandProperty Sum) bytes

Contenu :
- Base de données MailWizz : mailapp-production-*.sql.gz
- Application MailWizz : mailwizz-production-*.tar.gz
- Config PowerMTA : pmta-config-production-*
- Clés DKIM : pmta-dkim/
- Info système : pmta-version.txt, pmta-status.txt, server-ips.txt

==========================================================
"@ | Out-File -FilePath "BACKUP-INFO.txt" -Encoding UTF8
```

---

## VÉRIFICATION

### Sur votre PC Windows

```powershell
cd "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing\backup-cold"

# Lister les fichiers
Get-ChildItem -Recurse | Select-Object FullName, Length

# Vérifier la base de données
Get-Item mailapp-production-*.sql.gz | Select-Object Name, Length, LastWriteTime

# Vérifier MailWizz
Get-Item mailwizz-production-*.tar.gz | Select-Object Name, Length, LastWriteTime

# Vérifier PowerMTA
Get-ChildItem pmta-* | Select-Object Name, Length
```

### Vérifier le contenu SQL (optionnel)

```powershell
# Extraire le fichier .sql.gz
7z x mailapp-production-20260216.sql.gz

# Ouvrir avec un éditeur de texte (premiers 100 lignes)
Get-Content mailapp-production-20260216.sql -Head 100

# Rechercher des tables importantes
Select-String -Path mailapp-production-20260216.sql -Pattern "CREATE TABLE.*mw_campaign" | Select-Object -First 5
Select-String -Path mailapp-production-20260216.sql -Pattern "CREATE TABLE.*mw_customer_email_template" | Select-Object -First 5
```

### Checklist finale

- [ ] ✅ Base de données récupérée (mailapp-production-*.sql.gz)
- [ ] ✅ Application MailWizz récupérée (mailwizz-production-*.tar.gz)
- [ ] ✅ Configuration PowerMTA récupérée (pmta-config-production-*)
- [ ] ✅ Clés DKIM récupérées (pmta-dkim/)
- [ ] ✅ Informations système sauvegardées (pmta-version.txt, etc.)
- [ ] ✅ Ancien backup-cold sauvegardé (backup-cold-OLD-*)
- [ ] ✅ Nouveau backup-cold organisé et documenté

---

## 🔐 NETTOYAGE SERVEUR (Important!)

```bash
# Sur le serveur Hetzner, supprimer le backup temporaire
ssh root@VOTRE_IP_SERVEUR

# Supprimer le répertoire de backup
rm -rf /root/backup-mailwizz-*
rm -f /root/backup-mailwizz-hetzner-production-*.tar.gz

# Vérifier l'espace libéré
df -h
```

---

## 📊 COMPARAISON ANCIEN vs NOUVEAU

### Comparer les versions

```powershell
# Si vous avez Git installé
cd "C:\Users\willi\Documents\Projets\VS_CODE\sos-expat-project\Outils d'emailing"

# Comparer les fichiers
Compare-Object -ReferenceObject (Get-ChildItem backup-cold-OLD-* -Recurse) `
               -DifferenceObject (Get-ChildItem backup-cold -Recurse) `
               -Property Name, Length

# Afficher les différences
```

### Extraire et comparer les bases SQL (avancé)

```powershell
# Extraire l'ancienne base
cd backup-cold-OLD-20260216
7z x mailapp-reference.sql  # Si compressé

# Extraire la nouvelle base
cd ../backup-cold
7z x mailapp-production-20260216.sql.gz

# Comparer le nombre de tables
Select-String -Path ../backup-cold-OLD-20260216/mailapp-reference.sql -Pattern "CREATE TABLE" | Measure-Object
Select-String -Path mailapp-production-20260216.sql -Pattern "CREATE TABLE" | Measure-Object

# Comparer le nombre de campagnes
Select-String -Path ../backup-cold-OLD-20260216/mailapp-reference.sql -Pattern "INSERT INTO.*mw_campaign" | Measure-Object
Select-String -Path mailapp-production-20260216.sql -Pattern "INSERT INTO.*mw_campaign" | Measure-Object
```

---

## 🆘 DÉPANNAGE

### Problème 1 : Connexion SSH refusée

```powershell
# Vérifier si le serveur est accessible
Test-NetConnection -ComputerName VOTRE_IP_SERVEUR -Port 22

# Si timeout, vérifier firewall Hetzner
# Aller sur Panel Hetzner → Firewall → Autoriser port 22 depuis votre IP
```

### Problème 2 : Transfert SCP très lent

```powershell
# Utiliser compression
scp -C root@VOTRE_IP_SERVEUR:/root/backup-*.tar.gz .

# Ou utiliser rsync (si disponible)
rsync -avz --progress root@VOTRE_IP_SERVEUR:/root/backup-*.tar.gz .
```

### Problème 3 : Archive corrompue

```bash
# Sur le serveur, vérifier l'intégrité
cd /root/
tar -tzf backup-mailwizz-hetzner-production-*.tar.gz | head -20

# Si erreur, recréer l'archive
cd /root/
tar -czf backup-mailwizz-hetzner-production-NEW-$(date +%Y%m%d).tar.gz backup-mailwizz-*/
```

### Problème 4 : Pas assez d'espace

```bash
# Sur le serveur, vérifier l'espace
df -h

# Si nécessaire, télécharger fichiers séparément au lieu d'une grosse archive
# Puis supprimer chaque fichier après téléchargement
```

---

## 📝 NOTES IMPORTANTES

### Sécurité
- ⚠️ **Ne jamais commit** les backups dans Git (contiennent mots de passe)
- ⚠️ **Ajouter au .gitignore** : `backup-cold/mailapp-*.sql*`, `backup-cold/mailwizz-*.tar.gz`
- ⚠️ **Supprimer les backups** du serveur après téléchargement

### Automatisation
Pour récupérer automatiquement les backups régulièrement :
```powershell
# Créer un script PowerShell backup-sync.ps1
# Planifier avec Task Scheduler Windows
# Voir : https://docs.microsoft.com/en-us/windows/desktop/taskschd/task-scheduler-start-page
```

### Documentation
- 📄 Mettre à jour `BACKUP-INFO.txt` à chaque récupération
- 📄 Noter les différences majeures entre versions
- 📄 Documenter les nouvelles campagnes/templates ajoutés en production

---

## 🔗 LIENS UTILES

- **Panel Hetzner** : https://console.hetzner.cloud/
- **WinSCP Download** : https://winscp.net/eng/download.php
- **7-Zip Download** : https://www.7-zip.org/download.html
- **Git for Windows** : https://git-scm.com/download/win

---

**Document créé par Claude Code le 16 février 2026**
**Version** : 1.0.0
**Dernière mise à jour** : 16 février 2026
