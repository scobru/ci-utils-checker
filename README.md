# ci-utils-checker

Utility da riga di comando per verificare, catalogare e installare i tool CLI moderni (Rust, Go, TUI, monitoraggio, networking) su distribuzioni Debian / Ubuntu e derivate.

## 🚀 Quickstart

```bash
# Rendi eseguibile lo script
chmod +x ci-utils-checker.sh

# Esegui il check completo
./ci-utils-checker.sh
```

## 📦 Utility monitorate di default

| Categoria | Comandi |
|---|---|
| **Monitoraggio** | `btop`, `htop`, `glances` |
| **Processi & Benchmark** | `procs`, `hyperfine` |
| **Disco & File** | `duf`, `ncdu`, `gdu`, `dust` (`du-dust`) |
| **Ricerca & Navigazione** | `rg` (`ripgrep`), `fd` (`fd-find`), `fzf`, `zoxide` |
| **Testo, Dati & Diff** | `bat` (`batcat`), `eza`, `sd`, `jq`, `yq`, `delta` (`git-delta`) |
| **Rete & API** | `http` (`httpie`), `curlie`, `mtr`, `doggo` |
| **TUI, Git & Container** | `lazygit`, `lazydocker`, `gh`, `tmux`, `zellij` |
| **Automazione & Aiuto** | `just`, `fastfetch`, `tldr` |

## 🛠️ Comandi

```bash
./ci-utils-checker.sh               # Mostra tutte le utility (installate e mancanti)
./ci-utils-checker.sh installed     # Mostra solo quelle già installate
./ci-utils-checker.sh missing       # Mostra solo quelle mancanti con suggerimento apt
./ci-utils-checker.sh search <term> # Cerca per nome, categoria o descrizione
./ci-utils-checker.sh install       # Installa in batch i pacchetti apt mancanti
./ci-utils-checker.sh add           # Aggiunge una nuova utility personalizzata
./ci-utils-checker.sh edit          # Modifica la lista ~/.config/my_utilities.list
./ci-utils-checker.sh reset         # Ripristina la lista predefinita
```

## ⚙️ Configurazione

La configurazione viene salvata in `${XDG_CONFIG_HOME:-$HOME/.config}/my_utilities.list` con sintassi pipe-separated:

```text
Comando | Categoria | Descrizione | Pacchetto Apt (opzionale)
```

## 📄 Licenza

MIT
