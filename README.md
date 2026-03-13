# Mail Server Config - 46.62.168.55

## Services
- **PMTA v5.0r8** - PowerMTA mail transfer agent (port 2525)
- **MailWizz** - Email marketing platform (mail.sos-expat.com)
- **Nginx** - Reverse proxy
- **MariaDB** - MailWizz database
- **Engine Telegram** - Docker (port 8080)
- **Engine Motivation** - Docker (port 8082)

## Domains
- ulixai-expat.com (PMTA sending domain)
- mail.sos-expat.com (MailWizz UI)

## IPs
- 46.62.168.55 (primary)
- 95.216.179.163 (secondary)

## DKIM
Keys in /home/pmta/conf/mail/ (NOT versioned - sensitive)

## Restore
1. Install PMTA, copy config from pmta/
2. Install MailWizz, restore DB from backup
3. Configure nginx from nginx/
4. Import crontab from cron/
