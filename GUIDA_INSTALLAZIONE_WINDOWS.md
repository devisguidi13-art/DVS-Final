# DVS Music 0.5 — creare l'IPA iPhone su GitHub da Windows

Questa versione compila **l'app iOS nativa** (SwiftUI + YouTubeKit + AVQueuePlayer), non la precedente app Expo.

## Caricare la nuova versione

1. Estrai lo ZIP `DVS_Music_v05_iPhone_Audio_Nativo.zip` su Windows.
2. Apri il repository GitHub `DVS-Music` nella scheda **Code**.
3. Carica **il contenuto** della cartella estratta nella root del repository, mantenendo le cartelle `native-ios/` e `.github/workflows/`.
4. Se hai già creato `.github/workflows/crea-ipa.yml`, sostituisci quel file con **quello del pacchetto 0.5** (non lasciare il vecchio workflow Expo attivo per errore). GitHub Web può non preservare sempre cartelle nascoste nel drag-and-drop: se `.github` manca, usa `Add file > Create new file`, nome `.github/workflows/crea-ipa.yml`, e incolla il contenuto del file locale.
5. Clicca **Commit changes** sul branch `main`.

## Compilare

1. Apri **Actions** nel repository.
2. Seleziona **DVS Music 0.5 - iPhone audio nativo (sperimentale)**.
3. Clicca **Run workflow**, seleziona `main`, quindi di nuovo **Run workflow**.
4. Se l'esecuzione diventa verde, aprila e nella sezione **Artifacts** scarica `DVS_Music_05_iPhone_IPA_non_firmato`.
5. Estrai lo ZIP di GitHub e ottieni `DVS_Music_v05_unsigned.ipa`.

In caso di errore rosso, apri la fase fallita e copia il log: il sorgente Swift **non è stato ancora verificato compilando su macOS**.

## Installare da Windows

1. Apri https://sideloadly.io e installa Sideloadly con i suoi prerequisiti Windows.
2. Collega l'iPhone via USB e autorizza il computer.
3. Trascina `DVS_Music_v05_unsigned.ipa` in Sideloadly e usa il tuo Apple ID per la firma e l'installazione.
4. Se iOS lo richiede, abilita la Modalità sviluppatore in Impostazioni > Privacy e sicurezza.
5. Un Apple ID gratuito di solito richiede una nuova firma dopo 7 giorni.

## Prova pratica

Cerca una canzone su YouTube, oppure incolla un link di un video direttamente nel campo Cerca. Avvia il brano, poi blocca l'iPhone e prova play/pausa, successivo e cambio automatico. Verifica anche ricerca e radio: si appoggiano a istanze Invidious che potrebbero non rispondere.

## Limitazioni

- Nessuna garanzia di compilazione su GitHub, di funzionamento degli stream o di background audio: è un esperimento da testare su dispositivo reale.
- YouTubeKit è non ufficiale e può violare le condizioni di YouTube.
- Non è un'app Android: il player 0.5 è specifico per iOS. La cartella Expo 0.4 è conservata solo come backup.
