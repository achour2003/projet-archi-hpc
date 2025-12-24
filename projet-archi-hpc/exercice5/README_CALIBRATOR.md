# Exercice 5 : Comprendre l'outil Calibrator

## Qu'est-ce que Calibrator ?

Calibrator est un micro-benchmark sophistiqué créé par Stefan Manegold (CWI Amsterdam)
qui permet de mesurer automatiquement les caractéristiques de la hiérarchie mémoire :
- Tailles des caches (L1, L2, L3)
- Tailles des lignes de cache
- Latences d'accès à chaque niveau
- Caractéristiques du TLB

## Pourquoi Calibrator fonctionne mieux que nos micro-benchmarks simples ?

### 1. Technique du "pointer chasing"

Au lieu d'accéder séquentiellement à un tableau (`tab[i], tab[i+1], ...`),
Calibrator utilise une chaîne de pointeurs :

```c
// Notre approche simple (prévisible)
for (i = 0; i < n; i += pas) {
    x += tab[i];
}

// Approche Calibrator (pointer chasing)
p = &array[0];
*p = &array[stride];
// ... création d'une chaîne circulaire de pointeurs
for (i = 0; i < n; i++) {
    p = (char **)*p;  // L'adresse suivante dépend de la donnée actuelle
}
```

**Avantage** : Le prefetcher matériel ne peut PAS prédire les adresses suivantes
car chaque adresse dépend de la valeur lue en mémoire. Cela désactive
efficacement le préchargement automatique (data preloading).

### 2. Chaîne circulaire avec stride variable

Calibrator crée une liste chaînée circulaire dans le tableau :
- array[0] pointe vers array[stride]
- array[stride] pointe vers array[2*stride]
- ...
- Le dernier élément pointe vers array[0]

En variant le stride et la taille du tableau, on peut :
- Isoler les effets de chaque niveau de cache
- Mesurer précisément les latences

### 3. Mesure du temps minimum (pas moyenne)

```c
for (tries = 0; tries < NUMTRIES; ++tries) {
    time = now();
    // ... accès mémoire
    time = now() - time;
    if (time < best) {
        best = time;
    }
}
```

Calibrator prend le **temps minimum** sur plusieurs essais plutôt qu'une moyenne.
Cela élimine les perturbations dues aux interruptions système.

### 4. Calibration automatique du nombre d'itérations

```c
if (time <= MINTIME) {
    j *= 2;  // Double le nombre d'itérations
    tries--;  // Recommence l'essai
}
```

Si le temps mesuré est trop court (< MINTIME), Calibrator augmente
automatiquement le nombre d'itérations pour avoir des mesures significatives.

### 5. Séparation Cache vs TLB

Calibrator effectue deux types de tests :
1. **Test cache** : Stride variable, nombre de pages constant
2. **Test TLB** : Stride = taille de page, nombre de pages variable

Cela permet de mesurer séparément les effets du cache et du TLB.

## Utilisation

```bash
# Syntaxe
./calibrator <MHz> <taille_max> <nom_fichier>

# Exemple (CPU à 3 GHz, test jusqu'à 64 Mo)
./calibrator 3000 64M results

# Fichiers générés
results.cache-miss-latency.data  # Données latence cache
results.cache-miss-latency.gp    # Script gnuplot
results.cache-replace-time.data  # Données remplacement cache
results.cache-replace-time.gp    # Script gnuplot
results.TLB-miss-latency.data    # Données latence TLB
results.TLB-miss-latency.gp      # Script gnuplot
```

## Comment obtenir la fréquence CPU ?

```bash
# Méthode 1 : /proc/cpuinfo
cat /proc/cpuinfo | grep "cpu MHz"

# Méthode 2 : lscpu
lscpu | grep "CPU MHz"

# Méthode 3 : fréquence maximale
cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq
# Diviser par 1000 pour avoir les MHz
```

## Interprétation des résultats

Les graphiques montrent des "paliers" correspondant à chaque niveau de cache :
- Premier palier bas : données dans L1 (quelques cycles)
- Deuxième palier : données dans L2 (~10-20 cycles)
- Troisième palier : données dans L3 (~30-50 cycles)
- Dernier palier haut : accès mémoire principale (~100-300 cycles)

Les transitions entre paliers indiquent les tailles des caches.

## Références

- Page officielle : http://homepages.cwi.nl/~manegold/Calibrator/
- Article original : Manegold et al., "What is the Cost of a Memory Access?"
