<#
.SYNOPSIS
    Instala Office con ODT + XML de este repo (pide Admin solo).
.EJEMPLO
    powershell -ExecutionPolicy Bypass -File .\Instalar-Office.ps1
    powershell -ExecutionPolicy Bypass -File .\Instalar-Office.ps1 -Config .\configs\Office-M365-Empresa.xml
#>
param(
    [string]$Config = (Join-Path $PSScriptRoot "configs\Office-ProPlus2021-VL.xml")
)

# --- Auto-elevar a Administrador (vale doble clic) ---
$esAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $esAdmin) {
    Write-Host "Re-lanzando como Administrador (UAC)..." -ForegroundColor Yellow
    $reenvio = ($PSBoundParameters.GetEnumerator() | ForEach-Object {
        if ($_.Value -is [System.Management.Automation.SwitchParameter]) { if ($_.Value) { "-$($_.Key)" } }
        else { "-$($_.Key) `"$($_.Value)`"" }
    }) -join ' '
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`" $reenvio" -Verb RunAs
    exit
}

$ErrorActionPreference = "Stop"
$setup = Join-Path $PSScriptRoot "odt\setup.exe"

if (-not (Test-Path $setup)) {
    Write-Host "Falta odt\setup.exe" -ForegroundColor Red
    Write-Host "1) Descarga Office Deployment Tool: https://www.microsoft.com/en-us/download/details.aspx?id=49117"
    Write-Host "2) Ejecuta el .exe descargado y extrae setup.exe en la carpeta odt\ de este repo."
    exit 1
}
if (-not (Test-Path $Config)) { Write-Host "No existe: $Config" -ForegroundColor Red; exit 1 }

Write-Host "Instalando Office con: $Config" -ForegroundColor Cyan
& $setup /configure $Config
if ($LASTEXITCODE -eq 0) {
    Write-Host "Instalacion OK. Log en %temp% (setup*.log)." -ForegroundColor Green
    Write-Host "Siguiente: .\Activar-Office.ps1  (solo ediciones Volumen/KMS)"
} else {
    Write-Host "setup.exe termino con codigo $LASTEXITCODE. Revisa %temp%\setup*.log" -ForegroundColor Red
    exit $LASTEXITCODE
}
