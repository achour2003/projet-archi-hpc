# Projet Architecture des Processeurs Hautes Performances

## Master Informatique - Université Côte d'Azur
## Professeur Sid Touati

---

## 📁 Structure du projet

```
Projet-NOM-Prenom/
├── README.md                 # Ce fichier
├── exercice1/               # Micro-benchmark taille des caches
│   ├── cache_benchmark.c    # Code source
│   ├── Makefile
│   ├── resultats.csv        # Données expérimentales
│   ├── cache_latency.pdf    # Graphique généré
│   └── plot_cache.gp        # Script gnuplot
├── exercice2/               # Bande passante mémoire
│   ├── bandwidth_benchmark.c
│   ├── Makefile
│   ├── resultats.csv
│   ├── bandwidth.pdf
│   └── plot_bandwidth.gp
├── exercice5/               # Outil Calibrator
│   ├── calibrator.c         # Code source Calibrator
│   ├── Makefile
│   ├── *.data               # Données générées
│   ├── *.gp                 # Scripts gnuplot générés
│   └── *.pdf                # Graphiques
├── rapport/                 # Rapport LaTeX
│   ├── main.tex             # Document principal
│   ├── sections/            # Sections du rapport
│   └── figures/             # Figures incluses
├── scripts/                 # Scripts utilitaires
│   ├── prepare_machine.sh   # Préparation de la machine
│   ├── run_all.sh          # Exécution de tous les benchmarks
│   └── collect_info.sh     # Collecte infos système
└── IAG.txt                  # Déclaration usage IA (si applicable)
```

---

## 🔧 Prérequis

### Outils nécessaires
```bash
# Vérifier les installations
gcc --version          # Compilateur C
gnuplot --version      # Génération de graphiques
pdflatex --version     # Compilation LaTeX
```

### Installation des dépendances (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install build-essential gnuplot texlive-full texlive-lang-french
```

---

## 🚀 Configuration de la machine pour les expériences

### 1. Désactiver le scaling de fréquence CPU (IMPORTANT)
```bash
# Vérifier le gouverneur actuel
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# Passer en mode performance (fréquence fixe maximale)
sudo cpupower frequency-set -g performance

# OU manuellement pour chaque CPU
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo performance | sudo tee $cpu
done
```

### 2. Désactiver le turbo boost (si applicable)
```bash
# Pour Intel
echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo

# Pour AMD (vérifier le chemin)
echo 0 | sudo tee /sys/devices/system/cpu/cpufreq/boost
```

### 3. Réduire la charge système
```bash
# Fermer les applications graphiques
# Utiliser un TTY (Ctrl+Alt+F3) pour les expériences

# Arrêter les services non essentiels
sudo systemctl stop bluetooth
sudo systemctl stop cups
# etc.
```

### 4. Exécuter sur un CPU spécifique
```bash
# Exemple : exécuter sur le CPU 0
taskset -c 0 ./mon_benchmark
```

---

## 📊 Collecte des informations système

```bash
# Informations CPU
lscpu

# Détails des caches
getconf -a | grep CACHE

# Hiérarchie mémoire détaillée
cat /sys/devices/system/cpu/cpu0/cache/index*/size
cat /sys/devices/system/cpu/cpu0/cache/index*/type
cat /sys/devices/system/cpu/cpu0/cache/index*/level

# Taille des pages
getconf PAGESIZE

# Informations mémoire
free -h
cat /proc/meminfo

# Version du noyau
uname -a
```

---

## 🔨 Compilation et exécution

### Exercice 1 - Détection taille des caches
```bash
cd exercice1
make
taskset -c 0 ./cache_benchmark > resultats.csv
gnuplot plot_cache.gp
```

### Exercice 2 - Bande passante mémoire
```bash
cd exercice2
make
taskset -c 0 ./bandwidth_benchmark > resultats.csv
gnuplot plot_bandwidth.gp
```

### Exercice 5 - Calibrator
```bash
cd exercice5
make
# Syntaxe: ./calibrator <MHz> <taille_max> <nom_fichier>
taskset -c 0 ./calibrator 3000 32M results
gnuplot results.cache-miss-latency.gp
gnuplot results.TLB-miss-latency.gp
```

---

## 📝 Génération du rapport

```bash
cd rapport
pdflatex main.tex
bibtex main
pdflatex main.tex
pdflatex main.tex
```

---

## 📦 Création de l'archive finale

```bash
# À la racine du projet
tar -czvf Projet-NOM-Prenom.tar.gz \
    exercice1/ \
    exercice2/ \
    exercice5/ \
    rapport/ \
    README.md \
    IAG.txt
```

---

## ⚠️ Points importants

1. **Machine Linux native** : Ne pas utiliser de machine virtuelle
2. **Faible charge** : Minimiser les processus actifs
3. **Fréquence CPU fixe** : Désactiver le scaling dynamique
4. **Format CSV** : Données au format CSV pour les résultats
5. **Graphiques PDF** : Générés avec gnuplot
6. **Rapport LaTeX** : Obligatoire, pas de Word

---

## 📚 Références

- [Documentation Calibrator](http://homepages.cwi.nl/~manegold/Calibrator/)
- Cours Architecture des Processeurs Hautes Performances
- TP Hiérarchie Mémoire
