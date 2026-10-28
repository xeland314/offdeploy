# Optimizar Windows 11 en hardware antiguo (i3-370M / Sandy Bridge)
# Copiar a USB, clic derecho -> Ejecutar con PowerShell (se auto-eleva como Administrador)
# Requiere REINICIO al terminar.

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

Write-Host "== 1) Desactivar VBS / Integridad de memoria (el mayor consumidor oculto) ==" -ForegroundColor Cyan
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name "EnableVirtualizationBasedSecurity" -Value 0 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
bcdedit /set hypervisorlaunchtype off | Out-Null

Write-Host "== 2) Servicios pesados (SysMain, busqueda indexada, telemetria) ==" -ForegroundColor Cyan
foreach ($s in "SysMain","WSearch","DiagTrack","dmwappushservice","MapsBroker","RetailDemo","Fax","RemoteRegistry","WpcMonSvc") {
    sc.exe config $s start= disabled | Out-Null
    Stop-Service $s -Force -ErrorAction SilentlyContinue
    Write-Host "  desactivado: $s"
}

Write-Host "== 3) Tareas programadas de telemetria/compatibilidad ==" -ForegroundColor Cyan
$tasks = @(
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
    "\Microsoft\Windows\Application Experience\StartupAppTask",
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "\Microsoft\Windows\Autochk\Proxy",
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
)
foreach ($t in $tasks) { schtasks /Change /TN $t /Disable 2>$null | Out-Null }
Write-Host "  $($tasks.Count) tareas desactivadas"

Write-Host "== 4) Widgets y Copilot fuera ==" -ForegroundColor Cyan
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f | Out-Null
Get-AppxPackage Microsoft.Copilot -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
Get-AppxPackage *WebExperience* -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue

Write-Host "== 5) Limitar CPU al 80% (menos calor y ventilador) ==" -ForegroundColor Cyan
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 80
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 80
powercfg /setactive SCHEME_CURRENT

Write-Host "" 
Write-Host "LISTO. REINICIA el equipo." -ForegroundColor Green
pause
