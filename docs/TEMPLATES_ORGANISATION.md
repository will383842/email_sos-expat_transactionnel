# Organisation des Templates Emails SOS-Expat

**Date** : 4 février 2026
**Total templates** : 106 (version française)
**Langues prévues** : 9 (FR + 8 traductions)

---

## Nomenclature Actuelle (Analysée)

### Structure du nom de fichier

```
[TYPE]_[CIBLE]_[CATEGORIE]_[SEQUENCE]_[LANGUE].html
```

| Élément | Valeurs | Description |
|---------|---------|-------------|
| **TYPE** | `TR`, `CA`, `NL` | Type d'email |
| **CIBLE** | `CLI`, `PRO` | Destinataire |
| **CATEGORIE** | `welcome`, `payment-*`, etc. | Catégorie fonctionnelle |
| **SEQUENCE** | `01`, `02`, `03`, `04` | Numéro dans la séquence (si applicable) |
| **LANGUE** | `FR`, `EN`, `DE`, etc. | Code langue ISO |

### Types d'emails

| Code | Type | Description | Quantité |
|------|------|-------------|----------|
| `TR_` | Transactional | Emails déclenchés par une action | 54 |
| `CA_` | Campaign | Séquences automatisées (nurturing) | 46 |
| `NL_` | Newsletter | Communications ponctuelles | 6 |

### Cibles

| Code | Cible | Description |
|------|-------|-------------|
| `CLI_` | Client | Utilisateurs qui cherchent de l'aide |
| `PRO_` | Provider | Experts/Prestataires |

---

## Inventaire Complet des Templates

### Transactional Client (TR_CLI_) - 16 templates

| Fichier | Catégorie | Description |
|---------|-----------|-------------|
| `TR_CLI_welcome_FR.html` | Onboarding | Email de bienvenue client |
| `TR_CLI_anniversary_FR.html` | Engagement | Anniversaire d'inscription |
| `TR_CLI_call-cancelled_FR.html` | Appel | Appel annulé |
| `TR_CLI_call-completed_FR.html` | Appel | Appel terminé avec succès |
| `TR_CLI_call-missed_FR.html` | Appel | Appel manqué |
| `TR_CLI_expert-found_FR.html` | Matching | Expert trouvé |
| `TR_CLI_expert-no-answer_FR.html` | Matching | Expert ne répond pas |
| `TR_CLI_payment-failed_FR.html` | Paiement | Échec de paiement |
| `TR_CLI_payment-refunded_FR.html` | Paiement | Remboursement effectué |
| `TR_CLI_payment-success_FR.html` | Paiement | Paiement réussi |
| `TR_CLI_request-sent_FR.html` | Demande | Demande envoyée |
| `TR_CLI_thank-you-review_FR.html` | Avis | Remerciement pour avis |
| `TR_CLI_trustpilot-invite_FR.html` | Avis | Invitation Trustpilot |
| `TR_CLI_vip_FR.html` | Fidélité | Passage au statut VIP |

### Transactional Provider (TR_PRO_) - 38 templates

| Fichier | Catégorie | Description |
|---------|-----------|-------------|
| `TR_PRO_welcome_FR.html` | Onboarding | Email de bienvenue expert |
| `TR_PRO_account-blocked_FR.html` | Compte | Compte bloqué |
| `TR_PRO_account-reactivated_FR.html` | Compte | Compte réactivé |
| `TR_PRO_anniversary_FR.html` | Engagement | Anniversaire |
| `TR_PRO_back-online_FR.html` | Statut | Retour en ligne |
| `TR_PRO_badge-unlocked_FR.html` | Gamification | Badge débloqué |
| `TR_PRO_bad-review-received_FR.html` | Avis | Mauvais avis reçu |
| `TR_PRO_call-completed_FR.html` | Appel | Appel terminé |
| `TR_PRO_call-missed_01_FR.html` | Appel | Appel manqué (1er rappel) |
| `TR_PRO_call-missed_02_FR.html` | Appel | Appel manqué (2ème rappel) |
| `TR_PRO_call-missed_03_FR.html` | Appel | Appel manqué (3ème rappel) |
| `TR_PRO_call-missed_04_FR.html` | Appel | Appel manqué (dernier rappel) |
| `TR_PRO_earning-credited_FR.html` | Gains | Gain crédité |
| `TR_PRO_first-earning_FR.html` | Gains | Premier gain |
| `TR_PRO_first-online_FR.html` | Statut | Première mise en ligne |
| `TR_PRO_good-review-received_FR.html` | Avis | Bon avis reçu |
| `TR_PRO_kyc-documents-received_FR.html` | KYC | Documents reçus |
| `TR_PRO_kyc-info-missing_FR.html` | KYC | Informations manquantes |
| `TR_PRO_kyc-rejected_FR.html` | KYC | KYC rejeté |
| `TR_PRO_kyc-request_FR.html` | KYC | Demande de KYC |
| `TR_PRO_kyc-verified_FR.html` | KYC | KYC vérifié |
| `TR_PRO_milestone_FR.html` | Gamification | Palier atteint |
| `TR_PRO_monthly-stats_FR.html` | Stats | Statistiques mensuelles |
| `TR_PRO_negative-review_FR.html` | Avis | Avis négatif |
| `TR_PRO_neutral-review-received_FR.html` | Avis | Avis neutre reçu |
| `TR_PRO_new-request_FR.html` | Demande | Nouvelle demande |
| `TR_PRO_new-review_FR.html` | Avis | Nouvel avis |
| `TR_PRO_payout-failed_FR.html` | Paiement | Échec de versement |
| `TR_PRO_payout-requested_FR.html` | Paiement | Demande de versement |
| `TR_PRO_payout-sent_FR.html` | Paiement | Versement envoyé |
| `TR_PRO_payout-threshold-reached_FR.html` | Paiement | Seuil de versement atteint |
| `TR_PRO_paypal-confirmed_FR.html` | PayPal | PayPal confirmé |
| `TR_PRO_paypal-request_FR.html` | PayPal | Demande PayPal |
| `TR_PRO_profile-completed_FR.html` | Profil | Profil complété |
| `TR_PRO_referral-bonus_FR.html` | Parrainage | Bonus parrainage |
| `TR_PRO_trustpilot-invite_FR.html` | Avis | Invitation Trustpilot |
| `TR_PRO_weekly-stats_FR.html` | Stats | Statistiques hebdomadaires |

### Campaign Client (CA_CLI_) - 17 templates

| Fichier | Séquence | Description |
|---------|----------|-------------|
| `CA_CLI_nurture-action_01_FR.html` | Action 1/4 | Nurturing action client |
| `CA_CLI_nurture-action_02_FR.html` | Action 2/4 | |
| `CA_CLI_nurture-action_03_FR.html` | Action 3/4 | |
| `CA_CLI_nurture-action_04_FR.html` | Action 4/4 | |
| `CA_CLI_nurture-inactive_01_FR.html` | Inactif 1/5 | Réactivation client inactif |
| `CA_CLI_nurture-inactive_02_FR.html` | Inactif 2/5 | |
| `CA_CLI_nurture-inactive_03_FR.html` | Inactif 3/5 | |
| `CA_CLI_nurture-inactive_04_FR.html` | Inactif 4/5 | |
| `CA_CLI_nurture-inactive_05_FR.html` | Inactif 5/5 | |
| `CA_CLI_nurture-login_01_FR.html` | Login 1/4 | Nurturing post-connexion |
| `CA_CLI_nurture-login_02_FR.html` | Login 2/4 | |
| `CA_CLI_nurture-login_03_FR.html` | Login 3/4 | |
| `CA_CLI_nurture-login_04_FR.html` | Login 4/4 | |
| `CA_CLI_request-review_01_FR.html` | Review 1/4 | Demande d'avis |
| `CA_CLI_request-review_02_FR.html` | Review 2/4 | |
| `CA_CLI_request-review_03_FR.html` | Review 3/4 | |
| `CA_CLI_request-review_04_FR.html` | Review 4/4 | |

### Campaign Provider (CA_PRO_) - 29 templates

| Fichier | Séquence | Description |
|---------|----------|-------------|
| `CA_PRO_motivation_01_FR.html` | Motivation | Email de motivation |
| `CA_PRO_nurture-inactive-p_01_FR.html` | Inactif 1/3 | Réactivation expert inactif |
| `CA_PRO_nurture-inactive-p_02_FR.html` | Inactif 2/3 | |
| `CA_PRO_nurture-inactive-p_03_FR.html` | Inactif 3/3 | |
| `CA_PRO_nurture-kyc_01_FR.html` | KYC 1/4 | Nurturing KYC |
| `CA_PRO_nurture-kyc_02_FR.html` | KYC 2/4 | |
| `CA_PRO_nurture-kyc_03_FR.html` | KYC 3/4 | |
| `CA_PRO_nurture-kyc_04_FR.html` | KYC 4/4 | |
| `CA_PRO_nurture-login_01_FR.html` | Login 1/4 | Nurturing post-connexion |
| `CA_PRO_nurture-login_02_FR.html` | Login 2/4 | |
| `CA_PRO_nurture-login_03_FR.html` | Login 3/4 | |
| `CA_PRO_nurture-login_04_FR.html` | Login 4/4 | |
| `CA_PRO_nurture-no-calls_01_FR.html` | No-calls 1/3 | Nurturing sans appels |
| `CA_PRO_nurture-no-calls_02_FR.html` | No-calls 2/3 | |
| `CA_PRO_nurture-no-calls_03_FR.html` | No-calls 3/3 | |
| `CA_PRO_nurture-offline_01_FR.html` | Offline 1/5 | Nurturing hors ligne |
| `CA_PRO_nurture-offline_02_FR.html` | Offline 2/5 | |
| `CA_PRO_nurture-offline_03_FR.html` | Offline 3/5 | |
| `CA_PRO_nurture-offline_04_FR.html` | Offline 4/5 | |
| `CA_PRO_nurture-offline_05_FR.html` | Offline 5/5 | |
| `CA_PRO_nurture-paypal_01_FR.html` | PayPal 1/3 | Nurturing PayPal |
| `CA_PRO_nurture-paypal_02_FR.html` | PayPal 2/3 | |
| `CA_PRO_nurture-paypal_03_FR.html` | PayPal 3/3 | |
| `CA_PRO_nurture-profile_01_FR.html` | Profil 1/4 | Nurturing profil |
| `CA_PRO_nurture-profile_02_FR.html` | Profil 2/4 | |
| `CA_PRO_nurture-profile_03_FR.html` | Profil 3/4 | |
| `CA_PRO_nurture-profile_04_FR.html` | Profil 4/4 | |
| `CA_PRO_referral_01_FR.html` | Referral | Programme parrainage |
| `CA_PRO_reminder-online_01_FR.html` | Online 1/2 | Rappel mise en ligne |
| `CA_PRO_reminder-online_02_FR.html` | Online 2/2 | |
| `CA_PRO_tips_01_FR.html` | Tips 1/2 | Conseils expert |
| `CA_PRO_tips_02_FR.html` | Tips 2/2 | |

### Newsletter (NL_) - 6 templates

| Fichier | Type | Description |
|---------|------|-------------|
| `NL_blog-article_FR.html` | Contenu | Nouvel article de blog |
| `NL_holiday_FR.html` | Événement | Email de fêtes |
| `NL_monthly-recap_FR.html` | Récap | Récapitulatif mensuel |
| `NL_new-feature_FR.html` | Produit | Nouvelle fonctionnalité |
| `NL_promo_FR.html` | Marketing | Promotion |
| `NL_survey_FR.html` | Feedback | Sondage |

---

## Structure de Dossiers Scalable (9 langues)

### Organisation recommandée

```
templates/
├── transactional/
│   ├── client/
│   │   ├── fr/
│   │   │   ├── welcome.html
│   │   │   ├── call-completed.html
│   │   │   ├── payment-success.html
│   │   │   └── ...
│   │   ├── en/
│   │   ├── de/
│   │   ├── es/
│   │   ├── pt/
│   │   ├── ru/
│   │   ├── zh/
│   │   ├── ar/
│   │   └── hi/
│   └── provider/
│       ├── fr/
│       ├── en/
│       └── ...
├── campaign/
│   ├── client/
│   │   ├── fr/
│   │   │   ├── nurture-action/
│   │   │   │   ├── 01.html
│   │   │   │   ├── 02.html
│   │   │   │   ├── 03.html
│   │   │   │   └── 04.html
│   │   │   ├── nurture-inactive/
│   │   │   ├── nurture-login/
│   │   │   └── request-review/
│   │   ├── en/
│   │   └── ...
│   └── provider/
│       ├── fr/
│       │   ├── nurture-kyc/
│       │   ├── nurture-profile/
│       │   └── ...
│       └── ...
└── newsletter/
    ├── fr/
    │   ├── blog-article.html
    │   ├── holiday.html
    │   └── ...
    ├── en/
    └── ...
```

### Codes langues ISO 639-1

| Code | Langue | Priorité |
|------|--------|----------|
| `fr` | Français | 1 (source) |
| `en` | Anglais | 2 |
| `de` | Allemand | 3 |
| `es` | Espagnol | 4 |
| `pt` | Portugais | 5 |
| `ru` | Russe | 6 |
| `zh` | Chinois | 7 |
| `ar` | Arabe | 8 |
| `hi` | Hindi | 9 |

---

## Fichier de Mapping (pour l'import)

### templates_mapping.json

```json
{
  "version": "1.0",
  "source_language": "fr",
  "templates": {
    "TR_CLI_welcome": {
      "type": "transactional",
      "target": "client",
      "category": "onboarding",
      "subject": {
        "fr": "Bienvenue sur SOS-Expat !",
        "en": "Welcome to SOS-Expat!",
        "de": "Willkommen bei SOS-Expat!",
        "es": "¡Bienvenido a SOS-Expat!",
        "pt": "Bem-vindo ao SOS-Expat!",
        "ru": "Добро пожаловать в SOS-Expat!",
        "zh": "欢迎来到SOS-Expat!",
        "ar": "!SOS-Expat مرحباً بك في",
        "hi": "SOS-Expat में आपका स्वागत है!"
      },
      "trigger": "user.registered",
      "delay": "0",
      "files": {
        "fr": "transactional/client/fr/welcome.html",
        "en": "transactional/client/en/welcome.html"
      }
    }
  }
}
```

---

## Prochaines Étapes

### Phase 1 : Réorganisation (à faire maintenant)
1. [ ] Créer la structure de dossiers
2. [ ] Renommer et déplacer les fichiers FR
3. [ ] Créer le fichier de mapping JSON
4. [ ] Valider la structure

### Phase 2 : Traduction (à faire ensuite)
1. [ ] Exporter les textes à traduire
2. [ ] Traduire en 8 langues
3. [ ] Créer les fichiers HTML par langue
4. [ ] Valider les traductions

### Phase 3 : Import dans MailWizz
1. [ ] Importer les templates transactionnels
2. [ ] Créer les campagnes automatisées
3. [ ] Configurer les triggers
4. [ ] Tester les envois

---

## Script de Réorganisation

```bash
#!/bin/bash
# Script pour réorganiser les templates

SRC="Template france sos expat"
DEST="templates"

# Créer la structure
mkdir -p $DEST/{transactional,campaign,newsletter}/{client,provider}/{fr,en,de,es,pt,ru,zh,ar,hi}
mkdir -p $DEST/campaign/client/fr/{nurture-action,nurture-inactive,nurture-login,request-review}
mkdir -p $DEST/campaign/provider/fr/{nurture-kyc,nurture-profile,nurture-login,nurture-offline,nurture-paypal,nurture-no-calls,reminder-online,tips}

# Déplacer les templates transactionnels client
for f in $SRC/TR_CLI_*_FR.html; do
  name=$(basename "$f" | sed 's/TR_CLI_//' | sed 's/_FR.html/.html/')
  cp "$f" "$DEST/transactional/client/fr/$name"
done

# Déplacer les templates transactionnels provider
for f in $SRC/TR_PRO_*_FR.html; do
  name=$(basename "$f" | sed 's/TR_PRO_//' | sed 's/_FR.html/.html/')
  cp "$f" "$DEST/transactional/provider/fr/$name"
done

# Déplacer les newsletters
for f in $SRC/NL_*_FR.html; do
  name=$(basename "$f" | sed 's/NL_//' | sed 's/_FR.html/.html/')
  cp "$f" "$DEST/newsletter/fr/$name"
done

echo "Réorganisation terminée!"
```

---

*Document généré le 4 février 2026*
