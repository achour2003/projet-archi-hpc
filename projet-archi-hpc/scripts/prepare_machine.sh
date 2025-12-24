#!/bin/bash
# Script de préparation de la machine pour les expériences
# Projet Architecture des Processeurs Hautes Performances
# 
# Usage: sudo ./prepare_machine.sh [start|stop|status]

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Ce script doit être exécuté en tant que root (sudo)"
        exit 1
    fi
}

show_status() {
    echo "=== État actuel de la machine ==="
    echo ""
    
    # Gouverneur CPU
    echo "Gouverneur CPU actuel:"
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [[ -f "$cpu" ]]; then
            echo "  $(dirname $cpu | xargs basename): $(cat $cpu)"
        fi
    done
    echo ""
    
    # Fréquences CPU
    echo "Fréquences CPU (MHz):"
    grep "cpu MHz" /proc/cpuinfo | head -4
    echo ""
    
    # Turbo Boost (Intel)
    if [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
        turbo=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)
        if [[ "$turbo" == "1" ]]; then
            echo "Turbo Boost Intel: DÉSACTIVÉ"
        else
            echo "Turbo Boost Intel: ACTIVÉ"
        fi
    fi
    
    # Boost (AMD)
    if [[ -f /sys/devices/system/cpu/cpufreq/boost ]]; then
        boost=$(cat /sys/devices/system/cpu/cpufreq/boost)
        if [[ "$boost" == "0" ]]; then
            echo "AMD Boost: DÉSACTIVÉ"
        else
            echo "AMD Boost: ACTIVÉ"
        fi
    fi
    echo ""
    
    # Charge système
    echo "Charge système:"
    uptime
    echo ""
    
    # Processus actifs (top 5)
    echo "Top 5 processus CPU:"
    ps aux --sort=-%cpu | head -6
}

start_preparation() {
    echo "=== Préparation de la machine pour les benchmarks ==="
    echo ""
    
    # 1. Passage en mode performance
    echo "1. Configuration du gouverneur CPU en mode performance..."
    if command -v cpupower &> /dev/null; then
        cpupower frequency-set -g performance 2>/dev/null
        print_status "Gouverneur configuré via cpupower"
    else
        for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            if [[ -f "$gov" ]]; then
                echo "performance" > "$gov" 2>/dev/null
            fi
        done
        print_status "Gouverneur configuré manuellement"
    fi
    
    # 2. Désactivation du Turbo Boost (Intel)
    echo "2. Désactivation du Turbo Boost..."
    if [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
        echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null
        print_status "Turbo Boost Intel désactivé"
    elif [[ -f /sys/devices/system/cpu/cpufreq/boost ]]; then
        echo 0 > /sys/devices/system/cpu/cpufreq/boost 2>/dev/null
        print_status "AMD Boost désactivé"
    else
        print_warning "Contrôle du Turbo Boost non disponible"
    fi
    
    # 3. Recommandations
    echo ""
    echo "3. Recommandations supplémentaires:"
    echo "   - Fermez toutes les applications graphiques"
    echo "   - Utilisez un TTY (Ctrl+Alt+F3) pour les expériences"
    echo "   - Exécutez vos benchmarks avec: taskset -c 0 ./benchmark"
    echo ""
    
    # 4. Services optionnels à arrêter
    echo "4. Services pouvant être arrêtés (optionnel):"
    services="bluetooth cups avahi-daemon snapd"
    for svc in $services; do
        if systemctl is-active --quiet $svc 2>/dev/null; then
            echo "   - $svc (actif) : sudo systemctl stop $svc"
        fi
    done
    echo ""
    
    print_status "Machine prête pour les benchmarks"
}

stop_preparation() {
    echo "=== Restauration de la configuration normale ==="
    echo ""
    
    # 1. Retour en mode ondemand/powersave
    echo "1. Restauration du gouverneur CPU..."
    if command -v cpupower &> /dev/null; then
        cpupower frequency-set -g ondemand 2>/dev/null || \
        cpupower frequency-set -g powersave 2>/dev/null
        print_status "Gouverneur restauré via cpupower"
    else
        for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            if [[ -f "$gov" ]]; then
                echo "ondemand" > "$gov" 2>/dev/null || \
                echo "powersave" > "$gov" 2>/dev/null
            fi
        done
        print_status "Gouverneur restauré manuellement"
    fi
    
    # 2. Réactivation du Turbo Boost
    echo "2. Réactivation du Turbo Boost..."
    if [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
        echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null
        print_status "Turbo Boost Intel réactivé"
    elif [[ -f /sys/devices/system/cpu/cpufreq/boost ]]; then
        echo 1 > /sys/devices/system/cpu/cpufreq/boost 2>/dev/null
        print_status "AMD Boost réactivé"
    fi
    
    echo ""
    print_status "Configuration normale restaurée"
}

# Main
case "${1:-status}" in
    start)
        check_root
        start_preparation
        ;;
    stop)
        check_root
        stop_preparation
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 [start|stop|status]"
        echo ""
        echo "  start  - Prépare la machine pour les benchmarks"
        echo "  stop   - Restaure la configuration normale"
        echo "  status - Affiche l'état actuel (par défaut)"
        exit 1
        ;;
esac
