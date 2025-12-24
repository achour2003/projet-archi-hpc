# Makefile - Exercice 5 : Outil Calibrator
# Projet Architecture des Processeurs Hautes Performances

CC = gcc
CFLAGS = -O2 -Wall -march=native
LDFLAGS = -lm

TARGET = calibrator
SRC = calibrator.c
RESULTS_PREFIX = results

# Fréquence CPU en MHz (À ADAPTER à votre machine)
# Utilisez: cat /proc/cpuinfo | grep MHz
# Ou: lscpu | grep "CPU MHz"
CPU_MHZ = 3000

# Taille max du test (doit dépasser 2x le dernier cache)
MAX_SIZE = 64M

.PHONY: all clean run plot help info

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

# Afficher les informations CPU pour configurer MHz
info:
	@echo "=== Informations CPU ==="
	@lscpu | grep -E "(Model name|CPU MHz|CPU max MHz|cache)"
	@echo ""
	@echo "=== Fréquence actuelle ==="
	@cat /proc/cpuinfo | grep "cpu MHz" | head -1
	@echo ""
	@echo "Modifiez CPU_MHZ dans le Makefile avec la valeur appropriée"

run: $(TARGET)
	@echo "Exécution de Calibrator..."
	@echo "CPU_MHZ=$(CPU_MHZ), MAX_SIZE=$(MAX_SIZE)"
	@echo "Conseil: désactivez le scaling de fréquence avant le test"
	./$(TARGET) $(CPU_MHZ) $(MAX_SIZE) $(RESULTS_PREFIX)

# Génération des graphiques à partir des scripts gnuplot générés par Calibrator
plot:
	@if [ -f $(RESULTS_PREFIX).cache-miss-latency.gp ]; then \
		gnuplot $(RESULTS_PREFIX).cache-miss-latency.gp 2>/dev/null || \
		echo "Note: gnuplot a généré des avertissements (normal)"; \
	fi
	@if [ -f $(RESULTS_PREFIX).cache-replace-time.gp ]; then \
		gnuplot $(RESULTS_PREFIX).cache-replace-time.gp 2>/dev/null || \
		echo "Note: gnuplot a généré des avertissements (normal)"; \
	fi
	@if [ -f $(RESULTS_PREFIX).TLB-miss-latency.gp ]; then \
		gnuplot $(RESULTS_PREFIX).TLB-miss-latency.gp 2>/dev/null || \
		echo "Note: gnuplot a généré des avertissements (normal)"; \
	fi
	@echo "Graphiques générés (fichiers .ps ou .pdf selon la config gnuplot)"

benchmark: run plot

clean:
	rm -f $(TARGET)
	rm -f $(RESULTS_PREFIX)*.data
	rm -f $(RESULTS_PREFIX)*.gp
	rm -f $(RESULTS_PREFIX)*.ps
	rm -f $(RESULTS_PREFIX)*.pdf

help:
	@echo "Cibles disponibles:"
	@echo "  all       - Compile Calibrator"
	@echo "  info      - Affiche les infos CPU pour configurer MHz"
	@echo "  run       - Exécute Calibrator"
	@echo "  plot      - Génère les graphiques"
	@echo "  benchmark - Compile, exécute et génère les graphiques"
	@echo "  clean     - Nettoie les fichiers générés"
	@echo ""
	@echo "Configuration:"
	@echo "  CPU_MHZ   = $(CPU_MHZ) (à adapter)"
	@echo "  MAX_SIZE  = $(MAX_SIZE)"
	@echo ""
	@echo "Usage:"
	@echo "  make CPU_MHZ=3500 run"
