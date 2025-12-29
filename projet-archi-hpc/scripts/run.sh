#!/bin/bash
#
# Script pour exécuter les benchmarks dans des conditions optimales
# DOIT ÊTRE EXÉCUTÉ EN TANT QUE ROOT (sudo)
#

echo "=============================================="
echo "  PRÉPARATION MACHINE POUR BENCHMARKS"
echo "=============================================="
echo ""

# Vérifier si root
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  Ce script doit être exécuté avec sudo !"
    echo "   Usage: sudo $0"
    exit 1
fi

# Sauvegarder l'utilisateur original
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(eval echo ~$REAL_USER)

echo "[1/5] Configuration du gouverneur CPU en mode PERFORMANCE..."
cpupower frequency-set -g performance > /dev/null 2>&1
sleep 2

# Vérifier
GOV=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
echo "      Gouverneur actuel: $GOV"

echo ""
echo "[2/5] Désactivation du Turbo Boost..."
# Intel
if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
    echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo
    echo "      Turbo Boost Intel désactivé"
# AMD
elif [ -f /sys/devices/system/cpu/cpufreq/boost ]; then
    echo 0 > /sys/devices/system/cpu/cpufreq/boost
    echo "      Turbo Boost AMD désactivé"
else
    echo "      ⚠️ Impossible de désactiver le Turbo"
fi

echo ""
echo "[3/5] Attente de stabilisation de la fréquence..."
sleep 3

# Afficher les fréquences
echo "      Fréquences CPU actuelles:"
cat /proc/cpuinfo | grep "cpu MHz" | head -4 | while read line; do
    echo "        $line"
done

echo ""
echo "[4/5] Compilation du benchmark amélioré..."
cd "$REAL_HOME/Bureau/M1/Archi/projet/src/projet-archi-hpc/exercice1" 2>/dev/null || \
cd "$(dirname "$0")/../exercice1" 2>/dev/null || \
cd /tmp

# Copier le nouveau fichier si présent
if [ -f "$REAL_HOME/Téléchargements/cache_benchmark_v2.c" ]; then
    cp "$REAL_HOME/Téléchargements/cache_benchmark_v2.c" ./cache_benchmark_v2.c
fi

if [ -f "cache_benchmark_v2.c" ]; then
    gcc -O2 -Wall -march=native -o cache_benchmark_v2 cache_benchmark_v2.c -lrt
    echo "      Compilation réussie"
else
    echo "      ⚠️ Fichier cache_benchmark_v2.c non trouvé"
    echo "      Téléchargez-le et placez-le dans exercice1/"
fi

echo ""
echo "[5/5] Exécution du benchmark..."
echo ""
echo "=============================================="
echo "  RÉSULTATS EXERCICE 1 (Pointer Chasing)"
echo "=============================================="
echo ""

if [ -f "./cache_benchmark_v2" ]; then
    # Exécuter sur CPU 0 uniquement
    taskset -c 0 ./cache_benchmark_v2 > resultats_v2.csv
    
    echo ""
    echo "Résultats sauvegardés dans: resultats_v2.csv"
    echo ""
    echo "Aperçu des résultats:"
    echo "---------------------"
    cat resultats_v2.csv | grep -v "^#" | head -20
fi

echo ""
echo "=============================================="
echo "  RESTAURATION DE LA CONFIGURATION"
echo "=============================================="

# Restaurer powersave
cpupower frequency-set -g powersave > /dev/null 2>&1

# Réactiver turbo
if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
    echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo
fi

echo "Configuration restaurée."
echo ""
