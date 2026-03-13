# ============================================================================
# GENERATEUR SQL POUR IMPORT TEMPLATES MAILWIZZ
# ============================================================================

$ErrorActionPreference = "Stop"

$TemplatesPath = "C:\Users\willi\Documents\Projets\VS_CODE\email_sos-expat_transactionnel\templates"
$OutputFile = "C:\Users\willi\Documents\Projets\VS_CODE\email_sos-expat_transactionnel\backup-cold\templates-import.sql"

# Customer ID (admin MailWizz - a verifier dans la base)
$CustomerId = 1

Write-Host "=========================================="
Write-Host "  GENERATION SQL TEMPLATES MAILWIZZ"
Write-Host "=========================================="
Write-Host ""

# Mapping langues
$LangNames = @{
    "fr" = "Francais"
    "en" = "English"
    "es" = "Espanol"
    "de" = "Deutsch"
    "pt" = "Portugues"
    "ar" = "Arabic"
    "zh" = "Chinese"
    "hi" = "Hindi"
    "ru" = "Russian"
}

# Debut du fichier SQL
$sql = @"
-- ============================================================================
-- IMPORT TEMPLATES MAILWIZZ - 742 TEMPLATES (7 LANGUES x 106 TEMPLATES)
-- Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
-- ============================================================================

-- Supprimer les anciens templates
DELETE FROM mw_customer_email_template WHERE customer_id = $CustomerId;

-- Desactiver les checks pour import rapide
SET FOREIGN_KEY_CHECKS = 0;
SET UNIQUE_CHECKS = 0;
SET AUTOCOMMIT = 0;


"@

$count = 0
$templates = Get-ChildItem -Path $TemplatesPath -Filter "*.html" -Recurse

foreach ($template in $templates) {
    $count++

    # Extraire les infos du chemin
    $relativePath = $template.FullName.Replace($TemplatesPath + "\", "")
    $parts = $relativePath -split "\\"

    # Structure: type/[audience]/lang/[campaign]/file.html
    $type = $parts[0]  # campaign, newsletter, transactional

    # Determiner la langue et le nom
    $lang = ""
    $campaignName = ""
    $fileName = $template.BaseName

    foreach ($part in $parts) {
        if ($LangNames.ContainsKey($part)) {
            $lang = $part
        }
    }

    # Construire le nom du template
    $audience = if ($parts.Count -gt 2 -and $parts[1] -match "client|provider") { $parts[1] } else { "" }
    $campaign = if ($parts.Count -gt 3 -and $parts[3] -ne $template.Name) { $parts[3] } else { "" }

    $templateName = "$type"
    if ($audience) { $templateName += "-$audience" }
    if ($campaign) { $templateName += "-$campaign" }
    $templateName += "-$fileName"
    $templateName += " [$($lang.ToUpper())]"

    # Generer UID unique
    $uid = [System.Guid]::NewGuid().ToString("N").Substring(0, 13)

    # Lire le contenu HTML
    $content = Get-Content -Path $template.FullName -Raw -Encoding UTF8

    # Calculer le hash SHA1 du contenu
    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
    $hashBytes = $sha1.ComputeHash($bytes)
    $contentHash = [BitConverter]::ToString($hashBytes).Replace("-", "").ToLower()

    # Echapper les caracteres speciaux pour SQL
    $contentEscaped = $content -replace "\\", "\\\\"
    $contentEscaped = $contentEscaped -replace "'", "''"
    $templateNameEscaped = $templateName -replace "'", "''"

    # Generer l'INSERT (structure correcte MailWizz)
    $sql += @"
INSERT INTO mw_customer_email_template (template_uid, customer_id, category_id, name, content, content_hash, create_screenshot, screenshot, inline_css, minify, meta_data, sort_order, date_added, last_updated)
VALUES ('$uid', $CustomerId, NULL, '$templateNameEscaped', '$contentEscaped', '$contentHash', 'no', NULL, 'no', 'no', NULL, $count, NOW(), NOW());

"@

    if ($count % 50 -eq 0) {
        Write-Host "  Traite: $count / $($templates.Count)"
    }
}

# Fin du fichier SQL
$sql += @"

-- Reactiver les checks
COMMIT;
SET FOREIGN_KEY_CHECKS = 1;
SET UNIQUE_CHECKS = 1;
SET AUTOCOMMIT = 1;

-- Verification
SELECT COUNT(*) as 'Templates importes' FROM mw_customer_email_template WHERE customer_id = $CustomerId;
"@

# Ecrire le fichier
$sql | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host ""
Write-Host "=========================================="
Write-Host "  TERMINE!"
Write-Host "=========================================="
Write-Host ""
Write-Host "Fichier genere: $OutputFile"
Write-Host "Templates: $count"
Write-Host ""
Write-Host "PROCHAINE ETAPE:"
Write-Host "  1. scp `"$OutputFile`" root@46.62.168.55:/root/"
Write-Host "  2. mysql -u mailapp -p`$MAILWIZZ_DB_PASSWORD mailapp < /root/templates-import.sql"
Write-Host ""
