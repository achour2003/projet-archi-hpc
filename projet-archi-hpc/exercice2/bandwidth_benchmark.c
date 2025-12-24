/*
 * Exercice 2 : Micro-benchmark pour évaluer la bande passante mémoire
 * Projet Architecture des Processeurs Hautes Performances
 * Master Informatique - Université Côte d'Azur
 * 
 * Ce programme mesure le temps d'accès à la mémoire centrale en évitant
 * les caches, puis calcule la bande passante effective.
 */

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <stdint.h>
#include <unistd.h>

/* Configuration - À ADAPTER selon votre machine */
#define CACHE_LINE_SIZE     64           /* Taille ligne cache en octets */
#define L3_CACHE_SIZE_KB    8192         /* Taille L3 en Ko (adapter à votre machine) */
#define PAGE_SIZE           4096         /* Taille d'une page en octets */
#define NB_REPETITIONS      10           /* Nombre de répétitions */

/* Pour forcer les accès en mémoire centrale, on utilise un pas 
 * supérieur à la taille du dernier niveau de cache divisé par
 * le nombre d'éléments qu'on souhaite accéder */

/* Macro pour forcer l'utilisation du résultat */
volatile int sink;

/* Fonction pour obtenir le temps en nanosecondes */
static inline uint64_t get_time_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t)ts.tv_sec * 1000000000ULL + (uint64_t)ts.tv_nsec;
}

/* Fonction pour forcer le vidage d'une ligne de cache (si disponible) */
#ifdef __x86_64__
static inline void clflush(volatile void *p) {
    __asm__ volatile ("clflush (%0)" :: "r"(p));
}
#else
static inline void clflush(volatile void *p) {
    (void)p;  /* Non disponible sur cette architecture */
}
#endif

int main(int argc, char *argv[]) {
    /* Taille du buffer : doit être très supérieur au dernier niveau de cache */
    size_t buffer_size = (size_t)L3_CACHE_SIZE_KB * 1024 * 4; /* 4x la taille du L3 */
    int nb_repetitions = NB_REPETITIONS;
    
    if (argc > 1) {
        buffer_size = (size_t)atoi(argv[1]) * 1024 * 1024; /* En Mo */
    }
    if (argc > 2) {
        nb_repetitions = atoi(argv[2]);
    }
    
    /* Allocation alignée sur les pages */
    char *buffer = NULL;
    if (posix_memalign((void **)&buffer, PAGE_SIZE, buffer_size) != 0) {
        fprintf(stderr, "Erreur: impossible d'allouer %zu octets\n", buffer_size);
        return 1;
    }
    
    /* Initialisation pour s'assurer que les pages sont allouées */
    memset(buffer, 1, buffer_size);
    
    /* En-tête CSV */
    printf("# Exercice 2 - Evaluation de la bande passante memoire\n");
    printf("# Taille buffer: %zu Mo\n", buffer_size / (1024 * 1024));
    printf("# Taille ligne cache: %d octets\n", CACHE_LINE_SIZE);
    printf("# Format: pas_ko,temps_acces_ns,bande_passante_go_s\n");
    printf("pas_ko,temps_ns,bande_passante_go_s\n");
    
    fprintf(stderr, "Démarrage des mesures de bande passante...\n");
    
    /* Test avec différents pas d'accès pour dépasser les caches */
    size_t pas_values[] = {
        CACHE_LINE_SIZE,           /* Accès séquentiel (cache efficace) */
        1024,                      /* 1 Ko */
        4096,                      /* 4 Ko = taille d'une page */
        8192,                      /* 8 Ko */
        16384,                     /* 16 Ko */
        32768,                     /* 32 Ko */
        65536,                     /* 64 Ko */
        131072,                    /* 128 Ko */
        262144,                    /* 256 Ko */
        524288,                    /* 512 Ko */
        1048576,                   /* 1 Mo */
        2097152                    /* 2 Mo */
    };
    int nb_pas = sizeof(pas_values) / sizeof(pas_values[0]);
    
    for (int p = 0; p < nb_pas; p++) {
        size_t pas = pas_values[p];
        
        if (pas >= buffer_size / 2) continue; /* Pas trop grand */
        
        size_t nb_acces = buffer_size / pas;
        volatile int x = 0;
        
        /* Vidage des caches (best effort avec accès aléatoires) */
        for (size_t i = 0; i < buffer_size; i += PAGE_SIZE) {
            x += buffer[i];
        }
        
        /* Mesure */
        uint64_t t1 = get_time_ns();
        
        for (int j = 0; j < nb_repetitions; j++) {
            for (size_t i = 0; i < buffer_size; i += pas) {
                x += buffer[i];
            }
        }
        
        uint64_t t2 = get_time_ns();
        
        sink = x;
        
        /* Calculs */
        double temps_total_ns = (double)(t2 - t1);
        double temps_acces_moyen_ns = temps_total_ns / ((double)nb_acces * (double)nb_repetitions);
        
        /* Bande passante : on charge une ligne cache par accès */
        double donnees_transferees = (double)nb_acces * (double)CACHE_LINE_SIZE * (double)nb_repetitions;
        double temps_total_s = temps_total_ns / 1e9;
        double bande_passante_go_s = (donnees_transferees / temps_total_s) / (1024.0 * 1024.0 * 1024.0);
        
        printf("%zu,%.2f,%.3f\n", pas / 1024, temps_acces_moyen_ns, bande_passante_go_s);
        
        fprintf(stderr, "  Pas: %8zu Ko | Temps: %8.2f ns | BP: %6.3f Go/s\n", 
                pas / 1024, temps_acces_moyen_ns, bande_passante_go_s);
    }
    
    /* Test spécifique pour mesurer la bande passante pure (accès séquentiel) */
    fprintf(stderr, "\nMesure de bande passante séquentielle...\n");
    
    size_t test_sizes[] = {1, 2, 4, 8, 16, 32, 64, 128, 256}; /* En Mo */
    int nb_sizes = sizeof(test_sizes) / sizeof(test_sizes[0]);
    
    printf("\n# Bande passante sequentielle\n");
    printf("# Format: taille_mo,bande_passante_go_s\n");
    printf("taille_mo,bande_passante_seq_go_s\n");
    
    for (int s = 0; s < nb_sizes; s++) {
        size_t test_size = test_sizes[s] * 1024 * 1024;
        if (test_size > buffer_size) continue;
        
        volatile long sum = 0;
        long *long_buffer = (long *)buffer;
        size_t nb_longs = test_size / sizeof(long);
        
        uint64_t t1 = get_time_ns();
        
        for (int j = 0; j < nb_repetitions; j++) {
            for (size_t i = 0; i < nb_longs; i++) {
                sum += long_buffer[i];
            }
        }
        
        uint64_t t2 = get_time_ns();
        
        sink = (int)sum;
        
        double temps_total_s = (double)(t2 - t1) / 1e9;
        double donnees_transferees = (double)test_size * (double)nb_repetitions;
        double bande_passante = donnees_transferees / temps_total_s / (1024.0 * 1024.0 * 1024.0);
        
        printf("%zu,%.3f\n", test_sizes[s], bande_passante);
        fprintf(stderr, "  Taille: %4zu Mo | BP: %6.3f Go/s\n", test_sizes[s], bande_passante);
    }
    
    fprintf(stderr, "\nTerminé.\n");
    
    free(buffer);
    return 0;
}
