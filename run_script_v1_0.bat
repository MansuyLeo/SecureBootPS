:: Script par Mansuy Léo
:: Si modification de ce fichier batch, se rappeler de l'encoder en UTF-8
:: Script batch pour forcer l'ouverture du script powershell avec la demande des droits administrateurs

@echo off

:: Vérification si le .bat est exécuté avec les droits administrateurs
net session >nul 2>&1
if %errorlevel% neq 0 (
    PowerShell -Command "Write-Host 'Relancement avec demande droits administrateurs...'"
    PowerShell -Command "Start-Process '%~0' -Verb RunAs"
    exit /b
)

echo.
echo ##############################################
echo #                                            #
echo #           SCRIPT SECUREBOOT v1.0           #
echo #             Lenovo - HP - Dell             #
echo #             Auteur: MANSUY Leo             #
echo #                                            #
echo ##############################################
echo.

:: Lancement du script PowerShell avec la demande des droits administrateurs (situé dans le même répertoire)
PowerShell -NoLogo -ExecutionPolicy Bypass -NoExit -File "%~dp0SecureBootPS_v1_0.ps1"
