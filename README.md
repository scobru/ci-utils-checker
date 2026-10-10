# ci-utils-checker

CLI checker rapido per verificare, gestire e installare i tool moderni essenziali da terminale (Rust/Go, TUI, search, monitoring) su Debian / Ubuntu.

Focalizzato sui **16 tool core** irrinunciabili (nessun doppione superfluo).

## 🚀 Quickstart

```bash
chmod +x ci-utils-checker.sh
./ci-utils-checker.sh
```

## 📦 I 16 Tool Essenziali

| Categoria | Comandi | Pacchetto Apt | Descrizione |
|---|---|---|---|
| **Ricerca** | `rg` | `ripgrep` | Ricerca ricorsiva fulminea nel codice |
| | `fd` | `fd-find` | Alternativa ergonomica e veloce a `find` |
| | `fzf` | `fzf` | Fuzzy finder interattivo |
| **File / Nav** | `bat` | `bat` (`batcat`) | `cat` con syntax highlight e git |
| | `eza` | `eza` | `ls` moderno con colori, icone e tree |
| | `zoxide` | `zoxide` | Navigatore directory intelligente con memoria |
| **Dati** | `jq` | `jq` | Parser e formattatore JSON CLI |
| **Monitor / Disco** | `btop` | `btop` | Monitor di sistema TUI moderno |
| | `dust` | `du-dust` | Grafico ad albero dell'occupazione disco |
| | `ncdu` | `ncdu` | Analizzatore interattivo di spazio disco |
| **Git / Dev** | `lazygit` | `lazygit` | TUI completa per Git |
| | `gh` | `gh` | GitHub CLI ufficiale |
| | `delta` | `git-delta` | Syntax-highlighting pager per `git diff` |
| **Terminale / Task** | `tmux` | `tmux` | Terminal multiplexer |
| | `just` | `just` | Command runner moderno (alternativa a `make`) |
| | `tldr` | `tldr` | Cheat-sheet e pagine man semplificate con esempi |

## 🛠️ Comandi

```bash
./ci-utils-checker.sh               # Mostra stato di tutte le utility
./ci-utils-checker.sh installed     # Mostra solo quelle installate
./ci-utils-checker.sh missing       # Mostra solo quelle mancanti
./ci-utils-checker.sh search <term> # Cerca per nome, categoria o descrizione
./ci-utils-checker.sh install       # Installa in batch i pacchetti apt mancanti
./ci-utils-checker.sh add           # Aggiunge una nuova utility personalizzata
./ci-utils-checker.sh edit          # Modifica la lista ~/.config/my_utilities.list
./ci-utils-checker.sh reset         # Ripristina la lista predefinita (16 tool)
```

## ⚙️ Configurazione

Salvata in `${XDG_CONFIG_HOME:-$HOME/.config}/my_utilities.list`:
```text
Comando | Categoria | Descrizione | Pacchetto Apt (opzionale)
```

## 📄 Licenza

MIT
