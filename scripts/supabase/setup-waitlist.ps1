<#
.SYNOPSIS
  One-off manual setup of the landing beta waitlist on the hosted Supabase project.
  (The normal path is: merge to main, then run the "Deploy Supabase (hosted)" workflow, then set
  the secrets. This script does the same from a Windows machine.)
  See docs/runbooks/landing-waitlist.md.

.EXAMPLE
  pwsh scripts/supabase/setup-waitlist.ps1 -ProjectRef abcdefghijklmnopqrst -From "Ourney <hello@ourney.tech>" -NotifyTo you@example.com

  Asks for the Resend API key (hidden input). Needs Node.js (runs the Supabase CLI through npx)
  and a Supabase login (`npx supabase login`, or SUPABASE_ACCESS_TOKEN in the environment).
  `db push` asks for the database password unless SUPABASE_DB_PASSWORD is set.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][ValidatePattern('^[a-z0-9]{20}$')][string]$ProjectRef,
  [Parameter(Mandatory = $true)][string]$From,
  [string]$NotifyTo = '',
  [string]$ReplyTo = '',
  [string]$AllowedOrigins = 'https://ourney.tech,https://www.ourney.tech',
  [switch]$SkipDbPush,
  [switch]$SkipLandingEdit
)

$ErrorActionPreference = 'Stop'
$repo = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repo
$cli = @('--yes', 'supabase@2.121.0')

function Invoke-Supabase {
  param([string[]]$CliArgs)
  & npx @cli @CliArgs
  if ($LASTEXITCODE -ne 0) { throw "supabase $($CliArgs -join ' ') failed ($LASTEXITCODE)" }
}

Write-Host '==> Linking project'
Invoke-Supabase @('link', '--project-ref', $ProjectRef)

if (-not $SkipDbPush) {
  Write-Host '==> Applying migrations (db push, includes 0022_landing_waitlist)'
  Invoke-Supabase @('db', 'push')
}

Write-Host '==> Deploying function waitlist-signup (anonymous access)'
Invoke-Supabase @('functions', 'deploy', 'waitlist-signup', '--project-ref', $ProjectRef, '--no-verify-jwt')

Write-Host '==> Setting function secrets'
$secure = Read-Host -AsSecureString 'Resend API key (re_...)'
$resendKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
  [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
if (-not $resendKey) { throw 'Resend API key is empty' }

# Secrets go through a temporary env file so the key never appears on a command line.
$envFile = New-TemporaryFile
try {
  $lines = @(
    "RESEND_API_KEY=$resendKey",
    "WAITLIST_FROM=$From",
    "WAITLIST_ALLOWED_ORIGINS=$AllowedOrigins"
  )
  if ($NotifyTo) { $lines += "WAITLIST_NOTIFY_TO=$NotifyTo" }
  if ($ReplyTo) { $lines += "WAITLIST_REPLY_TO=$ReplyTo" }
  Set-Content -Path $envFile -Value $lines -Encoding utf8
  Invoke-Supabase @('secrets', 'set', '--env-file', $envFile.FullName, '--project-ref', $ProjectRef)
} finally {
  Remove-Item $envFile -Force -ErrorAction SilentlyContinue
  $resendKey = $null
}

if (-not $SkipLandingEdit) {
  Write-Host '==> Writing the endpoint into apps/landing/index.html'
  $index = Join-Path $repo 'apps\landing\index.html'
  $html = [IO.File]::ReadAllText($index)
  $updated = $html.Replace('https://PROJECT_REF.supabase.co/functions/v1/waitlist-signup',
    "https://$ProjectRef.supabase.co/functions/v1/waitlist-signup")
  if ($updated -ne $html) {
    [IO.File]::WriteAllText($index, $updated, (New-Object Text.UTF8Encoding($false)))
    Write-Host '    updated (commit it and redeploy the landing on Vercel)'
  } else {
    Write-Host '    placeholder not found (already set?)'
  }
}

Write-Host '==> Smoke test'
$origin = ($AllowedOrigins -split ',')[0].Trim()
# delivered@resend.dev is Resend's test inbox: a real send without hurting the domain reputation.
$body = @{ email = 'delivered@resend.dev'; lang = 'vi'; platforms = @('ios', 'android'); source = 'setup-script' } | ConvertTo-Json
try {
  $res = Invoke-WebRequest -Method Post -Uri "https://$ProjectRef.supabase.co/functions/v1/waitlist-signup" `
    -Headers @{ Origin = $origin } -ContentType 'application/json' -Body $body -UseBasicParsing
  Write-Host "    HTTP $($res.StatusCode) $($res.Content)"
} catch {
  Write-Warning "    smoke test failed: $($_.Exception.Message)"
}
Write-Host 'Done. Check the row and its confirmation_sent_at / confirmation_error in SQL Editor, then remove it:'
Write-Host "  select * from private.waitlist where source = 'setup-script';"
Write-Host "  delete from private.waitlist where source = 'setup-script';"
