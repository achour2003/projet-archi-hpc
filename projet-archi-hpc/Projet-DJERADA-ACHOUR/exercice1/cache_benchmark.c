/*
 * Exercice 1 : Micro-benchmark pour détecter les tailles des caches
 * VERSION AMÉLIORÉE avec POINTER CHASING
 * 
 * Cette version utilise la technique du "pointer chasing" pour empêcher
 * le prefetcher matériel de prédire les accès mémoire.
 */

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <stdint.h>
#include <unistd.h>

/* Configuration */
#define CACHE_LINE_SIZE     64
#define NB_ITERATIONS       1000000   /* Nombre d'accès pour avoir un temps mesurable */
#define NB_REPETITIONS      5         /* Répétitions pour stabilité */

/* Pour éviter optimisation */
volatile void *sink;

/* Obtenir le temps en nanosecondes */
static inline uint64_t get_time_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t)ts.tv_sec * 1000000000ULL + (uint64_t)ts.tv_nsec;
}

/*
 * Crée une chaîne de pointeurs circulaire avec un pas donné.
 * Chaque élément pointe vers le suivant, le dernier pointe vers le premier.
 * Le prefetcher ne peut pas prédire car l'adresse suivante dépend de la donnée lue.
 */
void create_pointer_chain(void **array, size_t size_bytes, size_t stride) {
    size_t num_elements = size_bytes / sizeof(void*);
    size_t count = size_bytes / stride; // Nombre de blocs à visiter
    
    // Tableau d'indices temporaire pour le mélange
    size_t *indices = malloc(count * sizeof(size_t));
    if (!indices) {
        perror("Malloc indices failed");
        exit(1);
    }

    // On prépare les indices des débuts de lignes (0, 8, 16...)
    // stride / 8 car sizeof(void*) = 8 octets sur 64 bits
    size_t step_index = stride / sizeof(void*); 
    for (size_t i = 0; i < count; i++) {
        indices[i] = i * step_index;
    }

    // Mélange de Fisher-Yates (Shuffle)
    // On mélange les indices pour que l'accès soit imprévisible
    for (size_t i = count - 1; i > 0; i--) {
        size_t j = rand() % (i + 1);
        size_t temp = indices[i];
        indices[i] = indices[j];
        indices[j] = temp;
    }

    // Chainage des pointeurs selon l'ordre mélangé
    for (size_t i = 0; i < count - 1; i++) {
        // L'élément actuel pointe vers le suivant dans la liste mélangée
        array[indices[i]] = (void*)&array[indices[i+1]];
    }
    
    // Le dernier pointe vers le premier (boucle fermée)
    array[indices[count-1]] = (void*)&array[indices[0]];

    free(indices);
}
/*
 * Parcourt la chaîne de pointeurs N fois et mesure le temps.
 * Le compilateur ne peut pas optimiser car chaque accès dépend du précédent.
 */
double measure_latency(void **array, size_t num_accesses) {
    void **p = array;
    
    uint64_t start = get_time_ns();
    
    for (size_t i = 0; i < num_accesses; i++) {
        p = (void **)*p;  /* L'adresse suivante dépend de la donnée lue ! */
    }
    
    uint64_t end = get_time_ns();
    
    /* Empêcher l'optimisation */
    sink = p;
    
    return (double)(end - start) / (double)num_accesses;
}

int main(int argc, char *argv[]) {
    /* Tailles à tester (en Ko) - échelle logarithmique */
    size_t tailles_ko[] = {
        /* Zone L1 (48 Ko sur mon CPU i7 13650hx) */
        1, 2, 4, 8, 12, 16, 24, 32, 48,
        /* Zone L2 (1.25 Mo) */
        64, 96, 128, 192, 256, 384, 512, 768, 1024, 1280,
        /* Zone L3 (24 Mo) */
        1536, 2048, 3072, 4096, 6144, 8192, 12288, 16384, 20480, 24576,
        /* Zone RAM */
        28672, 32768, 40960, 49152, 65536
    };
    int nb_tailles = sizeof(tailles_ko) / sizeof(tailles_ko[0]);
    
    size_t max_size = 65536 * 1024;  /* 64 Mo max */
    
    /* Allocation alignée sur les pages */
    void **array = NULL;
    if (posix_memalign((void**)&array, 4096, max_size) != 0) {
        fprintf(stderr, "Erreur allocation mémoire\n");
        return 1;
    }
    
    /* En-tête CSV */
    printf("# Exercice 1 - Detection des tailles de cache (Pointer Chasing)\n");
    printf("# Technique: Pointer chasing pour desactiver le prefetcher\n");
    printf("# Iterations par mesure: %d\n", NB_ITERATIONS);
    printf("# Repetitions: %d\n", NB_REPETITIONS);
    printf("taille_ko,temps_ns\n");
    
    fprintf(stderr, "Benchmark avec pointer chasing (%d tailles)...\n", nb_tailles);
    fprintf(stderr, "Caches attendus: L1=48Ko, L2=1.25Mo, L3=24Mo\n\n");
    
    for (int t = 0; t < nb_tailles; t++) {
        size_t taille_bytes = tailles_ko[t] * 1024;
        
        if (taille_bytes > max_size) break;
        
        /* Créer la chaîne de pointeurs */
        create_pointer_chain(array, taille_bytes, CACHE_LINE_SIZE);
        
        /* Mesurer plusieurs fois et prendre le minimum */
        double min_latency = 1e9;
        
        for (int r = 0; r < NB_REPETITIONS; r++) {
            double latency = measure_latency(array, NB_ITERATIONS);
            if (latency < min_latency) {
                min_latency = latency;
            }
        }
        
        printf("%zu,%.2f\n", tailles_ko[t], min_latency);
        
        /* Afficher la progression avec interprétation */
        char *zone = "???";
        if (tailles_ko[t] <= 48) zone = "L1";
        else if (tailles_ko[t] <= 1280) zone = "L2";
        else if (tailles_ko[t] <= 24576) zone = "L3";
        else zone = "RAM";
        
        fprintf(stderr, "[%2d/%2d] %6zu Ko (%s): %.2f ns\n", 
                t + 1, nb_tailles, tailles_ko[t], zone, min_latency);
    }
    
    fprintf(stderr, "\nTerminé.\n");
    
    free(array);
    return 0;
}
