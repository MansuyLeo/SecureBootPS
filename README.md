# Script d'activation du SecureBoot sur les postes Lenovo, HP et Dell

## Instructions:
- Copiez le fichier "run_script.bat" et le script "SNCF_TAM_SecureBoot_v1_0.ps1" sur le poste distant dans UN MEME DOSSIER.
- Exécutez "run_script.bat" en tant qu'administrateur depuis le poste distant.  

## Informations utiles:
- Quoi qu'il arrive, le script ne peut pas s'exécuter en tant qu'utilisateur normal (y compris le .bat).
- Le script peut-être exécuté depuis un support amovible connecté au poste concerné.
- Le poste redémarrera UNIQUEMENT si le script est concluant.
- Un fichier .log est crée durant l'exécution du script dans le sous répertoire "Logs" crée à l'emplacement du script PowerShell.
- Le script vérifie s'il y'a un mot de passe BIOS présent et l'utilisateur peut le rentrer de lui-même.  

Pour toutes questions, informations et erreurs: MANSUY Léo - Alternant TAM PSL - leo.mansuy@sncf.fr - leo.mansuy.mz@gmail.com
