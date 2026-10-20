# office-deploy — Instalación desatendida de Office (ODT + KMS IBM)

Instalación repetible de Office en PCs nuevas: mismo XML, mismo proceso,
activación contra el KMS propio (`192.168.100.124:1688`, vlmcsd en el IBM).

## Requisito único

- Windows 10/11 64-bit con red a la oficina (o Tailscale al IBM).
- PowerShell **como Administrador**.

## Uso en una PC nueva (5 min)

```powershell
# 1) Copia esta carpeta a la PC (USB o red) y entra en ella
cd C:\office-deploy

# 2) Pon setup.exe del ODT en odt\ (solo la primera vez por PC/repo)
#    Descarga: https://www.microsoft.com/en-us/download/details.aspx?id=49117
#    Ejecuta el .exe y extrae en odt\

# 3) Instala (edicion Volumen 2021 por defecto)
.\Instalar-Office.ps1
#    o la variante suscripcion:
#    .\Instalar-Office.ps1 -Config .\configs\Office-M365-Empresa.xml

# 4) Activa contra el KMS del IBM (solo ediciones Volumen)
.\Activar-Office.ps1
#    con otro host/puerto:
#    .\Activar-Office.ps1 -KmsHost 192.168.100.124 -KmsPort 1688
#    tambien Windows:  .\Activar-Office.ps1 -Windows
```

## Qué hace cada archivo

| Archivo | Para qué |
|---|---|
| `configs/Office-ProPlus2021-VL.xml` | Office LTSC Pro Plus 2021, es-es, 64-bit, canal `PerpetualVL2021`, clave GVLK pública, `AUTOACTIVATE=0`. **Esta es la que usa KMS.** |
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
