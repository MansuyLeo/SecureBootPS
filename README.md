# Script d'activation du SecureBoot sur les postes Lenovo, HP et Dell

## Instructions:
- Copiez le fichier "run_script.bat" et le script "SNCF_TAM_SecureBoot_v1_0.ps1" sur le poste distant dans UN MEME DOSSIER.
- Exécutez "run_script.bat" en tant qu'administrateur.  

## Return codes lors de l'activation du Secure Boot:

### LENOVO (pas de numérotation explicite):

- Success
- Not Supported
- Invalid Parameter
- Access Denied – BIOS password not supplied or not correct
- System Busy – There are pending setting changes. Reboot and try again

### HP:

0 – Success
1 – Not Supported
2 – Unspecified Error
3 – Timeout
4 – Failed (Usually caused by a typo in the setting value)
5 – Invalid Parameter
6 – Access Denied (Usually caused by an incorrect BIOS password)

### DELL:

0 – Success
1 – Failed
2 – Invalid Parameter
3 – Access Denied
4 – Not Supported
5 – Memory Error
6 – Protocol Error

Pour toutes questions, informations et erreurs: MANSUY Léo - Alternant TAM PSL - leo.mansuy@sncf.fr - leo.mansuy.mz@gmail.com
