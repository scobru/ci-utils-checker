#!/bin/sh
# ci-utils-checker: Modern CLI & System utilities checker
# Pure POSIX /bin/sh compatible (works on dash, bash, zsh, ash)

set -e

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/my_utilities.list"

# Terminal colors (POSIX printf %b)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Default configuration template
generate_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat << 'EOF' > "$CONFIG_FILE"
# Formato: Comando | Categoria | Descrizione | Pacchetto Apt (opzionale)
rg | Ricerca | Ripgrep: ricerca ricorsiva velocissima di testo | ripgrep
fd | Ricerca | Alternativa semplice e intuitiva a find | fd-find
fzf | Ricerca | Interactive Fuzzy Finder per filtrare liste e comandi | fzf
bat | File / Nav | Alternativa a cat con syntax highlighting e git | bat
eza | File / Nav | Alternativa moderna a ls con colori, icone e tree | eza
zoxide | File / Nav | Navigatore directory intelligente basato su frecency | zoxide
jq | Dati | Processore e formattatore a riga di comando per JSON | jq
btop | Monitoraggio | Monitor di sistema grafico avanzato e moderno | btop
dust | Disco | Grafico ad albero dell'occupazione del disco in Rust | du-dust
ncdu | Disco | Analizzatore interattivo di spazio su disco ncurses | ncdu
lazygit | Git / Dev | Interfaccia TUI completa per Git | lazygit
gh | Git / Dev | GitHub CLI ufficiale per repo, PR e issue | gh
delta | Git / Dev | Pager syntax-highlighting per git, diff e grep | git-delta
tmux | Terminale | Terminal multiplexer per sessioni multiple persistenti | tmux
just | Automazione | Command runner moderno, alternativa pulita a make | just
tldr | Aiuto | Pagine man semplificate e ricche di esempi pratici | tldr
EOF
}

# Ensure config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    generate_config
    printf "%bCreato file di configurazione in:%b %s\n" "$GREEN" "$NC" "$CONFIG_FILE"
fi

# POSIX trim helper
trim() {
    printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

# Check command existence and common Debian/Ubuntu alias names
check_installed() {
    _cmd="$1"

    if command -v "$_cmd" >/dev/null 2>&1; then
        return 0
    fi

    case "$_cmd" in
        bat|batcat)       command -v bat >/dev/null 2>&1 || command -v batcat >/dev/null 2>&1 ;;
        fd|fdfind)        command -v fd >/dev/null 2>&1 || command -v fdfind >/dev/null 2>&1 ;;
        rg|ripgrep)       command -v rg >/dev/null 2>&1 || command -v ripgrep >/dev/null 2>&1 ;;
        http|httpie)      command -v http >/dev/null 2>&1 || command -v httpie >/dev/null 2>&1 ;;
        tldr|tealdeer)    command -v tldr >/dev/null 2>&1 || command -v tealdeer >/dev/null 2>&1 ;;
        dust|du-dust)     command -v dust >/dev/null 2>&1 || command -v du-dust >/dev/null 2>&1 ;;
        delta|git-delta)  command -v delta >/dev/null 2>&1 || command -v git-delta >/dev/null 2>&1 ;;
        btm|bottom)       command -v btm >/dev/null 2>&1 || command -v bottom >/dev/null 2>&1 ;;
        *) return 1 ;;
    esac
}

print_header() {
    printf "%b---------------------------------------------------------------------------------------------------------%b\n" "${BOLD}${CYAN}" "$NC"
    printf "%b%-14s %-12s %-16s %-45s %-15s%b\n" "$BOLD" "STATO" "COMANDO" "CATEGORIA" "DESCRIZIONE" "PACCHETTO APT" "$NC"
    printf "%b---------------------------------------------------------------------------------------------------------%b\n" "${BOLD}${CYAN}" "$NC"
}

show_list() {
    filter_mode="$1" # all, installed, missing
    search_term="$2"

    print_header

    installed_count=0
    missing_count=0

    while IFS='|' read -r raw_cmd raw_cat raw_desc raw_pkg || [ -n "$raw_cmd" ]; do
        # Ignore comments and empty lines
        case "$raw_cmd" in
            ""|\#*) continue ;;
            *)
                # Also skip lines where stripped leading char is #
                first_char=$(printf '%s' "$raw_cmd" | sed 's/^[[:space:]]*//;s/\(.\).*/\1/')
                [ "$first_char" = "#" ] && continue
                ;;
        esac

        cmd=$(trim "$raw_cmd")
        cat=$(trim "$raw_cat")
        desc=$(trim "$raw_desc")
        pkg=$(trim "$raw_pkg")

        [ -z "$cmd" ] && continue

        if [ -n "$search_term" ]; then
            match_target="$cmd $cat $desc $pkg"
            if ! printf '%s' "$match_target" | grep -iq "$search_term"; then
                continue
            fi
        fi

        if check_installed "$cmd"; then
            installed_count=$((installed_count + 1))
            if [ "$filter_mode" != "missing" ]; then
                _display_pkg="${pkg:--}"
                printf "%b%-14s%b %b%-12s%b %-16s %-45s %-15s\n" "$GREEN" "[✔ OK]" "$NC" "$BOLD" "$cmd" "$NC" "[$cat]" "$desc" "$_display_pkg"
            fi
        else
            missing_count=$((missing_count + 1))
            if [ "$filter_mode" != "installed" ]; then
                _apt_info="${pkg:-n/d}"
                printf "%b%-14s%b %b%-12s%b %-16s %-45s %-15s\n" "$RED" "[✘ MANCA]" "$NC" "$BOLD" "$cmd" "$NC" "[$cat]" "$desc" "$_apt_info"
            fi
        fi
    done < "$CONFIG_FILE"

    printf "%b---------------------------------------------------------------------------------------------------------%b\n" "${BOLD}${CYAN}" "$NC"
    printf "Totale presenti: %b%d%b | Totale mancanti: %b%d%b\n" "$GREEN" "$installed_count" "$NC" "$RED" "$missing_count" "$NC"
}

# Install missing packages via apt
install_missing() {
    to_install=""

    while IFS='|' read -r raw_cmd raw_cat raw_desc raw_pkg || [ -n "$raw_cmd" ]; do
        case "$raw_cmd" in ""|\#*) continue ;; esac
        cmd=$(trim "$raw_cmd")
        pkg=$(trim "$raw_pkg")
        [ -z "$cmd" ] && continue

        if ! check_installed "$cmd" && [ -n "$pkg" ] && [ "$pkg" != "-" ]; then
            to_install="$to_install $pkg"
        fi
    done < "$CONFIG_FILE"

    to_install=$(trim "$to_install")

    if [ -z "$to_install" ]; then
        printf "%bNessun pacchetto apt da installare. Tutte le utility supportate sono presenti!%b\n" "$GREEN" "$NC"
        return 0
    fi

    printf "%bPacchetti apt da installare:%b %s\n" "$YELLOW" "$NC" "$to_install"
    printf "Vuoi procedere con l'installazione? (s/N) "
    read -r confirm
    case "$confirm" in
        [sSyY]*)
            sudo apt update && sudo apt install -y $to_install
            ;;
        *)
            echo "Operazione annullata."
            ;;
    esac
}

add_utility() {
    printf "%bAggiungi una nuova utility alla lista:%b\n" "$BOLD" "$NC"
    printf "Nome comando (es. htop): "
    read -r new_cmd
    printf "Categoria (es. Monitoraggio): "
    read -r new_cat
    printf "Descrizione (cosa fa): "
    read -r new_desc
    printf "Nome pacchetto apt per installare (opzionale): "
    read -r new_pkg

    new_cmd=$(trim "$new_cmd")
    new_desc=$(trim "$new_desc")
    new_cat=$(trim "$new_cat")
    new_pkg=$(trim "$new_pkg")

    if [ -n "$new_cmd" ] && [ -n "$new_desc" ]; then
        cat_val="${new_cat:-Generale}"
        printf "%s | %s | %s | %s\n" "$new_cmd" "$cat_val" "$new_desc" "$new_pkg" >> "$CONFIG_FILE"
        printf "%bUtility '%s' aggiunta con successo!%b\n" "$GREEN" "$new_cmd" "$NC"
    else
        printf "%bErrore: Nome comando e descrizione sono obbligatori.%b\n" "$RED" "$NC"
    fi
}

show_help() {
    printf "%bci-utils-checker%b — Verifica lo stato delle utility CLI essenziali\n\n" "$BOLD" "$NC"
    printf "%bUso:%b %s [opzione]\n\n" "$BOLD" "$NC" "$0"
    printf "Opzioni disponibili:\n"
    printf "  (nessuna)          Mostra tutte le utility (installate e mancanti)\n"
    printf "  installed          Filtra e mostra solo le utility installate\n"
    printf "  missing            Filtra e mostra solo le utility non installate\n"
    printf "  search <termine>   Cerca per comando, categoria o descrizione\n"
    printf "  install            Installa interattivamente tutti i pacchetti mancanti tramite apt\n"
    printf "  add                Aggiunge una nuova utility alla configurazione\n"
    printf "  edit               Apre la lista nell'editor (\$EDITOR o nano)\n"
    printf "  reset              Ripristina la configurazione di default\n"
    printf "  help               Mostra questa guida\n"
}

case "$1" in
    installed)        show_list "installed" ;;
    missing)          show_list "missing" ;;
    search)           show_list "all" "$2" ;;
    install)          install_missing ;;
    add)              add_utility ;;
    edit)             "${EDITOR:-nano}" "$CONFIG_FILE" ;;
    reset)            generate_config; printf "%bConfigurazione ripristinata con successo!%b\n" "$GREEN" "$NC" ;;
    help|-h|--help)   show_help ;;
    "")               show_list "all" ;;
    *)                printf "%bOpzione sconosciuta:%b %s\n" "$RED" "$NC" "$1"; show_help; exit 1 ;;
esac
