# ============================================================
# Makefile - Exercice 5 : Calibrator (Intel i7-13650HX)
# ============================================================

CC = gcc
# Options : Optimisation max, instructions natives (Raptor Lake), math library
CFLAGS = -O2 -Wall -march=native -Wno-unused-result -Wno-format
LDFLAGS = -lm

TARGET = calibrator
SRC = calibrator.c
GP_SCRIPT = plot_calibrator_modern.gp
OUTPUT_PDF = calibrator_results.pdf

# Fréquence par défaut (peut être surchargée: make run MHZ=4000)
MHZ ?= 3000

.PHONY: all clean run plot help

all: $(TARGET)

$(TARGET): $(SRC)
	@echo "[INFO] Correction de compatibilité (round -> my_round)..."
	@sed -i 's/\bround\b/my_round/g' $(SRC)
	@echo "[INFO] Compilation de $(TARGET)..."
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

# Crée le script Gnuplot moderne s'il n'existe pas
$(GP_SCRIPT):
	@echo "[INFO] Création du script Gnuplot moderne..."
	@echo "# Script auto-généré" > $@
	@echo "set terminal pdfcairo enhanced font \"Arial,12\" size 10,10" >> $@
	@echo "set output \"$(OUTPUT_PDF)\"" >> $@
	@echo "set datafile commentschars \"#\"" >> $@
	@echo "set multiplot layout 2,1 title \"Analyse Calibrator (Intel i7-13650HX)\"" >> $@
	@echo "set title \"1. Latence Mémoire par Taille de Buffer\" font \",14\"" >> $@
	@echo "set xlabel \"Taille du buffer (Ko)\"" >> $@
	@echo "set ylabel \"Latence (ns)\"" >> $@
	@echo "set logscale x 2" >> $@
	@echo "set logscale y 10" >> $@
	@echo "set grid xtics ytics mytics" >> $@
	@echo "set format x \"%.0s%c\"" >> $@
	@echo "set key top left box" >> $@
	@echo "plot 'test_run.cache-miss-latency.data' using (1024*\$$1):7 with linespoints pt 7 ps 0.8 lw 2 lc rgb '#D32F2F' title 'Accès séquentiel', \\" >> $@
	@echo "     'test_run.cache-miss-latency.data' using (1024*\$$1):13 with linespoints pt 5 ps 0.8 lw 2 lc rgb '#1976D2' title 'Accès optimisé'" >> $@
	@echo "set title \"2. Latence TLB (Pagination)\" font \",14\"" >> $@
	@echo "set xlabel \"Nombre de pages accédées (Spots)\"" >> $@
	@echo "set logscale x 2" >> $@
	@echo "set logscale y 10" >> $@
	@echo "plot 'test_run.TLB-miss-latency.data' using 1:7 with linespoints pt 7 ps 0.5 lw 1.5 title 'Stride A', \\" >> $@
	@echo "     'test_run.TLB-miss-latency.data' using 1:13 with linespoints pt 5 ps 0.5 lw 1.5 title 'Stride B'" >> $@
	@echo "unset multiplot" >> $@

run: $(TARGET)
	@echo "[INFO] Exécution du benchmark (MHZ=$(MHZ))..."
	./$(TARGET) $(MHZ) 64M test_run

plot: $(GP_SCRIPT)
	@if [ -f test_run.cache-miss-latency.data ]; then \
		echo "[INFO] Génération du graphique PDF..."; \
		gnuplot $(GP_SCRIPT); \
		echo "[SUCCESS] Fichier généré : $(OUTPUT_PDF)"; \
	else \
		echo "[ERROR] Pas de données ! Lancez 'make run' d'abord."; \
	fi

# Commande tout-en-un
benchmark: run plot

clean:
	@echo "[INFO] Nettoyage..."
	rm -f $(TARGET) test_run* results* *.pdf *.ps *.gp

help:
	@echo "Commandes disponibles :"
	@echo "  make           : Compile le programme"
	@echo "  make run       : Lance le benchmark (Défaut 3000 MHz)"
	@echo "  make plot      : Génère le beau graphique PDF"
	@echo "  make benchmark : Tout faire d'un coup"
	@echo "  make clean     : Tout effacer"
