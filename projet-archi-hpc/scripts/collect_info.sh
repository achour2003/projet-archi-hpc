#!/bin/bash
# Script de collecte des informations système
# Projet Architecture des Processeurs Hautes Performances
#
# Ce script génère un fichier avec toutes les informations nécessaires
# pour la section "Environnement Expérimental" du rapport

OUTPUT_FILE="${1:-system_info.txt}"

echo "=== Collecte des informations système ===" | tee "$OUTPUT_FILE"
echo "Date: $(date)" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# Section 1 : Informations générales
echo "=============================================" | tee -a "$OUTPUT_FILE"
echo "1. INFORMATIONS GÉNÉRALES" | tee -a "$OUTPUT_FILE"
echo "=============================================" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

echo "Hostname: $(hostname)" | tee -a "$OUTPUT_FILE"
echo "Kernel: $(uname -r)" | tee -a "$OUTPUT_FILE"
echo "Architecture: $(uname -m)" | tee -a "$OUTPUT_FILE"

if [[ -f /etc/os-release ]]; then
    echo "" | tee -a "$OUTPUT_FILE"
    echo "Distribution:" | tee -a "$OUTPUT_FILE"
    grep -E "^(NAME|VERSION)=" /etc/os-release | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# Section 2 : Informations CPU
echo "=============================================" | tee -a "$OUTPUT_FILE"
echo "2. INFORMATIONS CPU (lscpu)" | tee -a "$OUTPUT_FILE"
echo "=============================================" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"
lscpu | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# Section 3 : Hiérarchie des caches
echo "=============================================" | tee -a "$OUTPUT_FILE"
echo "3. HIÉRARCHIE DES CACHES" | tee -a "$OUTPUT_FILE"
echo "=============================================" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

echo "--- Via getconf ---" | tee -a "$OUTPUT_FILE"
getconf -a 2>/dev/null | grep -i cache | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

echo "--- Via sysfs ---" | tee -a "$OUTPUT_FILE"
for cache_dir in /sys/devices/system/cpu/cpu0/cache/index*; do
    if [[ -d "$cache_dir" ]]; then
        echo "$(basename $cache_dir):" | tee -a "$OUTPUT_FILE"
        echo "  Level: $(cat $cache_dir/level 2>/dev/null)" | tee -a "$OUTPUT_FILE"
        echo "  Type: $(cat $cache_dir/type 2>/dev/null)" | tee -a "$OUTPUT_FILE"
        echo "  Size: $(cat $cache_dir/size 2>/dev/null)" | tee -a "$OUTPUT_FILE"
        echo "  Line size: $(cat $cache_dir/coherency_line_size 2>/dev/null) bytes" | tee -a "$OUTPUT_FILE"
        echo "  Associativity: $(cat $cache_dir/ways_of_associativity 2>/dev/null)-way" | tee -a "$OUTPUT_FILE"
        echo "  Sets: $(cat $cache_dir/number_of_sets 2>/dev/null)" | tee -a "$OUTPUT_FILE"
        echo "" | tee -a "$OUTPUT_FILE"
    fi
done

# Section 4 : Mémoire
echo "=============================================" | tee -a "$OUTPUT_FILE"
echo "4. MÉMOIRE" | tee -a "$OUTPUT_FILE"
echo "=============================================" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

echo "--- free -h ---" | tee -a "$OUTPUT_FILE"
free -h | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

echo "--- Taille de page ---" | tee -a "$OUTPUT_FILE"
echo "Page size: $(getconf PAGESIZE) bytes" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

echo "--- /proc/meminfo (extrait) ---" | tee -a "$OUTPUT_FILE"
grep -E "(MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal)" /proc/meminfo | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# Section 5 : Fréquences CPU
echo "=============================================" | tee -a "$OUTPUT_FILE"
echo "5. FRÉQUENCES CPU" | tee -a "$OUTPUT_FILE"
echo "=============================================" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

echo "--- Fréquences actuelles ---" | tee -a "$OUTPUT_FILE"
grep "cpu MHz" /proc/cpuinfo | head -4 | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

echo "--- Gouverneur CPU ---" | tee -a "$OUTPUT_FILE"
for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    if [[ -f "$gov" ]]; then
        echo "$(dirname $gov | xargs basename): $(cat $gov)" | tee -a "$OUTPUT_FILE"
    fi
done 2>/dev/null | head -4
echo "" | tee -a "$OUTPUT_FILE"

if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq ]]; then
    echo "Min freq: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq) kHz" | tee -a "$OUTPUT_FILE"
    echo "Max freq: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq) kHz" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# Section 6 : Compilateur
echo "=============================================" | tee -a "$OUTPUT_FILE"
echo "6. COMPILATEUR" | tee -a "$OUTPUT_FILE"
echo "=============================================" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

if command -v gcc &> /dev/null; then
    gcc --version | head -1 | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# Section 7 : Outils disponibles
echo "=============================================" | tee -a "$OUTPUT_FILE"
echo "7. OUTILS DISPONIBLES" | tee -a "$OUTPUT_FILE"
echo "=============================================" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

check_tool() {
    if command -v $1 &> /dev/null; then
        echo "$1: disponible ($(which $1))" | tee -a "$OUTPUT_FILE"
    else
        echo "$1: NON DISPONIBLE" | tee -a "$OUTPUT_FILE"
    fi
}

check_tool gnuplot
check_tool pdflatex
check_tool perf
check_tool cpupower
check_tool taskset
echo "" | tee -a "$OUTPUT_FILE"

# Section 8 : Résumé pour LaTeX
echo "=============================================" | tee -a "$OUTPUT_FILE"
echo "8. RÉSUMÉ POUR LE RAPPORT LATEX" | tee -a "$OUTPUT_FILE"
echo "=============================================" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

echo "Copiez-collez ces valeurs dans votre rapport :" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# Extraction des valeurs clés
model=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)
cores=$(lscpu | grep "^CPU(s):" | head -1 | awk '{print $2}')
cores_per_socket=$(lscpu | grep "Core(s) per socket" | awk '{print $4}')
sockets=$(lscpu | grep "Socket(s)" | awk '{print $2}')
threads_per_core=$(lscpu | grep "Thread(s) per core" | awk '{print $4}')

echo "Modèle CPU: $model" | tee -a "$OUTPUT_FILE"
echo "Cœurs physiques: $((cores_per_socket * sockets))" | tee -a "$OUTPUT_FILE"
echo "Cœurs logiques: $cores" | tee -a "$OUTPUT_FILE"

# Caches
for cache_dir in /sys/devices/system/cpu/cpu0/cache/index*; do
    if [[ -d "$cache_dir" ]]; then
        level=$(cat $cache_dir/level 2>/dev/null)
        type=$(cat $cache_dir/type 2>/dev/null)
        size=$(cat $cache_dir/size 2>/dev/null)
        line=$(cat $cache_dir/coherency_line_size 2>/dev/null)
        ways=$(cat $cache_dir/ways_of_associativity 2>/dev/null)
        echo "Cache L${level} (${type}): ${size}, ligne ${line} octets, ${ways}-way" | tee -a "$OUTPUT_FILE"
    fi
done

echo "" | tee -a "$OUTPUT_FILE"
echo "Fichier généré: $OUTPUT_FILE" | tee -a "$OUTPUT_FILE"
