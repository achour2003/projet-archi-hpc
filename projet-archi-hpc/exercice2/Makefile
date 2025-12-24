# Makefile - Exercice 2 : Benchmark bande passante mémoire
# Projet Architecture des Processeurs Hautes Performances

CC = gcc
CFLAGS = -O2 -Wall -Wextra -march=native
LDFLAGS = -lrt

TARGET = bandwidth_benchmark
SRC = bandwidth_benchmark.c
CSV = resultats.csv
PLOT = bandwidth.pdf

.PHONY: all clean run plot help

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

run: $(TARGET)
	@echo "Exécution du benchmark de bande passante..."
	@echo "Conseil: utilisez 'taskset -c 0 ./$(TARGET)' pour fixer le CPU"
	./$(TARGET) > $(CSV)

plot: $(CSV)
	gnuplot plot_bandwidth.gp

benchmark: run plot

clean:
	rm -f $(TARGET) $(CSV) $(PLOT) bandwidth_step.pdf

help:
	@echo "Cibles disponibles:"
	@echo "  all       - Compile le benchmark"
	@echo "  run       - Exécute le benchmark"
	@echo "  plot      - Génère les graphiques"
	@echo "  benchmark - Compile, exécute et génère les graphiques"
	@echo "  clean     - Nettoie les fichiers générés"
