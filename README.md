# DVS Music 0.5 — YouTubeKit + AVQueuePlayer (iPhone)

**Prototipo sperimentale per test su iPhone.**

- `native-ios/`: app SwiftUI con **YouTubeKit 0.4.10** e **AVQueuePlayer**, senza bisogno di tenere acceso un PC o installare un server domestico.
- Ricerca tramite istanze pubbliche Invidious, più possibilità di incollare un link o ID YouTube direttamente.
- Audio nativo `.playback`, background audio abilitato, controlli di blocco, coda pre-caricata, preferiti, casuale, ripetizione e radio.
- `.github/workflows/crea-ipa.yml`: workflow **DVS Music 0.5 - iPhone audio nativo (sperimentale)** per generare un IPA non firmato.
- La cartella principale conserva il codice Expo/React Native 0.4 come backup, ma **non è l'app nativa 0.5**.

Leggi `GUIDA_INSTALLAZIONE_WINDOWS.md` e `native-ios/README.md`.

**Non testato su Xcode/iPhone reale**: compilazione e riproduzione possono richiedere correzioni. YouTubeKit usa API non ufficiali, può interrompersi per modifiche YouTube e può violarne le condizioni d'uso. La ricerca Invidious può essere indisponibile. L'IPA generato, se la compilazione riesce, deve essere firmato per l'installazione.
