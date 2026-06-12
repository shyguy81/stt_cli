# stt_cli — Transcription Whisper depuis .m4a (Rust)

Petit CLI Rust pour :
- lire des fichiers **.m4a** (AAC) avec **Symphonia**
- convertir en **mono f32**
- rééchantillonner en **16 kHz** avec **rubato**
- transcrire avec **whisper-rs** (backend whisper.cpp)

---

## Prérequis (Ubuntu)

```bash
sudo apt update
sudo apt install -y cmake build-essential pkg-config clang libclang-dev
```

- `cmake` est nécessaire pour compiler le code C/C++ embarqué (whisper.cpp).
- `libclang-dev` est requis car `whisper-rs-sys` utilise `bindgen`.

## Installation & build

Construire en release :

```bash
cargo build --release
```

## Modèle Whisper (ggml)

Vous devez fournir un fichier modèle compatible whisper.cpp, par exemple : `ggml-base.bin`, `ggml-small.bin`, `ggml-tiny.bin`.

Exemple d'arborescence :

```
models/
  ggml-base.bin
audio/
  sample.m4a
```

## Utilisation

Exemple de commande :

```bash
./target/release/stt_cli \
  --model ./models/ggml-base.bin \
  --m4a ./audio/sample.m4a \
  --lang fr
```

Options principales :
- `--model <path>` : chemin vers le fichier ggml
- `--m4a <path>` : fichier audio d'entrée (.m4a / AAC)
- `--lang <code>` : code langue (fr, en, ...). Chaîne vide => détection automatique
- `--threads <n>` : nombre de threads pour Whisper (0 = valeur par défaut de la lib)
- `--json` : sortie structurée pour automatisation / LLM
- `--gpu` et `--gpu-device <n>` : inférence GPU si le binaire est compilé avec un backend GPU

Exemple avec threads :

```bash
./target/release/stt_cli --model ./models/ggml-base.bin --m4a ./audio/sample.m4a --lang en --threads 8
```

Installer le binaire pour l'utilisateur courant :

```bash
bash scripts/install_user.sh
```

Compiler et installer avec CUDA :

```bash
bash scripts/install_user.sh --features cuda
```

## Sortie

Le programme affiche la transcription, segment par segment (une ligne par segment) sur stdout.

Avec `--json`, il produit un objet contenant `text`, `segments[]` avec timestamps en millisecondes, et `metadata`.

## Notes techniques

- L'entrée est décodée en `Vec<f32>` mono.
- Le rééchantillonnage est effectué vers 16 kHz (format attendu par Whisper).
- Les timestamps (début/fin) sont disponibles via `state.get_segment(i)` si vous voulez les récupérer.

Architecture & flux (rappels) :
- Décodage : `src/main.rs::decode_m4a_to_f32_mono` (Symphonia)
- Resampling : `src/main.rs::resample_to_16k_mono` (rubato::FftFixedIn)
- Transcription : initialisation de `whisper-rs` dans `main()` puis `state.full(...)` et `state.full_get_segment_text(i)`.

## Dépannage

1) Erreur bindgen / libclang introuvable

Vérifier la présence de libclang :

```bash
ls -l /usr/lib/llvm-*/lib/libclang.so*
export LIBCLANG_PATH=/usr/lib/llvm-14/lib  # ajuster selon votre version
cargo clean && cargo build --release
```

2) cmake manquant

```bash
sudo apt install -y cmake
cargo clean && cargo build --release
```

3) Impossible de décoder l'audio

Vérifiez que le `.m4a` est bien encodé en AAC (ou qu'un codec supporté par Symphonia est présent).

Vérification rapide :

```bash
ffprobe -hide_banner ./audio/sample.m4a
```

## Tests & validation

Il n'y a pas de suite de tests automatisés dans le projet. Pour valider vos modifications localement, utilisez un petit fichier `audio.m4a` et un modèle ggml.

## Améliorations fréquentes

- Exposer des options de resampling / performance (taille de buffer, GPU flag) via la CLI.
- Ajouter du logging (`log` + `env_logger`) et remplacer les `println!` par `info!`/`debug!`.

---

Si vous voulez, j'ajoute une option pour écrire la sortie en JSON ou j'ajoute des exemples d'utilisation supplémentaires.
