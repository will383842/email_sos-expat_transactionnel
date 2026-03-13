# Plan de Migration - Système Email SOS-Expat vers Hetzner

**Date du plan** : 4 février 2026
**Backups source** : 26-27 novembre 2025
**Système** : MailWizz 2.2.11 + PowerMTA 5.0r9

---

## Table des matières

1. [Hetzner et l'envoi d'emails](#1-hetzner-et-lenvoi-demails)
2. [Ce que tu dois acheter](#2-ce-que-tu-dois-acheter-chez-hetzner)
3. [Phase 1 : Préparation](#phase-1--préparation-avant-achat)
4. [Phase 2 : Achat et Setup Serveur](#phase-2--achat-et-setup-serveur)
5. [Phase 3 : Configuration Serveur](#phase-3--configuration-serveur)
6. [Phase 4 : Installation PowerMTA](#phase-4--installation-powermta)
7. [Phase 5 : Adapter la Config PMTA](#phase-5--adapter-la-config-pmta)
8. [Phase 6 : Installation MailWizz](#phase-6--installation-mailwizz)
9. [Phase 7 : Configuration Nginx](#phase-7--configuration-nginx)
10. [Phase 8 : Configuration DNS](#phase-8--configuration-dns)
11. [Phase 9 : Configuration Crons](#phase-9--configuration-crons-mailwizz)
12. [Phase 10 : Tests Finaux](#phase-10--tests-finaux)
13. [Checklist Récapitulative](#checklist-récapitulative)
14. [Améliorations à faire après migration](#améliorations-à-faire-après-migration)

---

## 1. Hetzner et l'envoi d'emails

### Points à savoir

| Aspect | Hetzner |
|--------|---------|
| **Port 25 sortant** | Bloqué par défaut → demande de déblocage obligatoire |
| **Réputation IPs** | Variable (dépend de l'historique de l'IP attribuée) |
| **Reverse DNS (PTR)** | Configurable via le panel |
| **Déblocage** | Réponse sous 24-48h généralement |
| **Datacenters** | Allemagne, Finlande (bon pour Europe) |

### Verdict

Hetzner **fonctionne** pour l'email mondial, mais :
- Tu dois demander le déblocage du port 25 (formulaire support)
- Les IPs neuves nécessitent un warmup
- Bien pour l'Europe, correct pour le reste du monde

### Alternatives si problème

| Hébergeur | Avantage email |
|-----------|----------------|
| **OVH** | Port 25 souvent ouvert, bon réseau mondial |
| **Vultr** | Déblocage facile, bonne réputation |
| **Contabo** | Moins cher, déjà utilisé avant |

---

## 2. Ce que tu dois acheter chez Hetzner

### Commande recommandée

| Produit | Spec | Prix/mois |
|---------|------|-----------|
| **VPS CX21** (Cloud Server) | 2 vCPU, 4 Go RAM, 40 Go SSD | ~4,85€ |
| **IP supplémentaire** | 1 IP additionnelle | ~3€ |
| **Total** | 1 serveur + 2 IPs | **~8€/mois** |

### Système d'exploitation recommandé

- **Rocky Linux 9** ou **AlmaLinux 9** (successeurs de CentOS, compatibles avec le RPM PowerMTA)

---

## Phase 1 : Préparation (Avant achat)

| Étape | Action | Statut |
|-------|--------|--------|
| 1.1 | Créer compte Hetzner (hetzner.com) | ☐ |
| 1.2 | Vérifier identité (carte ID parfois demandée) | ☐ |
| 1.3 | Extraire mailwizz.zip localement | ☐ |
| 1.4 | Vérifier les fichiers de config | ☐ |

---

## Phase 2 : Achat et Setup Serveur

| Étape | Action | Statut |
|-------|--------|--------|
| 2.1 | Commander Cloud Server CX21 (Datacenter : Falkenstein ou Helsinki) | ☐ |
| 2.2 | Choisir OS : Rocky Linux 9 (64-bit) | ☐ |
| 2.3 | Commander 1 IP supplémentaire (Total = 2 IPs) | ☐ |
| 2.4 | Noter les IPs attribuées | ☐ |
| 2.5 | **Demander déblocage port 25** (Support ticket - OBLIGATOIRE!) | ☐ |

### IPs attribuées (à remplir)

```
IP_1 : ___.___.___.___ (pour mailul.ulixai-expat.com)
IP_2 : ___.___.___.___ (pour mailsos.ulixai-expat.com)
```

---

## Phase 3 : Configuration Serveur

### 3.1 - Connexion SSH

```bash
ssh root@IP_SERVEUR
```

### 3.2 - Mise à jour système

```bash
dnf update -y
```

### 3.3 - Installer les dépendances

```bash
dnf install -y epel-release
dnf install -y wget curl unzip mariadb-server mariadb nginx php php-fpm php-mysqlnd php-cli php-gd php-mbstring php-xml php-curl php-zip php-imap
```

### 3.4 - Démarrer et sécuriser MariaDB

```bash
systemctl enable mariadb --now
mysql_secure_installation
```

### 3.5 - Démarrer Nginx + PHP

```bash
systemctl enable nginx php-fpm --now
```

### 3.6 - Configurer firewall

```bash
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-port=2525/tcp
firewall-cmd --permanent --add-port=1983/tcp
firewall-cmd --permanent --add-port=25/tcp
firewall-cmd --reload
```

---

## Phase 4 : Installation PowerMTA

### 4.1 - Transférer les fichiers (depuis ton PC Windows)

```bash
# Ouvrir PowerShell ou terminal sur ton PC
scp "C:\Users\simon\Documents\Projets\Outils d'emailing\backup-cold\rpm-install-pmta-5.zip" root@IP_SERVEUR:/root/
scp -r "C:\Users\simon\Documents\Projets\Outils d'emailing\backup-cold\pmta-etc\*" root@IP_SERVEUR:/etc/pmta/
scp -r "C:\Users\simon\Documents\Projets\Outils d'emailing\backup-cold\pmta-dkim\*" root@IP_SERVEUR:/home/pmta/
```

### 4.2 - Sur le serveur : extraire et installer

```bash
cd /root
unzip rpm-install-pmta-5.zip
rpm -i PowerMTA-5.0r8.rpm
```

### 4.3 - Créer les dossiers nécessaires

```bash
mkdir -p /var/log/pmta
mkdir -p /var/spool/pmta
mkdir -p /home/pmta/conf/mail/ulixai-expat.com
```

### 4.4 - Copier la licence

```bash
cp /root/license /etc/pmta/license
```

### 4.5 - Copier la clé DKIM

```bash
cp /home/pmta/mail/ulixai-expat.com/dkim.pem /home/pmta/conf/mail/ulixai-expat.com/
chmod 600 /home/pmta/conf/mail/ulixai-expat.com/dkim.pem
```

---

## Phase 5 : Adapter la Config PMTA

### 5.1 - Éditer le fichier de configuration

```bash
nano /etc/pmta/config
```

### 5.2 - Remplacer les anciennes IPs

**AVANT :**
```
smtp-listener 178.18.243.7:2525
smtp-listener 84.247.168.78:2525
```

**APRÈS :**
```
smtp-listener [NOUVELLE_IP_1]:2525
smtp-listener [NOUVELLE_IP_2]:2525
```

### 5.3 - Modifier les Virtual MTAs

**AVANT :**
```
<virtual-mta pmta-vmta0>
smtp-source-host 178.18.243.7 mailul.ulixai-expat.com
```

**APRÈS :**
```
<virtual-mta pmta-vmta0>
smtp-source-host [NOUVELLE_IP_1] mailul.ulixai-expat.com
```

**AVANT :**
```
<virtual-mta pmta-vmta1>
smtp-source-host 84.247.168.78 mailsos.ulixai-expat.com
```

**APRÈS :**
```
<virtual-mta pmta-vmta1>
smtp-source-host [NOUVELLE_IP_2] mailsos.ulixai-expat.com
```

### 5.4 - Changer le mot de passe SMTP (IMPORTANT!)

**AVANT :**
```
<smtp-user admin@ulixai-expat.com>
    password SBlanc1952/*%
    source {pmta-auth}
</smtp-user>
```

**APRÈS :**
```
<smtp-user admin@ulixai-expat.com>
    password NOUVEAU_MOT_DE_PASSE_TRES_FORT
    source {pmta-auth}
</smtp-user>
```

### 5.5 - Démarrer PowerMTA

```bash
systemctl enable pmta pmtahttp --now
systemctl status pmta
```

### 5.6 - Vérifier le statut

```bash
pmta show status
```

---

## Phase 6 : Installation MailWizz

### 6.1 - Transférer MailWizz (depuis ton PC)

```bash
scp "C:\Users\simon\Documents\Projets\Outils d'emailing\backup-cold\mailwizz.zip" root@IP_SERVEUR:/var/www/
```

### 6.2 - Extraire sur le serveur

```bash
cd /var/www
unzip mailwizz.zip -d mailwizz
chown -R nginx:nginx mailwizz
chmod -R 755 mailwizz
```

### 6.3 - Créer la base de données

```bash
mysql -u root -p
```

```sql
CREATE DATABASE mailapp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'mailapp'@'localhost' IDENTIFIED BY 'MOT_DE_PASSE_BDD_FORT';
GRANT ALL PRIVILEGES ON mailapp.* TO 'mailapp'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 6.4 - Importer la base de données

```bash
# Transférer le fichier SQL
scp "C:\Users\simon\Documents\Projets\Outils d'emailing\backup-cold\mailapp-reference.sql" root@IP_SERVEUR:/root/

# Importer
mysql -u root -p mailapp < /root/mailapp-reference.sql
```

### 6.5 - Configurer MailWizz

```bash
nano /var/www/mailwizz/apps/common/data/config/main-custom.php
```

```php
<?php
return [
    'components' => [
        'db' => [
            'connectionString'  => 'mysql:host=localhost;dbname=mailapp',
            'username'          => 'mailapp',
            'password'          => 'MOT_DE_PASSE_BDD_FORT',
            'tablePrefix'       => 'mw_',
        ],
    ],
    'params' => [
        'email.custom.header.prefix' => 'X-Mw-',
    ],
];
```

### 6.6 - Permissions des dossiers

```bash
chmod -R 777 /var/www/mailwizz/apps/common/runtime
chmod -R 777 /var/www/mailwizz/apps/common/data
chmod -R 777 /var/www/mailwizz/frontend/assets/cache
chmod -R 777 /var/www/mailwizz/frontend/assets/files
chmod -R 777 /var/www/mailwizz/customer/assets/cache
chmod -R 777 /var/www/mailwizz/customer/assets/files
chmod -R 777 /var/www/mailwizz/backend/assets/cache
chmod -R 777 /var/www/mailwizz/backend/assets/files
```

### 6.7 - Configuration post-installation MailWizz (IMPORTANT!)

Après l'installation, tu dois configurer MailWizz via l'interface web :

#### A. Activer les serveurs d'envoi (actuellement désactivés)

1. Aller dans **Backend** → **Servers** → **Delivery servers**
2. Pour chaque serveur (Ulixai IP1 et SOS-Expat IP2) :
   - Cliquer sur **Edit**
   - Mettre à jour le **Hostname** avec la nouvelle IP ou hostname
   - Mettre à jour le **Password** avec le nouveau mot de passe PMTA
   - Changer **Status** de `inactive` à `active`
   - Sauvegarder

#### B. Mettre à jour le mot de passe SMTP dans MailWizz

Le mot de passe SMTP est chiffré en base de données. Tu dois le mettre à jour via l'interface :

1. **Backend** → **Servers** → **Delivery servers**
2. Éditer chaque serveur
3. Entrer le **nouveau mot de passe** (celui défini dans `/etc/pmta/config`)
4. Sauvegarder

#### C. Vérifier les URLs système

1. **Backend** → **Settings** → **Common**
2. Vérifier que les URLs sont correctes :
   - Frontend URL : `https://app.mail-ulixai.com/`
   - Backend URL : `https://app.mail-ulixai.com/backend/`
   - Customer URL : `https://app.mail-ulixai.com/customer/`
   - API URL : `https://app.mail-ulixai.com/api/`

#### D. Vérifier le domaine d'envoi

1. **Backend** → **Servers** → **Sending domains**
2. Vérifier que `ulixai-expat.com` est configuré
3. Re-vérifier DKIM/SPF si nécessaire

#### E. Vérifier le tracking domain

1. **Backend** → **Servers** → **Tracking domains**
2. Vérifier que `track.ulixai-expat.com` est configuré en HTTPS

---

## Phase 7 : Configuration Nginx

### 7.1 - Créer le vhost

```bash
nano /etc/nginx/conf.d/mailwizz.conf
```

```nginx
server {
    listen 80;
    server_name app.mail-ulixai.com;
    root /var/www/mailwizz;
    index index.php index.html;

    # Logs
    access_log /var/log/nginx/mailwizz_access.log;
    error_log /var/log/nginx/mailwizz_error.log;

    # Taille max upload
    client_max_body_size 50M;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_read_timeout 300;
    }

    location ~ /\. {
        deny all;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires max;
        log_not_found off;
    }
}
```

### 7.2 - Tester et recharger Nginx

```bash
nginx -t
systemctl reload nginx
```

### 7.3 - Installer SSL avec Let's Encrypt

```bash
dnf install certbot python3-certbot-nginx -y

# SSL pour l'application MailWizz
certbot --nginx -d app.mail-ulixai.com

# SSL pour le tracking domain (IMPORTANT pour les liens dans les emails)
certbot --nginx -d track.ulixai-expat.com
```

### 7.4 - Créer vhost pour le tracking domain

```bash
nano /etc/nginx/conf.d/tracking.conf
```

```nginx
server {
    listen 80;
    server_name track.ulixai-expat.com;
    root /var/www/mailwizz;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

```bash
nginx -t && systemctl reload nginx
certbot --nginx -d track.ulixai-expat.com
```

### 7.5 - Renouvellement automatique SSL

```bash
echo "0 3 * * * certbot renew --quiet" | crontab -
```

---

## Phase 8 : Configuration DNS

### Chez ton registrar (domaine ulixai-expat.com)

#### Enregistrements A

```dns
mailul.ulixai-expat.com.    IN A    [NOUVELLE_IP_1]
mailsos.ulixai-expat.com.   IN A    [NOUVELLE_IP_2]
app.mail-ulixai.com.        IN A    [NOUVELLE_IP_1]
track.ulixai-expat.com.     IN A    [NOUVELLE_IP_1]
```

#### Enregistrement SPF

```dns
ulixai-expat.com.           IN TXT  "v=spf1 ip4:[NOUVELLE_IP_1] ip4:[NOUVELLE_IP_2] -all"
```

#### Enregistrement DKIM

Sélecteur : `dkim`

```dns
dkim._domainkey.ulixai-expat.com.  IN TXT  "v=DKIM1; k=rsa; p=[CLE_PUBLIQUE_DKIM]"
```

**Pour générer la clé publique :**

```bash
openssl rsa -in /home/pmta/conf/mail/ulixai-expat.com/dkim.pem -pubout -out /tmp/dkim.public.key
cat /tmp/dkim.public.key
# Copier le contenu entre BEGIN et END (sans les tirets)
```

#### Enregistrement DMARC

```dns
_dmarc.ulixai-expat.com.    IN TXT  "v=DMARC1; p=quarantine; rua=mailto:dmarc@ulixai-expat.com; pct=100"
```

### Configuration Reverse DNS chez Hetzner

Dans le **Panel Cloud Hetzner** → Serveur → Networking → Reverse DNS :

| IP | Reverse DNS |
|----|-------------|
| IP_1 | mailul.ulixai-expat.com |
| IP_2 | mailsos.ulixai-expat.com |

---

## Phase 9 : Configuration Crons MailWizz

### 9.1 - Éditer le crontab

```bash
crontab -e
```

### 9.2 - Ajouter les tâches planifiées

```cron
# MailWizz - Envoi des campagnes (toutes les minutes)
* * * * * /usr/bin/php /var/www/mailwizz/apps/console/console.php send-campaigns >/dev/null 2>&1

# MailWizz - Traitement de la queue (toutes les minutes)
* * * * * /usr/bin/php /var/www/mailwizz/apps/console/console.php queue >/dev/null 2>&1

# MailWizz - Traitement des bounces (toutes les 5 minutes)
*/5 * * * * /usr/bin/php /var/www/mailwizz/apps/console/console.php process-bounce-handler >/dev/null 2>&1

# MailWizz - Traitement des feedback loops (toutes les 5 minutes)
*/5 * * * * /usr/bin/php /var/www/mailwizz/apps/console/console.php process-feedback-loop-handler >/dev/null 2>&1

# MailWizz - Tâches horaires
0 * * * * /usr/bin/php /var/www/mailwizz/apps/console/console.php hourly >/dev/null 2>&1

# MailWizz - Tâches quotidiennes
0 0 * * * /usr/bin/php /var/www/mailwizz/apps/console/console.php daily >/dev/null 2>&1

# MailWizz - Synchronisation des listes (toutes les 10 minutes)
*/10 * * * * /usr/bin/php /var/www/mailwizz/apps/console/console.php sync-lists-custom-fields >/dev/null 2>&1

# MailWizz - Nettoyage des logs de livraison (quotidien)
0 1 * * * /usr/bin/php /var/www/mailwizz/apps/console/console.php delete-campaign-delivery-logs >/dev/null 2>&1
```

---

## Phase 10 : Tests Finaux

### 10.1 - Vérifier PowerMTA

```bash
# Statut général
pmta show status

# Voir les queues
pmta show queues

# Voir les domaines
pmta show domains

# Test d'envoi
echo "Test email" | pmta inject --from=test@ulixai-expat.com --to=ton-email@gmail.com
```

### 10.2 - Accès MailWizz

1. Ouvrir : https://app.mail-ulixai.com/backend
2. Login : admin@mail-ulixai.com
3. Mot de passe : (celui dans la base de données)

### 10.3 - Vérifier la délivrabilité

| Test | Outil |
|------|-------|
| Score global | https://www.mail-tester.com |
| SPF | https://mxtoolbox.com/spf.aspx |
| DKIM | https://mxtoolbox.com/dkim.aspx |
| DMARC | https://mxtoolbox.com/dmarc.aspx |
| Blacklists | https://mxtoolbox.com/blacklists.aspx |

### 10.4 - Test email complet

1. Depuis MailWizz, envoyer un email vers Gmail
2. Dans Gmail, cliquer sur "Afficher l'original"
3. Vérifier :
   - `SPF: PASS`
   - `DKIM: PASS`
   - `DMARC: PASS`

---

## Checklist Récapitulative

### Achat Hetzner
- [ ] Compte Hetzner créé
- [ ] VPS CX21 commandé (Rocky Linux 9)
- [ ] 1 IP supplémentaire commandée
- [ ] Ticket déblocage port 25 envoyé
- [ ] Port 25 débloqué (confirmation reçue)

### Installation Serveur
- [ ] Système mis à jour
- [ ] MariaDB installé et sécurisé
- [ ] Nginx + PHP-FPM installés
- [ ] Firewall configuré

### Installation PowerMTA
- [ ] PowerMTA installé (rpm)
- [ ] Licence copiée
- [ ] Dossiers créés (/var/log/pmta, /var/spool/pmta)
- [ ] Clé DKIM copiée
- [ ] IPs remplacées dans config
- [ ] Mot de passe SMTP changé
- [ ] PowerMTA démarré et fonctionnel

### Installation MailWizz
- [ ] MailWizz déployé
- [ ] Base de données créée
- [ ] Base de données importée
- [ ] Configuration BDD mise à jour
- [ ] Permissions des dossiers OK
- [ ] Nginx configuré
- [ ] SSL installé (app.mail-ulixai.com)
- [ ] SSL installé (track.ulixai-expat.com)

### Configuration MailWizz (Interface Web)
- [ ] Serveurs d'envoi activés (status: active)
- [ ] Mot de passe SMTP mis à jour dans MailWizz
- [ ] URLs système vérifiées
- [ ] Domaine d'envoi vérifié
- [ ] Tracking domain vérifié (HTTPS)

### Configuration DNS
- [ ] Enregistrements A créés
- [ ] SPF mis à jour avec nouvelles IPs
- [ ] DKIM publié
- [ ] DMARC ajouté
- [ ] Reverse DNS configuré (Hetzner)

### Crons et Tests
- [ ] Crons MailWizz configurés
- [ ] PowerMTA status OK
- [ ] MailWizz accessible
- [ ] Email test envoyé
- [ ] SPF validé (PASS)
- [ ] DKIM validé (PASS)
- [ ] DMARC validé (PASS)

---

## Améliorations à faire après migration

### Sécurité (Priorité haute)

| Problème | Action |
|----------|--------|
| Mot de passe SMTP | ✅ Fait pendant migration |
| Auth SMTP non chiffrée | Activer TLS obligatoire dans config PMTA |
| Accès HTTP PMTA ouvert | Restreindre aux IPs admin uniquement |

### Délivrabilité (Priorité moyenne)

| Action | Détail |
|--------|--------|
| Clé publique DKIM | Générer et publier dans DNS |
| Warmup IPs | Suivre le plan 30 jours déjà configuré |
| Monitoring blacklists | Configurer alertes MXToolbox |

### Configuration PMTA pour TLS

Ajouter dans `/etc/pmta/config` :

```
<source {pmta-auth}>
    smtp-service yes
    always-allow-relaying yes
    require-auth true
    require-starttls yes              # AJOUTER
    allow-unencrypted-plain-auth no   # MODIFIER
    process-x-virtual-mta yes
    default-virtual-mta pmta-pool
</source>
```

### Restreindre l'accès HTTP PMTA

Modifier dans `/etc/pmta/config` :

```
# AVANT
http-access 0/0 monitor

# APRÈS (remplacer par ton IP admin)
http-access 127.0.0.1 admin
http-access [TON_IP_ADMIN] admin
```

---

## Informations de référence

### Anciennes IPs (Contabo)

| Usage | IP |
|-------|-----|
| VMTA 0 | 178.18.243.7 |
| VMTA 1 | 84.247.168.78 |

### Hostnames

| Hostname | Usage |
|----------|-------|
| mailul.ulixai-expat.com | VMTA 0 |
| mailsos.ulixai-expat.com | VMTA 1 |
| app.mail-ulixai.com | Interface MailWizz |
| track.ulixai-expat.com | Tracking |

### Ports utilisés

| Port | Service |
|------|---------|
| 22 | SSH |
| 25 | SMTP sortant |
| 80 | HTTP |
| 443 | HTTPS |
| 2525 | SMTP PowerMTA (réception MailWizz) |
| 1983 | Interface web PowerMTA |

### Credentials (à mettre à jour)

| Service | Utilisateur | Mot de passe |
|---------|-------------|--------------|
| SSH | root | [À DÉFINIR] |
| MariaDB | root | [À DÉFINIR] |
| MariaDB | mailapp | [À DÉFINIR] |
| PMTA SMTP | admin@ulixai-expat.com | [À DÉFINIR] |
| MailWizz Admin | admin@mail-ulixai.com | [EXISTANT EN BDD] |

---

## Support

### Liens utiles

- Hetzner Cloud Console : https://console.hetzner.cloud
- Documentation PowerMTA : `/usr/share/doc/pmta/UsersGuide.html`
- Documentation MailWizz : https://www.mailwizz.com/kb/

### En cas de problème

1. **PowerMTA ne démarre pas** : `journalctl -u pmta -f`
2. **Emails non délivrés** : `pmta show queues` et `/var/log/pmta/log`
3. **MailWizz erreur 500** : `/var/log/nginx/mailwizz_error.log`
4. **Base de données** : `mysql -u root -p mailapp`

---

*Document généré le 4 février 2026*
