#!/bin/bash
# Script d'exécution de tous les benchmarks
# Projet Architecture des Processeurs Hautes Performances
#
# Ce script compile et exécute tous les exercices du projet

set -e  # Arrêter en cas d'erreur

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[i]${NC} $1"
}

# Configuration
CPU_TO_USE=0  # CPU sur lequel exécuter les benchmarks
CPU_MHZ=${CPU_MHZ:-3000}  # Fréquence CPU par défaut

# Vérification des prérequis
check_prerequisites() {
    print_header "Vérification des prérequis"
    
    local missing=0
    for tool in gcc gnuplot make; do
        if command -v $tool &> /dev/null; then
            print_success "$tool installé"
        else
            print_error "$tool manquant"
            missing=1
        fi
    done
    
    if [[ $missing -eq 1 ]]; then
        echo "Installez les outils : sudo apt install build-essential gnuplot"
        exit 1
    fi
    
    if ! command -v taskset &> /dev/null; then
        print_info "taskset non disponible"
        TASKSET_CMD=""
    else
        TASKSET_CMD="taskset -c $CPU_TO_USE"
        print_success "Utilisation du CPU $CPU_TO_USE via taskset"
    fi
}

# Exercice 1
run_exercice1() {
    print_header "Exercice 1: Détection des tailles de cache"
    cd "$PROJECT_DIR/exercice1"
    
    print_info "Nettoyage et Compilation..."
    make clean 2>/dev/null || true
    make
    
    print_info "Exécution et génération du graphe..."
    $TASKSET_CMD ./cache_benchmark > resultats.csv 2>/dev/null
    gnuplot plot_cache.gp 2>/dev/null || print_error "Erreur gnuplot"
    
    if [[ -f cache_latency.pdf ]]; then
        print_success "Généré : cache_latency.pdf"
    fi
    cd "$PROJECT_DIR"
}

# Exercice 2
run_exercice2() {
    print_header "Exercice 2: Bande passante mémoire"
    cd "$PROJECT_DIR/exercice2"
    
    print_info "Nettoyage et Compilation..."
    make clean 2>/dev/null || true
    make
    
    print_info "Exécution et génération des graphes..."
    $TASKSET_CMD ./bandwidth_benchmark > resultats.csv 2>/dev/null
    gnuplot plot_bandwidth.gp 2>/dev/null || print_error "Erreur gnuplot"
    
    if [[ -f bandwidth.pdf && -f bandwidth_seq.pdf ]]; then
        print_success "Générés : bandwidth.pdf et bandwidth_seq.pdf"
    fi
    cd "$PROJECT_DIR"
}

# Exercice 5 (Version Améliorée via Makefile)
run_exercice5() {
    print_header "Exercice 5: Calibrator"
    cd "$PROJECT_DIR/exercice5"
    
    # 1. Détection de fréquence
    if [[ -f /proc/cpuinfo ]]; then
        detected_mhz=$(grep "cpu MHz" /proc/cpuinfo | head -1 | awk '{print int($4)}')
        if [[ -n "$detected_mhz" && "$detected_mhz" -gt 0 ]]; then
            CPU_MHZ=$detected_mhz
            print_info "Fréquence détectée: $CPU_MHZ MHz"
        fi
    fi
    
    print_info "Lancement via Makefile (Compilation + Bench + Plot)..."
    
    # On délègue tout au Makefile qui sait quoi faire
    # On utilise taskset sur make pour que le processus fils (calibrator) en hérite
    if [ -n "$TASKSET_CMD" ]; then
        $TASKSET_CMD make benchmark MHZ=$CPU_MHZ
    else
        make benchmark MHZ=$CPU_MHZ
    fi

    # Vérification
    if [[ -f calibrator_results.pdf ]]; then
        print_success "Graphique généré : calibrator_results.pdf"
    else
        print_error "Le graphique n'a pas été généré."
    fi
    
    cd "$PROJECT_DIR"
}

# Génération des graphiques uniquement
generate_graphs() {
    print_header "Régénération des graphiques (Sans Benchmark)"
    
    # Ex 1
    if [[ -d "$PROJECT_DIR/exercice1" ]]; then
        cd "$PROJECT_DIR/exercice1" && gnuplot plot_cache.gp 2>/dev/null && print_success "PDF Ex1 OK" || print_error "Ex1 Fail"
    fi

    # Ex 2
    if [[ -d "$PROJECT_DIR/exercice2" ]]; then
        cd "$PROJECT_DIR/exercice2" && gnuplot plot_bandwidth.gp 2>/dev/null && print_success "PDF Ex2 OK" || print_error "Ex2 Fail"
    fi

    # Ex 5 (Via Makefile 'make plot')
    if [[ -d "$PROJECT_DIR/exercice5" ]]; then
        cd "$PROJECT_DIR/exercice5"
        make plot 2>/dev/null && print_success "PDF Ex5 OK" || print_error "Ex5 Fail (Données manquantes ?)"
    fi
    
    cd "$PROJECT_DIR"
}

# Création de l'archive
create_archive() {
    print_header "Création de l'archive finale"
    cd "$PROJECT_DIR"
    
    read -p "Entrez votre NOM: " nom
    read -p "Entrez votre Prénom: " prenom
    
    archive_name="Projet-${nom}-${prenom}.tar.gz"
    print_info "Création de $archive_name..."
    
    tar -czvf "$archive_name" exercice1/ exercice2/ exercice5/ rapport/ README.md system_info.txt 2>/dev/null
    
    print_success "Archive prête : $archive_name"
}

# Menu
show_menu() {
    echo ""
    echo "1) Tout exécuter (Benchmarks + Graphes)"
    echo "2) Exercice 1 (Caches)"
    echo "3) Exercice 2 (Bande passante)"
    echo "4) Exercice 5 (Calibrator)"
    echo "5) Collecter infos système"
    echo "6) Créer l'archive"
    echo "7) Tout faire"
    echo "8) Régénérer uniquement les graphiques"
    echo "q) Quitter"
    echo ""
    read -p "Votre choix: " choice
    
    case $choice in
    1) run_exercice1; run_exercice2; run_exercice5 ;;
    2) run_exercice1 ;;
    3) run_exercice2 ;;
    4) run_exercice5 ;;
    5) ./scripts/collect_info.sh system_info.txt ;;
    6) create_archive ;;
    7) run_exercice1; run_exercice2; run_exercice5; ./scripts/collect_info.sh system_info.txt; create_archive ;;
    8) generate_graphs ;;
    q|Q) exit 0 ;;
    *) show_menu ;;
    esac
}

# Main
print_header "Architecture HPC - Manager"
check_prerequisites

if [[ $# -gt 0 ]]; then
    case $1 in
    all) run_exercice1; run_exercice2; run_exercice5 ;;
    ex5) run_exercice5 ;;
    graphs) generate_graphs ;;
    archive) create_archive ;;
    *) show_menu ;;
    esac
else
    show_menu
fi

print_header "Opération terminée"
