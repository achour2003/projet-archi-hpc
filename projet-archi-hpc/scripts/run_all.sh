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
CPU_MHZ=${CPU_MHZ:-3000}  # Fréquence CPU pour Calibrator (à ajuster)

# Vérification des prérequis
check_prerequisites() {
    print_header "Vérification des prérequis"
    
    local missing=0
    
    for tool in gcc gnuplot; do
        if command -v $tool &> /dev/null; then
            print_success "$tool installé"
        else
            print_error "$tool manquant"
            missing=1
        fi
    done
    
    if [[ $missing -eq 1 ]]; then
        echo ""
        echo "Installez les outils manquants avec:"
        echo "  sudo apt install build-essential gnuplot"
        exit 1
    fi
    
    # Vérifier taskset
    if ! command -v taskset &> /dev/null; then
        print_info "taskset non disponible - les benchmarks ne seront pas fixés à un CPU"
        TASKSET_CMD=""
    else
        TASKSET_CMD="taskset -c $CPU_TO_USE"
        print_success "taskset disponible - utilisation du CPU $CPU_TO_USE"
    fi
}

# Exercice 1
run_exercice1() {
    print_header "Exercice 1: Détection des tailles de cache"
    
    cd "$PROJECT_DIR/exercice1"
    
    print_info "Compilation..."
    make clean 2>/dev/null || true
    make
    print_success "Compilation réussie"
    
    print_info "Exécution du benchmark..."
    $TASKSET_CMD ./cache_benchmark > resultats.csv 2>/dev/null
    print_success "Données collectées dans resultats.csv"
    
    print_info "Génération du graphique..."
    gnuplot plot_cache.gp 2>/dev/null || print_error "Erreur gnuplot (non bloquant)"
    
    if [[ -f cache_latency.pdf ]]; then
        print_success "Graphique généré: cache_latency.pdf"
    fi
    
    cd "$PROJECT_DIR"
}

# Exercice 2
run_exercice2() {
    print_header "Exercice 2: Bande passante mémoire"
    
    cd "$PROJECT_DIR/exercice2"
    
    print_info "Compilation..."
    make clean 2>/dev/null || true
    make
    print_success "Compilation réussie"
    
    print_info "Exécution du benchmark..."
    $TASKSET_CMD ./bandwidth_benchmark > resultats.csv 2>/dev/null
    print_success "Données collectées dans resultats.csv"
    
    print_info "Génération du graphique..."
    gnuplot plot_bandwidth.gp 2>/dev/null || print_error "Erreur gnuplot (non bloquant)"
    
    if [[ -f bandwidth.pdf ]]; then
        print_success "Graphique généré: bandwidth.pdf"
    fi
    
    cd "$PROJECT_DIR"
}

# Exercice 5
run_exercice5() {
    print_header "Exercice 5: Calibrator"
    
    cd "$PROJECT_DIR/exercice5"
    
    print_info "Compilation..."
    make clean 2>/dev/null || true
    make
    print_success "Compilation réussie"
    
    # Détection automatique de la fréquence si possible
    if [[ -f /proc/cpuinfo ]]; then
        detected_mhz=$(grep "cpu MHz" /proc/cpuinfo | head -1 | awk '{print int($4)}')
        if [[ -n "$detected_mhz" && "$detected_mhz" -gt 0 ]]; then
            CPU_MHZ=$detected_mhz
            print_info "Fréquence détectée: $CPU_MHZ MHz"
        fi
    fi
    
    print_info "Exécution de Calibrator (CPU_MHZ=$CPU_MHZ, taille=64M)..."
    $TASKSET_CMD ./calibrator $CPU_MHZ 64M results 2>/dev/null
    print_success "Calibrator terminé"
    
    print_info "Génération des graphiques..."
    for gp_file in results*.gp; do
        if [[ -f "$gp_file" ]]; then
            gnuplot "$gp_file" 2>/dev/null || true
        fi
    done
    
    # Liste des fichiers générés
    print_success "Fichiers générés:"
    ls -la results* 2>/dev/null | while read line; do
        echo "  $line"
    done
    
    cd "$PROJECT_DIR"
}

# Collecte des infos système
collect_system_info() {
    print_header "Collecte des informations système"
    
    cd "$PROJECT_DIR"
    chmod +x scripts/collect_info.sh
    ./scripts/collect_info.sh system_info.txt
    
    print_success "Informations sauvegardées dans system_info.txt"
}

# Création de l'archive finale
create_archive() {
    print_header "Création de l'archive finale"
    
    cd "$PROJECT_DIR"
    
    # Demander le nom
    read -p "Entrez votre NOM: " nom
    read -p "Entrez votre Prénom: " prenom
    
    archive_name="Projet-${nom}-${prenom}.tar.gz"
    
    print_info "Création de $archive_name..."
    
    tar -czvf "$archive_name" \
        exercice1/ \
        exercice2/ \
        exercice5/ \
        rapport/ \
        README.md \
        system_info.txt \
        2>/dev/null
    
    print_success "Archive créée: $archive_name"
    echo ""
    echo "Taille de l'archive: $(du -h "$archive_name" | cut -f1)"
}

# Menu principal
show_menu() {
    echo ""
    echo "Que souhaitez-vous faire ?"
    echo ""
    echo "  1) Exécuter tous les exercices"
    echo "  2) Exercice 1 uniquement (caches)"
    echo "  3) Exercice 2 uniquement (bande passante)"
    echo "  4) Exercice 5 uniquement (Calibrator)"
    echo "  5) Collecter les infos système"
    echo "  6) Créer l'archive finale"
    echo "  7) Tout faire (1 + 5 + 6)"
    echo "  q) Quitter"
    echo ""
    read -p "Votre choix: " choice
    
    case $choice in
        1)
            run_exercice1
            run_exercice2
            run_exercice5
            ;;
        2)
            run_exercice1
            ;;
        3)
            run_exercice2
            ;;
        4)
            run_exercice5
            ;;
        5)
            collect_system_info
            ;;
        6)
            create_archive
            ;;
        7)
            run_exercice1
            run_exercice2
            run_exercice5
            collect_system_info
            create_archive
            ;;
        q|Q)
            echo "Au revoir!"
            exit 0
            ;;
        *)
            print_error "Choix invalide"
            show_menu
            ;;
    esac
}

# Main
print_header "Projet Architecture HPC - Script d'exécution"

check_prerequisites

# Si argument passé, exécuter directement
if [[ $# -gt 0 ]]; then
    case $1 in
        all) 
            run_exercice1
            run_exercice2
            run_exercice5
            ;;
        ex1) run_exercice1 ;;
        ex2) run_exercice2 ;;
        ex5) run_exercice5 ;;
        info) collect_system_info ;;
        archive) create_archive ;;
        *)
            echo "Usage: $0 [all|ex1|ex2|ex5|info|archive]"
            exit 1
            ;;
    esac
else
    show_menu
fi

print_header "Terminé!"
