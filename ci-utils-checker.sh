#!/usr/bin/env bash
# ci-utils-checker: Modern CLI & System utilities checker
# ponytail: pure bash string manipulation, zero external dependencies

set -eo pipefail

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/my_utilities.list"

# Terminal colors
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
if [[ ! -f "$CONFIG_FILE" ]]; then
    generate_config
    echo -e "${GREEN}Creato file di configurazione in:${NC} $CONFIG_FILE"
fi

# Trim helper using pure bash parameter expansion
# ponytail: avoids spawning subshells with xargs for each column
trim() {
    local val="$1"
    val="${val#"${val%%[![:space:]]*}"}"
    val="${val%"${val##*[![:space:]]}"}"
    printf '%s' "$val"
}

# Check command existence and common Debian/Ubuntu alias names
check_installed() {
    local cmd="$1"

    if command -v "$cmd" &>/dev/null; then
        return 0
    fi

    case "$cmd" in
        bat|batcat)       command -v bat &>/dev/null || command -v batcat &>/dev/null ;;
        fd|fdfind)        command -v fd &>/dev/null || command -v fdfind &>/dev/null ;;
        rg|ripgrep)       command -v rg &>/dev/null || command -v ripgrep &>/dev/null ;;
        http|httpie)      command -v http &>/dev/null || command -v httpie &>/dev/null ;;
        tldr|tealdeer)    command -v tldr &>/dev/null || command -v tealdeer &>/dev/null ;;
        dust|du-dust)     command -v dust &>/dev/null || command -v du-dust &>/dev/null ;;
        delta|git-delta)  command -v delta &>/dev/null || command -v git-delta &>/dev/null ;;
        btm|bottom)       command -v btm &>/dev/null || command -v bottom &>/dev/null ;;
        *) return 1 ;;
    esac
}

print_header() {
    echo -e "${BOLD}${CYAN}---------------------------------------------------------------------------------------------------------${NC}"
    printf "${BOLD}%-14s %-12s %-16s %-45s %-15s${NC}\n" "STATO" "COMANDO" "CATEGORIA" "DESCRIZIONE" "PACCHETTO APT"
    echo -e "${BOLD}${CYAN}---------------------------------------------------------------------------------------------------------${NC}"
}

show_list() {
    local filter_mode="$1" # all, installed, missing
    local search_term="$2"

    print_header

    local installed_count=0
    local missing_count=0

    while IFS='|' read -r raw_cmd raw_cat raw_desc raw_pkg || [[ -n "$raw_cmd" ]]; do
        [[ -z "$raw_cmd" || "$raw_cmd" =~ ^[[:space:]]*# ]] && continue

        local cmd cat desc pkg
        cmd=$(trim "$raw_cmd")
        cat=$(trim "$raw_cat")
        desc=$(trim "$raw_desc")
        pkg=$(trim "$raw_pkg")

        if [[ -n "$search_term" ]]; then
            local match_target="$cmd $cat $desc $pkg"
            if ! echo "$match_target" | grep -iq "$search_term"; then
                continue
            fi
        fi

        if check_installed "$cmd"; then
            ((installed_count++))
            if [[ "$filter_mode" != "missing" ]]; then
                printf "${GREEN}%-14s${NC} ${BOLD}%-12s${NC} %-16s %-45s %-15s\n" "[✔ OK]" "$cmd" "[$cat]" "$desc" "${pkg:--}"
            fi
        else
            ((missing_count++))
            if [[ "$filter_mode" != "installed" ]]; then
                local apt_info="${pkg:-n/d}"
                printf "${RED}%-14s${NC} ${BOLD}%-12s${NC} %-16s %-45s %-15s\n" "[✘ MANCA]" "$cmd" "[$cat]" "$desc" "$apt_info"
            fi
        fi
    done < "$CONFIG_FILE"

    echo -e "${BOLD}${CYAN}---------------------------------------------------------------------------------------------------------${NC}"
    echo -e "Totale presenti: ${GREEN}$installed_count${NC} | Totale mancanti: ${RED}$missing_count${NC}"
}

# Install missing packages via apt
install_missing() {
    local to_install=()

    while IFS='|' read -r raw_cmd raw_cat raw_desc raw_pkg || [[ -n "$raw_cmd" ]]; do
        [[ -z "$raw_cmd" || "$raw_cmd" =~ ^[[:space:]]*# ]] && continue
        local cmd pkg
        cmd=$(trim "$raw_cmd")
        pkg=$(trim "$raw_pkg")

        if ! check_installed "$cmd" && [[ -n "$pkg" && "$pkg" != "-" ]]; then
            to_install+=("$pkg")
        fi
    done < "$CONFIG_FILE"

    if [[ ${#to_install[@]} -eq 0 ]]; then
        echo -e "${GREEN}Nessun pacchetto apt da installare. Tutte le utility supportate sono presenti!${NC}"
        return 0
    fi

    echo -e "${YELLOW}Pacchetti apt da installare:${NC} ${to_install[*]}"
    read -rp "Vuoi procedere con l'installazione? (s/N) " confirm
    if [[ "$confirm" =~ ^[sSyY]$ ]]; then
        sudo apt update && sudo apt install -y "${to_install[@]}"
    else
        echo "Operazione annullata."
    fi
}

add_utility() {
    echo -e "${BOLD}Aggiungi una nuova utility alla lista:${NC}"
    read -rp "Nome comando (es. htop): " new_cmd
    read -rp "Categoria (es. Monitoraggio): " new_cat
    read -rp "Descrizione (cosa fa): " new_desc
    read -rp "Nome pacchetto apt per installare (opzionale): " new_pkg

    new_cmd=$(trim "$new_cmd")
    new_desc=$(trim "$new_desc")

    if [[ -n "$new_cmd" && -n "$new_desc" ]]; then
        echo "$new_cmd | ${new_cat:-Generale} | $new_desc | ${new_pkg:-}" >> "$CONFIG_FILE"
        echo -e "${GREEN}Utility '$new_cmd' aggiunta con successo!${NC}"
    else
        echo -e "${RED}Errore: Nome comando e descrizione sono obbligatori.${NC}"
    fi
}

show_help() {
    echo -e "${BOLD}ci-utils-checker${NC} — Verifica lo stato delle utility CLI essenziali"
    echo ""
    echo -e "${BOLD}Uso:${NC} $0 [opzione]"
    echo ""
    echo "Opzioni disponibili:"
    echo "  (nessuna)          Mostra tutte le utility (installate e mancanti)"
    echo "  installed          Filtra e mostra solo le utility installate"
    echo "  missing            Filtra e mostra solo le utility non installate"
    echo "  search <termine>   Cerca per comando, categoria o descrizione"
    echo "  install            Installa interattivamente tutti i pacchetti mancanti tramite apt"
    echo "  add                Aggiunge una nuova utility alla configurazione"
    echo "  edit               Apre la lista nell'editor (\$EDITOR o nano)"
    echo "  reset              Ripristina la configurazione di default"
    echo "  help               Mostra questa guida"
}

case "$1" in
    installed)        show_list "installed" ;;
    missing)          show_list "missing" ;;
    search)           show_list "all" "$2" ;;
    install)          install_missing ;;
    add)              add_utility ;;
    edit)             "${EDITOR:-nano}" "$CONFIG_FILE" ;;
    reset)            generate_config; echo -e "${GREEN}Configurazione ripristinata con successo!${NC}" ;;
    help|-h|--help)   show_help ;;
    "")               show_list "all" ;;
    *)                echo -e "${RED}Opzione sconosciuta:${NC} $1"; show_help; exit 1 ;;
esac
