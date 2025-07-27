# Changelog

Tutte le modifiche importanti a questo progetto saranno documentate in questo file.

Il formato è basato su [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
e questo progetto aderisce a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Conversione da `sprintf` a `glue` in tutti gli script R per sintassi più moderna
- Documentazione completa della struttura del repository nel README
- File CHANGELOG.md per tracciare le modifiche
- Esempi di password sicure nel file .env.example
- Configurazioni avanzate opzionali (timezone, memory, debug)
- Sezione sicurezza e produzione nel README

### Changed
- README.md completamente rivisto con struttura migliorata
- Script R aggiornati per usare glue invece di sprintf
- File .env.example più documentato e con esempi pratici
- Migliorata la tabella dei comandi Makefile nel README

### Improved
- Documentazione più chiara per setup e troubleshooting
- Esempi di codice più leggibili e mantenibili
- Struttura organizzativa del progetto più professionale

## [1.0.0] - 2024-XX-XX

### Added
- Setup iniziale dell'ambiente opal-lab
- Docker Compose con 6 servizi (2 Opal + 2 Rock + 2 MongoDB + RStudio)
- Scripts di automazione per setup dati e analisi demo
- Makefile con comandi utili per gestione del progetto
- Documentazione completa in italiano
- File di esempio per dataset CSV
- Health checks per tutti i servizi Docker
- Network isolation tra i siti
- Backup automatico dei database MongoDB