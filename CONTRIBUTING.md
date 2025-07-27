# Guida per Contribuire

Grazie per l'interesse nel contribuire a opal-lab! Questo documento fornisce linee guida per contribuire al progetto.

## Come Contribuire

### 1. Segnalazione Bug

Se trovi un bug, apri una [issue](https://github.com/CorradoLanera/opal-lab/issues) includendo:

- Descrizione del problema
- Passi per riprodurlo
- Comportamento atteso vs. comportamento osservato
- Versioni di Docker, OS, browser utilizzati
- Log rilevanti (se disponibili)

### 2. Proposte di Miglioramento

Per nuove funzionalità o miglioramenti:

- Apri una issue per discutere l'idea prima di implementarla
- Spiega il caso d'uso e i benefici
- Considera l'impatto sulla compatibilità esistente

### 3. Pull Request

1. **Fork** del repository
2. **Clone** del tuo fork localmente
3. Crea un **branch** per la tua modifica:
   ```bash
   git checkout -b feature/nome-feature
   # oppure
   git checkout -b fix/nome-bug
   ```

4. **Implementa** le modifiche seguendo le convenzioni:
   - Commenti in italiano per coerenza con la documentazione
   - Codice R secondo [tidyverse style guide](https://style.tidyverse.org/)
   - YAML ben indentato e validato

5. **Testa** le modifiche:
   ```bash
   docker compose config  # valida syntax
   docker compose up -d   # testa ambiente completo
   ```

6. **Commit** con messaggi chiari:
   ```bash
   git commit -m "feat: aggiunge supporto per dataset personalizzati"
   git commit -m "fix: corregge problema connessione MongoDB"
   git commit -m "docs: migliora sezione troubleshooting"
   ```

7. **Push** e crea Pull Request:
   ```bash
   git push origin feature/nome-feature
   ```

### 4. Convenzioni di Codifica

#### Docker Compose
- Usa indentazione a 2 spazi
- Ordina i servizi logicamente (infrastruttura → applicazioni → client)
- Documenta variabili d'ambiente complesse

#### Documentazione
- Mantieni il README aggiornato
- Usa emoji per migliorare leggibilità (con moderazione)
- Esempi di codice testati e funzionanti
- Screenshot per procedure complesse (opzionale)

#### R Code
- Segui [tidyverse style guide](https://style.tidyverse.org/)
- Commenti esplicativi per codice DataSHIELD
- Gestione errori appropriata

### 5. Testing

Prima di aprire una PR, verifica che:

- [ ] `docker compose up -d` funziona correttamente
- [ ] Entrambi i siti Opal sono accessibili
- [ ] RStudio si avvia e i pacchetti DataSHIELD si installano
- [ ] Gli esempi nel README funzionano
- [ ] Non ci sono regressioni negli esempi esistenti

### 6. Tipi di Contributi Benvenuti

- **Bug fixes** e correzioni
- **Miglioramenti alla documentazione**
- **Esempi aggiuntivi** di analisi DataSHIELD
- **Ottimizzazioni** delle configurazioni Docker
- **Support per nuove versioni** di Opal/Rock

### 7. Cosa Non Includere

- File `.env` con password reali
- Dati sensibili o personali
- Configurazioni specifiche del tuo ambiente
- Dependencies non necessarie

### 8. Processo di Review

1. **Automated checks**: GitHub Actions verificherà syntax e build
2. **Manual review**: Un maintainer esaminerà le modifiche
3. **Discussion**: Eventuali feedback o richieste di modifica
4. **Merge**: Dopo l'approvazione, la PR viene mergeata

### 9. Codice di Condotta

- Rispetta tutti i partecipanti al progetto
- Usa linguaggio inclusivo e professionale
- Focalizzati sui fatti tecnici nelle discussioni
- Aiuta i nuovi contributori

### 10. Riconoscimenti

I contributori verranno riconosciuti nel README e nei release notes.

---

Per domande o chiarimenti, non esitare a aprire una issue o contattare i maintainer.

Grazie per il tuo contributo! 🙏
