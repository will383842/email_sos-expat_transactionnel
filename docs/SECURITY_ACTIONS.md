# ACTIONS DE SECURITE - A EFFECTUER AVANT DEPLOIEMENT

**Date de creation:** 4 fevrier 2026
**Statut:** EN COURS

---

## 1. CLES DKIM - MISE A JOUR EFFECTUEE

### mail-ulixai.com - NOUVELLE CLE 2048-BIT GENEREE

Les anciennes cles 1024-bit ont ete renommees en `*-1024-DEPRECATED.*` et de nouvelles cles 2048-bit ont ete generees.

**Fichiers mis a jour:**
- `backup-cold/pmta-dkim/mail/mail-ulixai.com/dkim.pem` (2048-bit)
- `backup-cold/pmta-dkim/mail/mail-ulixai.com/dkim.public.key` (2048-bit)
- `backup-cold/pmta-dkim/conf/mail/mail-ulixai.com/dkim.pem` (2048-bit)
- `backup-cold/pmta-dkim/conf/mail/mail-ulixai.com/dkim.public.key` (2048-bit)

### ACTION REQUISE: Mettre a jour le DNS

Ajouter/mettre a jour l'enregistrement TXT DNS suivant pour `mail-ulixai.com`:

```
Nom:     dkim._domainkey.mail-ulixai.com
Type:    TXT
TTL:     3600
Valeur:  v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAjYKZVW/VF4fY5FVXSlGyuVXUrk3zEbDn5u4VwyjMkfLZhW3paT7urnR7kmF3qs5/vBmP5+Bef9bgsviW8eY0UWIERI4pxmnvgWo4MrmmKY5LWe83q9xAVp22pVsMX+V4ghvdLLM1I5zDVhCWq3qZsNv6Th5ll8lK/7aSu6LGc8ekdubNFSTxQgOOCqBLBFXYkXsI9t/7dMgVUIAt2ekjintnE04sOjgWrsx/01/UIaTaE/kOK3s6sP0obGLHRUbJZjFaJhM8U6owVLtOoHAIse5aDc1KOizk6fLf4mgipgShBeozLrDbU9Ssc5DxFaeZUT7fhGJZVHS/wdy/3X+JYwIDAQAB
```

**Verification apres mise a jour DNS:**
```bash
# Tester l'enregistrement DKIM
dig dkim._domainkey.mail-ulixai.com TXT +short

# Ou utiliser un outil en ligne:
# https://mxtoolbox.com/dkim.aspx
```

---

## 2. SECRETS FIREBASE - A CONFIGURER

### GA4 API Secret

Le code a ete mis a jour pour utiliser Firebase Secret Manager au lieu d'un placeholder hardcode.

**ACTION REQUISE:**

```bash
# 1. Recuperer votre GA4 API Secret depuis Google Analytics:
#    - GA4 > Admin > Data Streams > [votre stream] > Measurement Protocol API secrets

# 2. Configurer le secret dans Firebase:
firebase functions:secrets:set GA4_API_SECRET

# Entrer la valeur du secret quand demande
```

**Fichiers modifies:**
- `sos/firebase/functions/src/emailMarketing/config.ts` - Ajout de GA4_API_SECRET
- `sos/firebase/functions/src/emailMarketing/utils/analytics.ts` - Utilisation du secret

---

## 3. PERMISSIONS FICHIERS - A APPLIQUER SUR SERVEUR HETZNER

### Apres deploiement sur le serveur, executer:

```bash
# Cles privees DKIM - Lecture seule par root
chmod 600 /home/pmta/conf/mail/*/dkim.pem
chown root:root /home/pmta/conf/mail/*/dkim.pem

# Configuration PowerMTA - Lecture seule par root
chmod 600 /etc/pmta/config
chown root:root /etc/pmta/config

# Fichiers SQL de backup - Supprimer apres import ou chiffrer
# NE PAS laisser les fichiers SQL en clair sur le serveur!
rm /root/mailapp-reference.sql
# OU chiffrer:
gpg -c /root/mailapp-reference.sql && rm /root/mailapp-reference.sql
```

---

## 4. CONFIGURATION POWERMTA - VERIFICATIONS

### Fichier: backup-cold/pmta-etc/config

**Verifier que ces parametres sont actifs:**
```
allow-unencrypted-plain-auth no    # DOIT etre "no"
require-starttls yes               # DOIT etre "yes"
http-access 127.0.0.1 admin       # DOIT etre localhost seulement
```

**A REMPLACER apres achat Hetzner (IPs anciennes Contabo):**
```
# Anciennes IPs a remplacer:
178.18.243.7   ->  [NOUVELLE_IP_HETZNER_1]
84.247.168.78  ->  [NOUVELLE_IP_HETZNER_2]
```

---

## 5. CLES API MAILWIZZ - A REGENERER

Les cles API suivantes sont exposees dans le dump SQL et doivent etre regenerees:

**ACTION REQUISE dans MailWizz Admin:**

1. Se connecter a `https://app.mail-ulixai.com`
2. Aller dans Settings > API Keys
3. Revoquer la cle existante: `63f17459fa45961cbb742a61ddebc157169bd3c1`
4. Generer une nouvelle cle API
5. Mettre a jour le secret Firebase:
   ```bash
   firebase functions:secrets:set MAILWIZZ_API_KEY
   ```

---

## 6. CHECKLIST DE VERIFICATION

### Avant deploiement:

- [ ] DNS DKIM mis a jour pour mail-ulixai.com
- [ ] GA4_API_SECRET configure dans Firebase
- [ ] Nouvelles IPs Hetzner configurees dans pmta config
- [ ] Cle API MailWizz regeneree

### Apres deploiement sur serveur:

- [ ] Permissions 600 sur cles DKIM
- [ ] Permissions 600 sur config PMTA
- [ ] Fichiers SQL supprimes ou chiffres
- [ ] Test envoi email avec nouvelle cle DKIM
- [ ] Verification SPF, DKIM, DMARC avec mail-tester.com

---

## 7. ANCIENNES CLES - A SUPPRIMER APRES VALIDATION

Une fois la nouvelle cle DKIM validee en production, supprimer les fichiers deprecies:

```bash
rm backup-cold/pmta-dkim/mail/mail-ulixai.com/dkim-1024-DEPRECATED.*
rm backup-cold/pmta-dkim/conf/mail/mail-ulixai.com/dkim-1024-DEPRECATED.*
```

---

---

## 8. DEPLOIEMENT HETZNER - SCRIPTS PREPARES

### Fichiers crees pour le deploiement:

| Fichier | Description |
|---------|-------------|
| `backup-cold/pmta-etc/config.hetzner.template` | Template config PMTA avec placeholders |
| `scripts/deploy-hetzner.sh` | Script d'installation automatique |
| `scripts/prepare-upload.ps1` | Script pour preparer les fichiers a uploader |

### Utilisation:

```powershell
# 1. Preparer les fichiers (Windows PowerShell)
cd "Outils d'emailing"
.\scripts\prepare-upload.ps1

# 2. Uploader sur le serveur Hetzner
scp -r "upload-package\*" root@VOTRE_IP:/root/

# 3. Sur le serveur, editer et executer
ssh root@VOTRE_IP
nano deploy-hetzner.sh  # Configurer les IPs et mots de passe
chmod +x deploy-hetzner.sh
./deploy-hetzner.sh
```

### Variables a configurer dans deploy-hetzner.sh:

```bash
HETZNER_IP_1="x.x.x.x"           # Premiere IP Hetzner
HETZNER_IP_2="y.y.y.y"           # Deuxieme IP Hetzner
SMTP_PASSWORD="nouveau_mdp"       # Mot de passe SMTP fort
DB_PASS="nouveau_mdp_db"          # Mot de passe MariaDB
```

---

## HISTORIQUE DES MODIFICATIONS

| Date | Action | Statut |
|------|--------|--------|
| 2026-02-04 | Generation cle DKIM 2048-bit mail-ulixai.com | FAIT |
| 2026-02-04 | Migration GA4 secret vers Firebase Secret Manager | FAIT |
| 2026-02-04 | Creation documentation securite | FAIT |
| 2026-02-04 | Creation template config Hetzner | FAIT |
| 2026-02-04 | Creation script deploiement automatique | FAIT |
| 2026-02-04 | Creation script preparation upload | FAIT |
| 2026-02-04 | Configuration GA4_API_SECRET Firebase | FAIT |
| - | Configuration DNS DKIM | A FAIRE |
| - | Regeneration cle API MailWizz | A FAIRE |
| - | Achat serveur Hetzner | A FAIRE |
| - | Deploiement sur Hetzner | A FAIRE |
