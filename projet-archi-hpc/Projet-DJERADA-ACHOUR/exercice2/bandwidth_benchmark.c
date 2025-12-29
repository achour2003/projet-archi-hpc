#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <stdint.h>
#include <unistd.h>

#define CACHE_LINE_SIZE     64
#define L3_CACHE_SIZE_KB    24576
#define PAGE_SIZE           4096
#define NB_REPETITIONS      3

volatile int sink;

static inline uint64_t get_time_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t)ts.tv_sec * 1000000000ULL + (uint64_t)ts.tv_nsec;
}

int main(int argc, char *argv[]) {
    (void)argc; (void)argv;
    size_t buffer_size = (size_t)L3_CACHE_SIZE_KB * 1024 * 4;
    
    char *buffer = NULL;
    if (posix_memalign((void **)&buffer, PAGE_SIZE, buffer_size) != 0) return 1;
    memset(buffer, 1, buffer_size);
    
    // --- PARTIE 1 : STRIDE (Va dans resultats.csv via stdout) ---
    printf("# Exercice 2 - Pas d'acces\n");
    printf("pas_ko,temps_ns,bande_passante_go_s\n");
    
    size_t pas_values[] = {64, 1024, 4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288, 1048576, 2097152};
    int nb_pas = sizeof(pas_values) / sizeof(pas_values[0]);
    
    for (int p = 0; p < nb_pas; p++) {
        size_t pas = pas_values[p];
        if (pas >= buffer_size / 2) continue;
        size_t nb_acces = buffer_size / pas;
        volatile int x = 0;
        
        for (size_t i = 0; i < buffer_size; i += PAGE_SIZE) x += buffer[i];
        
        uint64_t t1 = get_time_ns();
        for (int j = 0; j < NB_REPETITIONS; j++) {
            for (size_t i = 0; i < buffer_size; i += pas) x += buffer[i];
        }
        uint64_t t2 = get_time_ns();
        sink = x;
        
        double temps = (double)(t2 - t1);
        double bp = ((double)nb_acces * 64.0 * NB_REPETITIONS) / (temps/1e9) / (1024.0*1024.0*1024.0);
        printf("%.4f,%.2f,%.3f\n", (double)pas/1024.0, temps/(nb_acces*NB_REPETITIONS), bp);
    }

    // --- PARTIE 2 : SÉQUENTIEL (Va dans resultats_seq.csv DIRECTEMENT) ---
    // On ouvre explicitement un nouveau fichier pour éviter les erreurs gnuplot
    FILE *fp = fopen("resultats_seq.csv", "w");
    if (fp == NULL) {
        perror("Impossible de créer resultats_seq.csv");
        return 1;
    }
    
    fprintf(fp, "# Exercice 2 - Sequentiel\n");
    fprintf(fp, "taille_mo,bande_passante_seq_go_s\n");

    size_t sizes[] = {1, 2, 4, 8, 16, 32, 64, 128, 256};
    for (int s = 0; s < 9; s++) {
        size_t sz = sizes[s] * 1024 * 1024;
        if (sz > buffer_size) continue;
        volatile long sum = 0;
        long *lb = (long *)buffer;
        size_t n = sz / sizeof(long);
        
        uint64_t t1 = get_time_ns();
        for (int j = 0; j < NB_REPETITIONS; j++) {
            for (size_t i = 0; i < n; i++) sum += lb[i];
        }
        uint64_t t2 = get_time_ns();
        sink = (int)sum;
        
        double bp = ((double)sz * NB_REPETITIONS) / ((double)(t2-t1)/1e9) / (1024.0*1024.0*1024.0);
        fprintf(fp, "%zu,%.3f\n", sizes[s], bp);
    }
    
    fclose(fp); // On ferme proprement le 2eme fichier
    free(buffer);
    return 0;
}
