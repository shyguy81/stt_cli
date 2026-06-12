**Guide d'utilisation — stt_cli**

- **But**: Transcrire un fichier `.m4a` (AAC) en texte via `whisper-rs`.

**Prerequis**:
- Rust toolchain (stable)
- Un modèle ggml (ex: `ggml-base.bin`) — voir section "Modèles".

**Build**

```bash
cargo build --release
```

**Exemple d'exécution (stdout)**

```bash
cargo run --release -- --model ./ggml-base.bin --m4a ./audio.m4a --lang fr
```

**Écrire la transcription dans un fichier**

```bash
cargo run --release -- --model ./ggml-base.bin --m4a ./audio.m4a --lang fr --output out.txt
```

**Sortie JSON pour automatisation / LLM**

```bash
cargo run --release -- --model ./ggml-base.bin --m4a ./audio.m4a --lang fr --json
```

**Options CLI importantes**
- `--model <path>` : chemin vers le fichier ggml (obligatoire)
- `--m4a <path>` : fichier audio d'entrée (obligatoire)
- `--lang <code>` : langue (ex: `fr`). Chaîne vide => auto-détection
- `--threads <n>` : nombre de threads pour `whisper` (0 => valeur par défaut de la lib)
- `--gpu` : active l'inférence GPU si le binaire a été compilé avec une feature GPU
- `--gpu-device <n>` : index du GPU à utiliser avec `--gpu`
- `--beam-size <n>` : largeur de BeamSearch (par défaut 5). Valeurs plus grandes peuvent améliorer la qualité au prix du temps CPU.
- `--temperature <f>` : température d'échantillonnage (0.0 par défaut). >0 favorise diversité.
- `--initial-prompt <text>` : prompt initial pour guider la transcription (utile pour domaine/sujet spécifique)
- `--output <path>` : écrire la transcription dans un fichier texte au lieu de stdout
- `--json` : produire une sortie JSON stable avec texte complet, segments et métadonnées

**Format de sortie**
- Par défaut, la CLI affiche chaque segment (nettoyé des blancs) sur stdout.
- Avec `--output`, le fichier contiendra la transcription complète, segments séparés par des retours à la ligne.
- Avec `--json`, la sortie contient `text`, `segments[]` (`index`, `start_ms`, `end_ms`, `text`) et `metadata`.
- Avec `--json --output out.json`, le fichier contiendra le JSON au lieu du texte brut.

**Modèles (où les obtenir)**
- Modèles officiels/communautaires (ex: ggerganov/whisper.cpp) — télécharger manuellement et placer le `.bin` à côté du binaire, ex `./ggml-base.bin`.

Exemple de téléchargement rapide (HuggingFace, selon modèle choisi) :

```bash
wget -c -O ggml-base.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin
```

**Conseils pour améliorer la qualité**
- Augmenter `--beam-size` (p.ex. 8) pour moins d'erreurs de décodage mais plus lent.
- Fournir `--initial-prompt` contenant vocabulaire/domain-specific tokens.
- Ajuster `--temperature` si vous voulez des sorties plus « créatives » (par ex. 0.2).
- Utiliser des fichiers audio de bonne qualité (mono, 16 kHz ou sup) ; si non, le resampler interne convertit en 16 kHz.
- Si l'audio est bruyant, appliquer un pré-filtrage (réduction de bruit) avant transcription.

**Résolution de problèmes courants**
- `unknown channel count`: corrigé par lecture du buffer décodé dans le code (déduction des canaux).
- Modèle introuvable: vérifier le chemin `--model` et les permissions.
- Erreurs liées au resampler: tester avec `sr_in == 16_000` pour bypasser le resampling.

**Pour aller plus loin**
- Exposer options de resampling (chunk_size, sub_chunks) via CLI si vous avez des cas d'usage spécifiques.

---

Fichier: [docs/USAGE.md](docs/USAGE.md)
