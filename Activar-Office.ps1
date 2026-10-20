#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Activa Office (Volumen) contra el KMS del IBM + opcional Windows.
.EJEMPLO
    .\Activar-Office.ps1
    .\Activar-Office.ps1 -Key FXYTK-NJJ8C-GB6DW-3DYQT-6F2ZS
    .\Activar-Office.ps1 -KmsHost 192.168.100.124 -KmsPort 1688
    .\Activar-Office.ps1 -Windows   # tambien activa Windows vs el KMS
#>
param(
    [string]$KmsHost = "192.168.100.124",
    [int]$KmsPort = 1688,
    [string]$Key = "",
    [switch]$Windows
)

$ErrorActionPreference = "Stop"

function Find-Ospp {
    $paths = @(
        "${env:ProgramFiles}\Microsoft Office\Office16\OSPP.VBS",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office16\OSPP.VBS"
    )
    foreach ($p in $paths) { if (Test-Path $p) { return $p } }
    return $null
}

$ospp = Find-Ospp
if (-not $ospp) { Write-Host "Office no encontrado (falta OSPP.VBS). Instala primero." -ForegroundColor Red; exit 1 }

if ($Key -ne "") {
    Write-Host "Instalando clave GVLK..." -ForegroundColor Cyan
    cscript //nologo "$ospp" /inpkey:$Key
    if ($LASTEXITCODE -ne 0) { Write-Host "La clave fue RECHAZADA. Verifica SKU/clave y reintenta." -ForegroundColor Red; exit 1 }
}

Write-Host "KMS -> ${KmsHost}:${KmsPort}" -ForegroundColor Cyan
cscript //nologo "$ospp" /sethst:$KmsHost | Select-String "Successfully|correcto|host"
cscript //nologo "$ospp" /setprt:$KmsPort | Select-String "Successfully|correcto|port"
cscript //nologo "$ospp" /act
Write-Host ""
Write-Host "=== Estado ===" -ForegroundColor Cyan
cscript //nologo "$ospp" /dstatus | Select-String "LICENSE|License|activation|Remaining|SKU|KMS"

if ($Windows) {
    Write-Host ""
    Write-Host "=== Activando Windows ===" -ForegroundColor Cyan
    slmgr /skms "${KmsHost}:${KmsPort}"
    slmgr /ato
    slmgr /dli
}
