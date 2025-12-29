# Makefile - Exercice 2 : Bande passante mémoire
# Projet Architecture des Processeurs Hautes Performances

CC = gcc
CFLAGS = -O2 -Wall -Wextra -march=native
LDFLAGS = -lrt

TARGET = bandwidth_benchmark
SRC = bandwidth_benchmark.c

.PHONY: all clean run plot

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

run: $(TARGET)
	./$(TARGET) > resultats_full.csv
	@echo "Séparation des données..."
	@# Extraire la première section (BP vs pas) - lignes jusqu'à la ligne vide
	@head -n 17 resultats_full.csv > resultats.csv
	@# Extraire la deuxième section (BP séquentielle) - après la ligne vide
	@echo "taille_mo,bande_passante_seq_go_s" > resultats_seq.csv
	@tail -n 7 resultats_full.csv | grep "^[0-9]" >> resultats_seq.csv
	@echo "Fichiers générés: resultats.csv et resultats_seq.csv"
	@cat resultats_seq.csv

plot: resultats.csv resultats_seq.csv
	gnuplot plot_bandwidth.gp
	@echo "Graphiques générés: bandwidth.pdf et bandwidth_seq.pdf"

clean:
	rm -f $(TARGET) resultats.csv resultats_seq.csv resultats_full.csv bandwidth.pdf bandwidth_seq.pdf

# Cible pour tout faire d'un coup
benchmark: clean all run plot
	@echo ""
	@echo "=== Benchmark terminé ==="
