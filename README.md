# office-deploy — Instalación desatendida de Office (ODT + KMS IBM)

Instalación repetible de Office en PCs nuevas: mismo XML, mismo proceso,
activación contra el KMS propio (`192.168.100.124:1688`, vlmcsd en el IBM).

## Requisito único

- Windows 10/11 64-bit con red a la oficina (o Tailscale al IBM).
- Los scripts **piden Administrador solos**: si los abres sin elevar,
  se relanzan con UAC (acepta el aviso). Vale doble clic.

## Permisos y ExecutionPolicy Bypass

Si PowerShell bloquea el script (`cannot be loaded... execution of scripts
is disabled`), correlo con Bypass (solo afecta a esa ejecucion, no cambia
nada del sistema):

```powershell
powershell -ExecutionPolicy Bypass -File .\Instalar-Office.ps1
powershell -ExecutionPolicy Bypass -File .\Activar-Office.ps1 -Key TU-CLAVE
```

Con GPO `MachinePolicy`/`ConstrainedLanguage` el Bypass no alcanza: en ese
caso firma el script o ejecutalo desde sesion de admin con
`Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` antes.

## Uso en una PC nueva (5 min)

```powershell
# 1) Copia esta carpeta a la PC (USB o red) y entra en ella
cd C:\offdeploy

# 2) Pon setup.exe del ODT en odt\ (solo la primera vez por PC/repo)
#    Descarga: https://www.microsoft.com/en-us/download/details.aspx?id=49117
#    Ejecuta el .exe y extrae en odt\

# 3) Instala (edicion Volumen 2021 por defecto) - pide UAC solo
powershell -ExecutionPolicy Bypass -File .\Instalar-Office.ps1
#    o la variante suscripcion / 2024:
#    powershell -ExecutionPolicy Bypass -File .\Instalar-Office.ps1 -Config .\configs\Office-M365-Empresa.xml
#    powershell -ExecutionPolicy Bypass -File .\Instalar-Office.ps1 -Config .\configs\Office-ProPlus2024-VL.xml

# 4) Activa contra el KMS del IBM (solo ediciones Volumen) - pide UAC solo
powershell -ExecutionPolicy Bypass -File .\Activar-Office.ps1 -Key TU-CLAVE-GVLK
#    tambien Windows:  ... -Key TU-CLAVE -Windows
```

## Qué hace cada archivo

| Archivo | Para qué |
|---|---|
| `configs/Office-ProPlus2021-VL.xml` | Office LTSC Pro Plus 2021, es-es, 64-bit, canal `PerpetualVL2021`, clave GVLK pública, `AUTOACTIVATE=0`. **Esta es la que usa KMS.** |
| `configs/Office-ProPlus2024-VL.xml` | Office LTSC Pro Plus 2024, canal `PerpetualVL2024`. **Sin PIDKEY a propósito**: instala y luego `Activar-Office.ps1 -Key <clave>` (ospp valida al instante; una clave mala en el XML abortaría la instalación). |
| `configs/Office-M365-Empresa.xml` | Microsoft 365 Apps (suscripción). Se activa con la cuenta M365 del usuario, **no usa KMS**. |
| `Instalar-Office.ps1` | Corre `setup.exe /configure <xml>`. Sin intervención (`Display=None`). |
| `Activar-Office.ps1` | `ospp.vbs /sethst + /setprt + /act + /dstatus`. Switch `-Windows` para `slmgr /skms + /ato`. |
| `odt/` | Aquí va `setup.exe` del ODT (no se commitea). |

## Personalizar

- Quitar apps (Teams, Publisher...): descomenta líneas `ExcludeApp` en el XML.
- retail → volumen (para activar por KMS un Office ya instalado): el XML trae
  `PIDKEY` GVLK; tras instalar corre `Activar-Office.ps1`.
- Otros idiomas/canales: cambia `Language ID` y `Channel` en el XML
  ([referencia de ODT](https://learn.microsoft.com/deployoffice/office-deployment-tool-configuration-options)).

## Servidor KMS (IBM)

- Contenedor `kms-server` (imagen propia: Alpine + `Wind4/vlmcsd` compilado),
  compose en `/mnt/respaldos/kms/`, `restart: unless-stopped`, puerto `1688/tcp`.
- Replica del `kms-server` de la laptop (`~/workspace/tools/kms-server/`).
- Verificar: `nc -zv 192.168.100.124 1688` y `docker logs kms-server`.
- Nota: vlmcsd emula el servicio KMS de volumen. Las claves GVLK son públicas
  de Microsoft; úsalo conforme a tu licenciamiento por volumen.

## Publicar en GitHub

```bash
cd ~/workspace/office-deploy
git init -b main
git add .
git commit -m "Office ODT + KMS IBM: XMLs es-es y scripts PS"
# crea el repo vacio en github.com (sin README) y luego:
git remote add origin https://github.com/TU-USUARIO/office-deploy.git
git push -u origin main
```
