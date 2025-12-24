/*
 * Exercice 1 : Micro-benchmark pour détecter les tailles des caches
 * Projet Architecture des Processeurs Hautes Performances
 * Master Informatique - Université Côte d'Azur
 * 
 * Ce programme mesure le temps d'accès moyen aux données en fonction
 * de la taille du working set pour détecter les niveaux de cache.
 */

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <stdint.h>

/* Configuration - À ADAPTER selon votre machine */
#define MAX_TAILLE_DATA_KO  (64 * 1024)  /* 64 Mo - doit dépasser 2x le dernier niveau de cache */
#define CACHE_LINE_SIZE     64           /* Taille typique ligne cache (vérifier avec getconf) */
#define NB_REPETITIONS      100          /* Nombre de répétitions pour stabiliser les mesures */
#define STEP_SIZE           1024         /* Pas d'incrémentation en octets */

/* Macro pour forcer l'utilisation du résultat (évite optimisation du compilateur) */
volatile int sink;

/* Fonction pour obtenir le temps en nanosecondes */
static inline uint64_t get_time_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t)ts.tv_sec * 1000000000ULL + (uint64_t)ts.tv_nsec;
}

/* Fonction pour vider les caches (best effort) */
void flush_cache(char *buffer, size_t size) {
    volatile char tmp;
    for (size_t i = 0; i < size; i += CACHE_LINE_SIZE) {
        tmp = buffer[i];
    }
    (void)tmp;
}

int main(int argc, char *argv[]) {
    size_t max_taille = MAX_TAILLE_DATA_KO * 1024;
    size_t pas_acces = CACHE_LINE_SIZE / sizeof(int);
    int nb_repetitions = NB_REPETITIONS;
    
    /* Permettre de configurer via arguments */
    if (argc > 1) {
        max_taille = (size_t)atoi(argv[1]) * 1024;
    }
    if (argc > 2) {
        nb_repetitions = atoi(argv[2]);
    }
    
    /* Allocation dynamique du tableau */
    int *tab = (int *)calloc(max_taille / sizeof(int), sizeof(int));
    if (tab == NULL) {
        fprintf(stderr, "Erreur: impossible d'allouer %zu octets\n", max_taille);
        return 1;
    }
    
    /* Initialisation du tableau */
    for (size_t i = 0; i < max_taille / sizeof(int); i++) {
        tab[i] = (int)i;
    }
    
    /* En-tête CSV */
    printf("# Exercice 1 - Detection des tailles de cache\n");
    printf("# Taille ligne cache: %d octets\n", CACHE_LINE_SIZE);
    printf("# Nombre de repetitions: %d\n", nb_repetitions);
    printf("# Format: taille_ko,temps_acces_moyen_ns\n");
    printf("taille_ko,temps_ns\n");
    
    /* Boucle principale : variation de la taille des données */
    for (size_t taille_data = CACHE_LINE_SIZE; 
         taille_data <= max_taille; 
         taille_data += STEP_SIZE) {
        
        size_t nb_donnees = taille_data / sizeof(int);
        size_t nb_acces = nb_donnees / pas_acces;
        
        if (nb_acces == 0) nb_acces = 1;
        
        volatile int x = 0;
        
        /* Pré-chargement des données dans le cache */
        for (size_t i = 0; i < nb_donnees; i += pas_acces) {
            x += tab[i];
        }
        
        /* Mesure du temps d'accès */
        uint64_t t1 = get_time_ns();
        
        for (int j = 0; j < nb_repetitions; j++) {
            for (size_t i = 0; i < nb_donnees; i += pas_acces) {
                x += tab[i];
            }
        }
        
        uint64_t t2 = get_time_ns();
        
        /* Éviter l'optimisation du compilateur */
        sink = x;
        
        /* Calcul du temps d'accès moyen par donnée (en nanosecondes) */
        double temps_total_ns = (double)(t2 - t1);
        double temps_acces_moyen = temps_total_ns / ((double)nb_acces * (double)nb_repetitions);
        
        /* Affichage format CSV */
        printf("%zu,%.2f\n", taille_data / 1024, temps_acces_moyen);
        
        /* Affichage progression sur stderr */
        fprintf(stderr, "\rProgression: %zu / %zu Ko (%.1f%%)", 
                taille_data / 1024, max_taille / 1024,
                100.0 * taille_data / max_taille);
    }
    
    fprintf(stderr, "\nTerminé.\n");
    
    free(tab);
    return 0;
}
