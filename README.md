# Script d'activation du SecureBoot sur les postes Lenovo, HP et Dell

## Instructions:

1. Copiez le fichier "run_script_v1_0.bat" et le script "SecureBootPS_v1_0.ps1" sur le poste distant dans UN MEME DOSSIER.
2. Exécutez "run_script_v1_0.bat" en tant qu'administrateur.  

## Information Setup Mode / Audit Mode:

Les PCs avec le Secure Boot activé ou non mais en Setup Mode (Lenovo, HP) ou Audit Mode (Dell) ne peuvent pour l’instant être corrigés que manuellement via le BIOS par l'option "Clear Secure Boot Factory keys" ou similaire. Certains modèles peuvent également proposer de changer directement le mode.

## Return codes lors de l'activation du Secure Boot:

### LENOVO (pas de numérotation explicite):

- Success
- Not Supported
- Invalid Parameter
- Access Denied – BIOS password not supplied or not correct
- System Busy – There are pending setting changes. Reboot and try again

### HP:

- 0 – Success
- 1 – Not Supported
- 2 – Unspecified Error
- 3 – Timeout
- 4 – Failed (Usually caused by a typo in the setting value)
- 5 – Invalid Parameter
- 6 – Access Denied (Usually caused by an incorrect BIOS password)

### DELL:

- 0 – Success
- 1 – Failed
- 2 – Invalid Parameter
- 3 – Access Denied
- 4 – Not Supported
- 5 – Memory Error
- 6 – Protocol Error

Un grand merci à Jon Anderson qui a été d'une grande inspiration pour ce script. Consulter son blog ici: https://www.configjon.com/
