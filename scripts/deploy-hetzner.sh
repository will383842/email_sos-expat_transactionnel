#!/bin/bash
################################################################################
# SCRIPT DE DEPLOIEMENT HETZNER - SOS EXPAT EMAIL SYSTEM
#
# Ce script automatise l'installation de PowerMTA et MailWizz sur Hetzner
#
# PREREQUIS:
# 1. Serveur Hetzner avec Rocky Linux 9 ou AlmaLinux 9
# 2. Port 25 debloque (ticket support Hetzner)
# 3. 2 IPs configurees
#
# USAGE:
# 1. Editer les variables ci-dessous
# 2. Transferer ce script et les fichiers sur le serveur
# 3. Executer: chmod +x deploy-hetzner.sh && ./deploy-hetzner.sh
################################################################################

set -e  # Exit on error

# =============================================================================
# CONFIGURATION - A MODIFIER AVANT EXECUTION
# =============================================================================

# IPs Hetzner (a remplacer par vos IPs reelles)
HETZNER_IP_1="YOUR_FIRST_IP_HERE"
HETZNER_IP_2="YOUR_SECOND_IP_HERE"

# Nouveau mot de passe SMTP (generer un mot de passe fort!)
SMTP_PASSWORD="CHANGE_THIS_TO_A_STRONG_PASSWORD"

# Chemins des fichiers uploades
PMTA_ZIP="/root/rpm-install-pmta-5.zip"
MAILWIZZ_ZIP="/root/mailwizz.zip"
SQL_DUMP="/root/mailapp-reference.sql"
CONFIG_TEMPLATE="/root/config.hetzner.template"

# Base de donnees MailWizz
DB_NAME="mailapp"
DB_USER="mailapp"
DB_PASS="CHANGE_THIS_DB_PASSWORD"

# Domaines
DOMAIN_MAILWIZZ="app.mail-ulixai.com"
DOMAIN_TRACK="track.ulixai-expat.com"

# =============================================================================
# VERIFICATION DES PREREQUIS
# =============================================================================

echo "=========================================="
echo "  DEPLOIEMENT SOS EXPAT EMAIL SYSTEM"
echo "=========================================="
echo ""

# Verifier que les IPs sont configurees
if [[ "$HETZNER_IP_1" == "YOUR_FIRST_IP_HERE" ]]; then
    echo "ERREUR: Configurez HETZNER_IP_1 dans ce script!"
    exit 1
fi

if [[ "$SMTP_PASSWORD" == "CHANGE_THIS_TO_A_STRONG_PASSWORD" ]]; then
    echo "ERREUR: Configurez SMTP_PASSWORD dans ce script!"
    exit 1
fi

# Verifier les fichiers requis
for file in "$PMTA_ZIP" "$MAILWIZZ_ZIP" "$SQL_DUMP" "$CONFIG_TEMPLATE"; do
    if [[ ! -f "$file" ]]; then
        echo "ERREUR: Fichier manquant: $file"
        exit 1
    fi
done

echo "[OK] Tous les fichiers requis sont presents"

# =============================================================================
# PHASE 1: MISE A JOUR SYSTEME ET PACKAGES
# =============================================================================

echo ""
echo "[PHASE 1] Installation des packages systeme..."

dnf update -y
dnf install -y epel-release
dnf install -y \
    nginx \
    mariadb-server \
    php-fpm \
    php-mysqlnd \
    php-gd \
    php-mbstring \
    php-xml \
    php-curl \
    php-zip \
    php-intl \
    php-bcmath \
    php-imap \
    unzip \
    wget \
    certbot \
    python3-certbot-nginx \
    firewalld

echo "[OK] Packages installes"

# =============================================================================
# PHASE 2: CONFIGURATION FIREWALL
# =============================================================================

echo ""
echo "[PHASE 2] Configuration du firewall..."

systemctl enable firewalld
systemctl start firewalld

firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-port=25/tcp
firewall-cmd --permanent --add-port=2525/tcp
firewall-cmd --permanent --add-port=1983/tcp
firewall-cmd --reload

echo "[OK] Firewall configure"

# =============================================================================
# PHASE 3: INSTALLATION POWERMTA
# =============================================================================

echo ""
echo "[PHASE 3] Installation de PowerMTA..."

cd /root
unzip -o "$PMTA_ZIP"
cd rpm-install-pmta-5-extracted/rpm-install-pmta-5 || cd rpm-install-pmta-5

# Installer PowerMTA
rpm -ivh PowerMTA-*.rpm || yum localinstall -y PowerMTA-*.rpm

# Creer les repertoires
mkdir -p /var/spool/pmta
mkdir -p /var/log/pmta
mkdir -p /home/pmta/conf/mail/ulixai-expat.com
mkdir -p /home/pmta/conf/mail/mail-ulixai.com
mkdir -p /etc/pmta

echo "[OK] PowerMTA installe"

# =============================================================================
# PHASE 4: CONFIGURATION POWERMTA
# =============================================================================

echo ""
echo "[PHASE 4] Configuration de PowerMTA..."

# Generer la config a partir du template
sed -e "s/{{HETZNER_IP_1}}/$HETZNER_IP_1/g" \
    -e "s/{{HETZNER_IP_2}}/$HETZNER_IP_2/g" \
    -e "s/{{SMTP_PASSWORD}}/$SMTP_PASSWORD/g" \
    "$CONFIG_TEMPLATE" > /etc/pmta/config

# Copier les fichiers supplementaires
cp /root/pmta-etc/bounce-classifications /etc/pmta/
cp /root/pmta-etc/license /etc/pmta/
cp /root/pmta-etc/routing-domains /etc/pmta/

# Copier les cles DKIM
cp /root/pmta-dkim/mail/ulixai-expat.com/dkim.pem /home/pmta/conf/mail/ulixai-expat.com/
cp /root/pmta-dkim/mail/mail-ulixai.com/dkim.pem /home/pmta/conf/mail/mail-ulixai.com/

# Securiser les permissions
chmod 600 /etc/pmta/config
chmod 600 /home/pmta/conf/mail/*/dkim.pem
chown -R root:root /etc/pmta
chown -R root:root /home/pmta

echo "[OK] PowerMTA configure"

# =============================================================================
# PHASE 5: CONFIGURATION MARIADB
# =============================================================================

echo ""
echo "[PHASE 5] Configuration de MariaDB..."

systemctl enable mariadb
systemctl start mariadb

# Securiser MariaDB
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -e "FLUSH PRIVILEGES;"

# Creer la base MailWizz
mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Importer le dump
mysql $DB_NAME < "$SQL_DUMP"

echo "[OK] MariaDB configure et donnees importees"

# =============================================================================
# PHASE 6: INSTALLATION MAILWIZZ
# =============================================================================

echo ""
echo "[PHASE 6] Installation de MailWizz..."

mkdir -p /var/www/mailwizz
cd /var/www/mailwizz
unzip -o "$MAILWIZZ_ZIP"

# Permissions
chown -R nginx:nginx /var/www/mailwizz
chmod -R 755 /var/www/mailwizz
chmod -R 775 /var/www/mailwizz/apps/common/runtime
chmod -R 775 /var/www/mailwizz/apps/common/config
chmod -R 775 /var/www/mailwizz/frontend/assets/cache
chmod -R 775 /var/www/mailwizz/backend/assets/cache
chmod -R 775 /var/www/mailwizz/customer/assets/cache

echo "[OK] MailWizz installe"

# =============================================================================
# PHASE 7: CONFIGURATION NGINX
# =============================================================================

echo ""
echo "[PHASE 7] Configuration de Nginx..."

cat > /etc/nginx/conf.d/mailwizz.conf << 'NGINX_CONF'
server {
    listen 80;
    server_name app.mail-ulixai.com track.ulixai-expat.com;
    root /var/www/mailwizz;
    index index.php;

    access_log /var/log/nginx/mailwizz_access.log;
    error_log /var/log/nginx/mailwizz_error.log;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\. {
        deny all;
    }
}
NGINX_CONF

# Configurer PHP-FPM
sed -i 's/user = apache/user = nginx/' /etc/php-fpm.d/www.conf
sed -i 's/group = apache/group = nginx/' /etc/php-fpm.d/www.conf

systemctl enable nginx php-fpm
systemctl restart php-fpm nginx

echo "[OK] Nginx configure"

# =============================================================================
# PHASE 8: DEMARRAGE DES SERVICES
# =============================================================================

echo ""
echo "[PHASE 8] Demarrage des services..."

systemctl enable pmta
systemctl start pmta

echo "[OK] Services demarres"

# =============================================================================
# PHASE 9: CERTIFICATS SSL (OPTIONNEL)
# =============================================================================

echo ""
echo "[PHASE 9] Configuration SSL..."
echo "Pour obtenir les certificats SSL, executez:"
echo "  certbot --nginx -d $DOMAIN_MAILWIZZ -d $DOMAIN_TRACK"
echo ""

# =============================================================================
# RESUME
# =============================================================================

echo "=========================================="
echo "  INSTALLATION TERMINEE!"
echo "=========================================="
echo ""
echo "Services installes:"
echo "  - PowerMTA: systemctl status pmta"
echo "  - MariaDB:  systemctl status mariadb"
echo "  - Nginx:    systemctl status nginx"
echo "  - PHP-FPM:  systemctl status php-fpm"
echo ""
echo "URLs:"
echo "  - MailWizz: http://$DOMAIN_MAILWIZZ"
echo "  - Tracking: http://$DOMAIN_TRACK"
echo ""
echo "SMTP:"
echo "  - Port: 2525"
echo "  - IP 1: $HETZNER_IP_1"
echo "  - IP 2: $HETZNER_IP_2"
echo "  - User: admin@ulixai-expat.com"
echo ""
echo "ACTIONS RESTANTES:"
echo "  1. Configurer DNS (A records, SPF, DKIM, DMARC)"
echo "  2. Obtenir certificats SSL: certbot --nginx"
echo "  3. Mettre a jour les delivery servers dans MailWizz"
echo "  4. Tester l'envoi d'emails"
echo ""
echo "=========================================="
