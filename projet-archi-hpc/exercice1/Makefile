# Makefile - Exercice 1 : Benchmark des caches
# Projet Architecture des Processeurs Hautes Performances

CC = gcc
CFLAGS = -O2 -Wall -Wextra -march=native
LDFLAGS = -lrt

TARGET = cache_benchmark
SRC = cache_benchmark.c
CSV = resultats.csv
PLOT = cache_latency.pdf

.PHONY: all clean run plot help

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

# Exécution du benchmark (utiliser taskset pour fixer le CPU)
run: $(TARGET)
	@echo "Exécution du benchmark..."
	@echo "Conseil: utilisez 'taskset -c 0 ./$(TARGET)' pour fixer le CPU"
	./$(TARGET) > $(CSV)

# Génération du graphique
plot: $(CSV)
	gnuplot plot_cache.gp

# Tout faire
benchmark: run plot

clean:
	rm -f $(TARGET) $(CSV) $(PLOT)

help:
	@echo "Cibles disponibles:"
	@echo "  all       - Compile le benchmark"
	@echo "  run       - Exécute le benchmark"
	@echo "  plot      - Génère le graphique"
	@echo "  benchmark - Compile, exécute et génère le graphique"
	@echo "  clean     - Nettoie les fichiers générés"
	@echo ""
	@echo "Options de compilation:"
	@echo "  CFLAGS = $(CFLAGS)"
