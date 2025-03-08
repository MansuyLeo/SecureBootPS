# Script par MANSUY Léo - Alternant TAM PSL - DSNU DASU IDF - e.SNCF Solutions
# Script d'activation du Secure Boot sur les postes de travail Lenovo, HP et Dell
# Si modification du script, se rappeler d'encoder le fichier en UTF-8 avec prise en charge BOM

<# v1.0
Tests de validations initiaux (QC/QA):
- Sans BitLocker
- Avec Bitlocker
- Sans Bitlocker + MDP BIOS
- Avec BitLocker + MDP BIOS
- Le script doit s'arrêter si: le script n'est pas éxécuté avec les droits administrateurs
- Le script doit d'arrêter si: l'utilisateur n'a pas sélectionné "Oui" dans la boite de dialogue
- Le script doit s'arrêter si: le fabricant est autre que Lenovo, HP ou Dell
- Le script doit s'arrêter si: mode BIOS n'est pas UEFI (Legacy)
- Le script doit s'arrêter si: platform mode est Setup Mode (Secure Boot activé ou non)
- Le script doit s'arrêter si: le Secure Boot est déjà actif

Validés LENOVO (L380)
Validés HP (Probook 440 G7)
Validés DELL (Latitude 5420)
#>

# Variables globales
$logDir = Join-Path $PSScriptRoot "Logs"
$logPath = Join-Path $logDir "Log_Script.log"
$greenCheck = @{ Object = [char]0x2705; ForegroundColor = 'Green'; NoNewLine = $true } # coche verte
$yellowWarning = @{ Object = [char]0x26A0; ForegroundColor = 'Yellow'; NoNewLine = $true } # warning jaune
$manufacturer = (Get-WmiObject -Class Win32_ComputerSystem).Manufacturer

# Liste des syntaxes possibles WMI sur les postes Lenovo pour l'activation du Secure Boot
$secureBootCommandsLenovo = @("SecureBoot,Enable", "Secure Boot,Enabled", "SecureBoot,Enabled")

# Liste des modèles HP sur le parc identifiés avec une syntaxe CIM différente pour l'activation du Secure Boot
$specificModelsHP = @("HP ProBook 430 G2", "HP ZBook Power G7 Mobile Workstation", "HP ZBook Fury 15 G7 Mobile Workstation", "HP ZBook 15 G2", "HP ProBook 450 G8 Notebook PC")


# Fonction pour ajouter des logs
function Add-Log {
    param ([string]$message) Add-Content -Path $logPath -Value "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") - $message" -Encoding UTF8
}

# Fonction pour vérifier les droits administrateurs
function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Ce script doit être exécuté en tant qu'administrateur" -ForegroundColor Red
        Add-Log "L'utilisateur du script n'a pas le rôle administrateur"
        exit 1
    }
}

# Fonction pour afficher la boîte de dialogue de confirmation
function Show-ConfirmationDialog {
    $message = "Le poste redémarrera à l'issue du script. Veuillez enregistrer tous vos documents en cours. Voulez-vous continuer?"
    Add-Type -AssemblyName PresentationFramework
    return [System.Windows.MessageBox]::Show($message, "Confirmation", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
}

# Fonction pour vérifier le fabricant
function Test-Manufacturer {
    if ($manufacturer -notmatch "LENOVO|HP|Dell Inc.") {
        Write-Host "Ce script fonctionne uniquement sur les postes Lenovo, HP et Dell. Le Fabricant actuel du poste est : $manufacturer" -ForegroundColor Red
        Add-Log "Fabricant pas Lenovo, HP ou Dell: NOK, Fabricant: $manufacturer"
        exit 1
    } else {
        Write-Host @greenCheck
        Write-Host " Fabricant $manufacturer : Oui"
        Add-Log "Fabricant $manufacturer : Oui"
        if ($manufacturer -eq "LENOVO") {
            $modelVersionLenovo = Get-WmiObject Win32_ComputerSystemProduct | Select-Object -ExpandProperty Version # récup du modèle spécifique à Lenovo
            Write-Host @greenCheck
            Write-Host " Modèle : $modelVersionLenovo"
            Add-Log "Modèle : $modelVersionLenovo"
        } else {
            $modelVersion = (Get-WmiObject Win32_ComputerSystem).Model
            Write-Host @greenCheck
            Write-Host " Modèle : $modelVersion"
            Add-Log "Modèle : $modelVersion"
        }
    }
}

# Fonction pour vérifier le mode UEFI
function Test-UEFI {
    if ($env:firmware_type -eq "UEFI") {
        Write-Host @greenCheck
        Write-Host " Mode BIOS UEFI : OK"
        Add-Log "Mode BIOS UEFI: OK"
    } else {
        Write-Host "Le mode BIOS n'est pas UEFI, faire le nécessaire pour qu'il soit UEFI" -ForegroundColor Red
        Add-Log "Mode BIOS UEFI: NOK"
        exit 1
    }
}

# Fonction pour vérifier l'état du Secure Boot
function Test-SecureBoot {
    if (Confirm-SecureBootUEFI) {
        Write-Host "Le Secure Boot est déjà actif sur ce poste" -ForegroundColor Green
        Add-Log "Secure Boot: OK (déjà activé)"
        exit 0
    }
}

# Fonction pour vérifier le mode de la plateforme Secure Boot
function Test-PlatformMode {
    if ((Get-SecureBootUEFI -Name SetupMode).Bytes -eq 1) {
        Write-Host "Le Secure Boot est en Setup Mode / Audit Mode, faire le nécessaire dans le BIOS pour qu'il soit en User Mode / Deployed mode (Reset Secure Boot Factory Keys ou option similaire, il est possible de sélectionner directement le mode selon les modèles)" -ForegroundColor Red
        Add-Log "Platform mode = SETUP MODE: NOK"
        exit 1
    } else {
        Write-Host @greenCheck
        Write-Host " User Mode ou Deployed Mode: OK"
        Add-Log "Platform mode = USER MODE: OK"
    }
    <# Dell Latitude 5420: possible de changer le platform mode via wmi pour une évolution future du script:
    check l'état: Get-CimInstance -Namespace root\dcim\sysman\biosattributes -ClassName EnumerationAttribute | Where-Object AttributeName -eq "SecureBootMode" | Select-Object AttributeName,CurrentValue,PossibleValue
    set attribute: (Get-WmiObject -Namespace root\dcim\sysman\biosattributes -Class BIOSAttributeInterface).SetAttribute(0, 0, 0, "SecureBootMode", "DeployedMode") #>
}

# Fonction pour vérifier et suspendre BitLocker
function Test-BitLocker {
    $bitLockerStatus = Get-BitLockerVolume -MountPoint "C:"
    if ($bitLockerStatus.ProtectionStatus -eq 'On') {
        Suspend-BitLocker -MountPoint "C:" -RebootCount 1 | Out-Null # commande critique suspension du BitLocker
    }
    Write-Host @greenCheck
    Write-Host " BitLocker Suspendu : OK"
    Add-Log "BitLocker suspendu: OK"
}

# Fonction pour gérer le mot de passe du BIOS
function Test-BIOSPassword{
    ## LENOVO ##
    if ($manufacturer -eq "LENOVO") {
        $IsPasswordSet = (Get-WmiObject -Class Lenovo_BiosPasswordSettings -Namespace root\wmi).PasswordState
        if ($IsPasswordSet) {
            Write-Host @yellowWarning
            Write-Host "  Password BIOS : Oui"
            Add-Log "Password BIOS : Oui"
            Write-Host "Mot de passe BIOS détecté. Veuillez entrer le mot de passe : " -ForegroundColor Yellow
            $BIOSPassword = Read-Host
            return $BIOSPassword + ",ascii,fr" # interprété en ascii par le BIOS
        }
    }

    ## HP ##
    if ($manufacturer -eq "HP") {
        $IsPasswordSet = (Get-CimInstance -Namespace root\hp/InstrumentedBIOS -ClassName HP_BIOSSetting | Where-Object {$_.Name -eq "Setup Password"}).IsSet
        if ($IsPasswordSet) {
            Write-Host @yellowWarning
            Write-Host "  Password BIOS : Oui"
            Add-Log "Password BIOS : Oui"
            Write-Host "Mot de passe BIOS détecté. Veuillez entrer le mot de passe : " -ForegroundColor Yellow
            $BIOSPassword = Read-Host
            return "<utf-16/>" + $BIOSPassword # interprété en utf-16 par le BIOS
        }
    }

    ## DELL ##
    if ($manufacturer -eq "Dell Inc.") {
        $IsPasswordSet = (Get-CimInstance -Namespace root\dcim\sysman\wmisecurity -ClassName PasswordObject | Where-Object NameId -EQ "Admin").IsPasswordSet
        if ($IsPasswordSet) {
            Write-Host @yellowWarning
            Write-Host "  Password BIOS : Oui"
            Add-Log "Password BIOS : Oui"
            Write-Host "Mot de passe BIOS détecté. Veuillez entrer le mot de passe : " -ForegroundColor Yellow
            $BIOSPassword = Read-Host
            $Encoder = New-Object System.Text.UTF8Encoding
            $BIOSPassword = $Encoder.GetBytes($BIOSPassword) # encodé en utf-8 puis conversion en bytes
            return $BIOSPassword
        }
    }
    Write-Host @greenCheck
    Write-Host " Password BIOS : Non"
    Add-Log "Password BIOS : Non"
    return $null
}

# Fonction pour activer le Secure Boot
function Enable-SecureBoot {
    $BIOSPasswordSet = Test-BIOSPassword # appel de la fonction Test-BIOSPassword

    ## LENOVO ##
    if ($manufacturer -eq "LENOVO") {
        $secureBootEnabled = $false  # variable pour suivre le succès de la boucle
        foreach ($command in $secureBootCommandsLenovo) {
            if ($null -eq $BIOSPasswordSet) {
                $setResult = (Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi).SetBiosSetting("$command")
            } else {
                $setResult = (Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi).SetBiosSetting("$command,$BIOSPasswordSet")
            }
            if ($setResult.return -eq "Success") {   
                Add-Log "SetBiosSetting $command : OK"
                $saveResult = (Get-WmiObject -Class Lenovo_SaveBiosSettings -Namespace root\wmi).SaveBiosSettings("$BIOSPasswordSet")
                if ($saveResult.return -eq "Success") {
                        Add-Log "SaveBiosSetting $command : OK"
                        $secureBootEnabled = $true
                        break  # sortie de la boucle
                } else {
                        Write-Host "Echec de l'activation du Secure Boot, Return code: $($saveResult.return)" -ForegroundColor Red
                        Add-Log "SaveBiosSetting $command : NOK"
                        Add-Log "Activation SecureBoot: NOK, Return code: $($saveResult.return), arrêt du script"
                        exit 1
                }
            } else {
                Add-Log "SetBiosSetting $command : NOK, return: $($setResult.return), essai avec la prochaine commande" # non critique, pas d'affichage au user
            }
        }

        # Vérification après la boucle
        if ($secureBootEnabled) {
            Write-Host "Succès de l'activation du Secure Boot, Return code: $($saveResult.return)" -ForegroundColor Green
            Write-Host "Redémarrage dans 10 secondes..."
            Add-Log "Initialisation du redémarrage"
            Add-Log "Activation SecureBoot: OK, Return code 0"
            Start-Sleep -Seconds 10
            Restart-Computer -Force
        } else {
            Write-Host "Echec de l'activation du Secure Boot, Return code: $($setResult.return)" -ForegroundColor Red
            Add-Log "Liste des syntaxes: NOK, SetBiosSetting: NOK" # peut-être également mdp bios incorrect quand mdp bios présent
            Add-Log "Activation SecureBoot: NOK, Return code: $($setResult.return), arrêt du script"
            exit 1
        }
    }

    ## HP ##
    if ($manufacturer -eq "HP") {
        $Bios = Get-CimInstance -Namespace root/HP/InstrumentedBIOS -ClassName HP_BIOSSettingInterface
        $arguments = @{
            Name = if ($specificModelsHP -contains $modelVersion) { 'SecureBoot' } else { 'Configure Legacy Support and Secure Boot' }
            Value = if ($specificModelsHP -contains $modelVersion) { 'Enable' } else { 'Legacy Support Disable and Secure Boot Enable' }
            Password = $BIOSPasswordSet
        }
        $result = $Bios | Invoke-CimMethod -MethodName SetBIOSSetting -Arguments $arguments
        if ($result.Return -eq 0) {
            Write-Host "Succès de l'activation du Secure Boot, Return code 0" -ForegroundColor Green
            Write-Host "Redémarrage dans 10 secondes..."
            Add-Log "Initialisation du redémarrage"
            Add-Log "Activation SecureBoot: OK, Return code 0"
            Start-Sleep -Seconds 10
            Restart-Computer -Force
        } else {
            Write-Host "Echec de l'activation du Secure Boot, Return code $($result.Return)" -ForegroundColor Red
            Add-Log "Activation SecureBoot: NOK, Return code $($result.Return), arrêt du script"
            exit $($result.Return)
        }
    }

    ## DELL ##
    if ($manufacturer -eq "Dell Inc.") {
        $Bios = Get-WmiObject -Namespace root\dcim\sysman\biosattributes -Class BIOSAttributeInterface
        if ($null -eq $BIOSPasswordSet) {
            $result = $Bios.SetAttribute(0, 0, 0, "SecureBoot", "Enabled")
        } else {
            $result = $Bios.SetAttribute(1, $BIOSPasswordSet.Length, $BIOSPasswordSet, "SecureBoot", "Enabled")
        }
            if ($result.Status -eq 0) {
                Write-Host "Succès de l'activation du Secure Boot, Return code 0" -ForegroundColor Green
                Write-Host "Redémarrage dans 10 secondes..."
                Add-Log "Initialisation du redémarrage"
                Add-Log "Activation SecureBoot: OK, Return code 0"
                Start-Sleep -Seconds 10
                Restart-Computer -Force
            } else {
                Write-Host "Echec de l'activation du Secure Boot, Return code $($result.Status)" -ForegroundColor Red
                Add-Log "Activation SecureBoot: NOK, Return code $($result.Status), arrêt du script"
                exit $($result.Status)
            }
    }
}
### Démarrage du script ###

# Création du dossier Logs s'il n'existe pas
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

# Effacement du contenu du fichier log principal au début du programme s'il existe
if (Test-Path $logPath) { Clear-Content -Path $logPath }

# Vérification des droits administratifs
Test-Administrator

# Affichage de la boîte de dialogue de confirmation
$dialog = Show-ConfirmationDialog
if ($dialog -eq "Yes") {
    Write-Output "Démarrage du script..."
    try {
        Test-Manufacturer
        Test-UEFI
        Test-PlatformMode
        Test-SecureBoot
        Test-BitLocker
        Enable-SecureBoot
    } catch {
        Write-Host "Une erreur est survenue : $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Annulation du script"
    Add-Log "Script annulé par l'utilisateur lors du popup, arrêt du script"
    exit 1
}

<# Return codes lors de l'activation du Secure Boot:

LENOVO (pas de numérotation explicite):

- Success
- Not Supported
- Invalid Parameter
- Access Denied – BIOS password not supplied or not correct
- System Busy – There are pending setting changes. Reboot and try again

HP:

0 – Success
1 – Not Supported
2 – Unspecified Error
3 – Timeout
4 – Failed (Usually caused by a typo in the setting value)
5 – Invalid Parameter
6 – Access Denied (Usually caused by an incorrect BIOS password)

DELL:

0 – Success
1 – Failed
2 – Invalid Parameter
3 – Access Denied
4 – Not Supported
5 – Memory Error
6 – Protocol Error

#>
