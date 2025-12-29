# Projet Architecture des Processeurs Hautes Performances

## Analyse Expérimentale de la Hiérarchie Mémoire

**Auteur :** Achour Djerada  
**Formation :** Master 1 Informatique - Université Côte d'Azur  
**Encadrant :** Pr. Sid Touati  
**Année :** 2024/2025

---

## 📋 Description

Ce projet consiste à analyser expérimentalement la hiérarchie mémoire d'un processeur moderne (Intel Core i7-13650HX) à travers le développement de micro-benchmarks en C. Les exercices réalisés permettent de :

- **Exercice 1** : Détecter les tailles des caches (L1, L2, L3) par mesure de latence
- **Exercice 2** : Évaluer la bande passante mémoire et l'impact du TLB
- **Exercice 5** : Comparer nos résultats avec l'outil de référence Calibrator

---

## 🖥️ Configuration Matérielle

| Composant | Spécification |
|-----------|---------------|
| **Processeur** | Intel Core i7-13650HX (13ème génération) |
| **Architecture** | Raptor Lake (x86_64) |
| **Cœurs** | 14 (6 P-cores + 8 E-cores) |
| **Threads** | 20 |
| **Fréquence** | 800 MHz - 4.9 GHz (Turbo) |
| **RAM** | 32 Go DDR5 |

### Hiérarchie des Caches

| Niveau | Type | Taille | Ligne | Associativité |
|--------|------|--------|-------|---------------|
| L1 Data | Privé/cœur | 48 Ko | 64 octets | 12-way |
| L1 Instruction | Privé/cœur | 32 Ko | 64 octets | 8-way |
| L2 | Privé/cœur | 1280 Ko | 64 octets | 10-way |
| L3 (Smart Cache) | Partagé | 24 Mo | 64 octets | 12-way |

---

## 📁 Structure du Projet

```
Projet-djerada-achour-tls/
│
├── 📂 exercice1/               # Détection des tailles de cache
│   ├── cache_benchmark.c       # Code source (Pointer Chasing)
│   ├── resultats.csv           # Données expérimentales
│   ├── cache_latency.pdf       # Graphique généré
│   ├── plot_cache.gp           # Script gnuplot
│   └── Makefile
│
├── 📂 exercice2/               # Bande passante mémoire
│   ├── bandwidth_benchmark.c   # Code source
│   ├── resultats.csv           # Données (stride)
│   ├── resultats_seq.csv       # Données (séquentiel)
│   ├── bandwidth.pdf           # Graphique stride
│   ├── bandwidth_seq.pdf       # Graphique séquentiel
│   ├── plot_bandwidth.gp       # Scripts gnuplot
│   └── Makefile
│
├── 📂 exercice5/               # Outil Calibrator
│   ├── calibrator.c            # Code source (modifié)
│   ├── calibrator_results.pdf  # Graphique généré
│   ├── plot_calibrator.gp      # Script gnuplot
│   └── Makefile
│
├── 📂 rapport/                 # Rapport LaTeX
│   ├── rapport.tex             # Source LaTeX
│   └── rapport.pdf             # Rapport compilé
│
├── 📂 scripts/                 # Scripts utilitaires
│   ├── collect_info.sh         # Collecte infos système
│   ├── prepare_machine.sh      # Préparation benchmarks
│   ├── run.sh                  # Exécution simple
│   └── run_all.sh              # Exécution complète
│
├── system_info.txt             # Informations système collectées
├── IAG.txt                     # Déclaration usage IA
├── Makefile                    # Makefile principal
└── README.md                   # Ce fichier
```

---

## 🚀 Installation et Prérequis

### Dépendances système

```bash
# Installation des outils nécessaires
sudo apt update
sudo apt install build-essential gcc gnuplot texlive-latex-base \
                 texlive-latex-extra texlive-lang-french \
                 texlive-fonts-recommended linux-tools-common \
                 linux-tools-generic
```

### Vérification des outils

```bash
# Vérifier que tout est installé
gcc --version
gnuplot --version
pdflatex --version
cpupower --version
```

---

## 📖 Utilisation

### Méthode 1 : Script automatique (Recommandé)

```bash
cd scripts/

# Afficher le menu interactif
./run_all.sh

# Ou exécuter tout directement
./run_all.sh all
```

**Options du menu :**
1. Tout exécuter (Benchmarks + Graphes)
2. Exercice 1 uniquement
3. Exercice 2 uniquement
4. Exercice 5 uniquement
5. Collecter infos système
6. Créer l'archive finale
7. Tout faire (benchmarks + infos + archive)
8. Régénérer uniquement les graphiques

### Méthode 2 : Exécution manuelle

#### Préparation de la machine (optionnel mais recommandé)

```bash
# Voir l'état actuel
sudo ./scripts/prepare_machine.sh status

# Préparer pour les benchmarks (désactive Turbo, mode performance)
sudo ./scripts/prepare_machine.sh start

# Après les tests, restaurer la configuration normale
sudo ./scripts/prepare_machine.sh stop
```

#### Exercice 1 : Latence des caches

```bash
cd exercice1/

# Compiler
make

# Exécuter sur CPU 0
taskset -c 0 ./cache_benchmark > resultats.csv

# Générer le graphique
gnuplot plot_cache.gp

# Visualiser
evince cache_latency.pdf
```

#### Exercice 2 : Bande passante

```bash
cd exercice2/

# Compiler
make

# Exécuter
taskset -c 0 ./bandwidth_benchmark > resultats.csv

# Générer les graphiques
gnuplot plot_bandwidth.gp

# Visualiser
evince bandwidth.pdf bandwidth_seq.pdf
```

#### Exercice 5 : Calibrator

```bash
cd exercice5/

# Compiler et exécuter via Makefile
make benchmark MHZ=2600

# Ou manuellement
make
taskset -c 0 ./calibrator 2600 128M results
gnuplot plot_calibrator.gp
```

### Compilation du rapport

```bash
cd rapport/

# Compiler le rapport LaTeX
pdflatex rapport.tex
pdflatex rapport.tex   # 2ème passage pour les références

# Visualiser
evince rapport.pdf
```

---

## 🔧 Scripts Utilitaires

### `collect_info.sh` - Collecte des informations système

Génère un fichier `system_info.txt` contenant toutes les caractéristiques matérielles nécessaires pour le rapport.

```bash
./scripts/collect_info.sh [fichier_sortie]
```

**Informations collectées :**
- Version du noyau et distribution
- Caractéristiques CPU (lscpu)
- Hiérarchie des caches (sysfs + getconf)
- Informations mémoire
- Fréquences et gouverneur CPU
- Version du compilateur

### `prepare_machine.sh` - Préparation des benchmarks

Configure la machine pour des mesures optimales.

```bash
sudo ./scripts/prepare_machine.sh start   # Préparer
sudo ./scripts/prepare_machine.sh stop    # Restaurer
sudo ./scripts/prepare_machine.sh status  # État actuel
```

**Actions effectuées :**
- Passage du gouverneur CPU en mode `performance`
- Désactivation du Turbo Boost (Intel/AMD)
- Recommandations pour réduire la charge système

### `run.sh` - Exécution rapide

Script simple pour exécuter rapidement un benchmark avec les bonnes configurations.

```bash
sudo ./scripts/run.sh
```

### `run_all.sh` - Gestionnaire complet

Interface interactive pour gérer tout le projet.

```bash
./scripts/run_all.sh          # Menu interactif
./scripts/run_all.sh all      # Tout exécuter
./scripts/run_all.sh ex5      # Exercice 5 uniquement
./scripts/run_all.sh graphs   # Régénérer les graphiques
./scripts/run_all.sh archive  # Créer l'archive
```

---

## 📊 Résultats Attendus

### Exercice 1 : Courbe de latence

La courbe doit montrer des "marches" correspondant aux transitions entre niveaux de cache :

| Zone | Taille | Latence attendue |
|------|--------|------------------|
| L1 | 1-48 Ko | ~1-2 ns |
| L2 | 64 Ko - 1.25 Mo | ~3-5 ns |
| L3 | 1.5 - 24 Mo | ~10-20 ns |
| RAM | > 24 Mo | ~60-80 ns |

### Exercice 2 : Bande passante

- **Stride faible (64 octets)** : ~25-35 Go/s (prefetcher actif)
- **Stride = 4 Ko (page)** : ~5-6 Go/s (saturation TLB)
- **Séquentiel < 24 Mo** : ~20-30 Go/s (cache L3)
- **Séquentiel > 24 Mo** : ~15-17 Go/s (RAM DDR5)

---

## 📦 Création de l'Archive pour le Rendu

```bash
# Via le script
./scripts/run_all.sh archive

# Ou manuellement
tar -czvf Projet-Djerada-Achour.tar.gz \
    rapport/ exercice1/ exercice2/ exercice5/ \
    scripts/ system_info.txt IAG.txt README.md
```

**Contenu de l'archive :**
- ✅ Source LaTeX + PDF du rapport
- ✅ Codes C de chaque exercice
- ✅ Données expérimentales (CSV)
- ✅ Graphiques (PDF)
- ✅ Scripts gnuplot
- ✅ Fichier IAG.txt (déclaration IA)

---

## ⚠️ Problèmes Connus et Solutions

### Erreur de compilation Calibrator

```
error: conflicting types for 'round'
```

**Solution :** Renommer la fonction `round` en `my_round` :
```bash
sed -i 's/lng round/lng my_round/g' exercice5/calibrator.c
sed -i 's/round(/my_round(/g' exercice5/calibrator.c
```

### Courbe de latence plate

Si la courbe reste plate (~2-3 ns), le prefetcher masque les résultats.

**Solution :** Utiliser la technique du Pointer Chasing avec randomisation Fisher-Yates (déjà implémentée dans `cache_benchmark.c`).

### Figures non trouvées dans le rapport

```
! LaTeX Error: File 'exercice1/cache_latency.pdf' not found
```

**Solution :** Corriger les chemins relatifs dans `rapport.tex` :
```bash
cd rapport/
sed -i 's|{exercice1/|{../exercice1/|g' rapport.tex
sed -i 's|{exercice2/|{../exercice2/|g' rapport.tex
sed -i 's|{exercice5/|{../exercice5/|g' rapport.tex
```

### Package babel non disponible

**Solution :** Installer le package français ou commenter la ligne :
```bash
sudo apt install texlive-lang-french
# Ou commenter dans rapport.tex : % \usepackage[french]{babel}
```

---

## 📚 Références

1. **Calibrator** - Stefan Manegold, CWI Amsterdam  
   http://homepages.cwi.nl/~manegold/Calibrator/

2. **What Every Programmer Should Know About Memory** - Ulrich Drepper  
   https://people.freebsd.org/~lstewart/articles/cpumemory.pdf

3. **Intel 64 and IA-32 Architectures Optimization Reference Manual**  
   Intel Corporation, 2023

---

## 📝 Licence

Projet académique - Université Côte d'Azur  
Master Informatique - Architecture des Processeurs Hautes Performances

---

## 🙏 Remerciements

- Pr. Sid Touati pour l'encadrement du projet
- Stefan Manegold pour l'outil Calibrator
- La communauté open-source pour les outils utilisés (GCC, Gnuplot, LaTeX)
