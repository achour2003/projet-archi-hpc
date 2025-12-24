# Script gnuplot - Exercice 1 : Temps d'accès aux caches
# Projet Architecture des Processeurs Hautes Performances

# Configuration de sortie
set terminal pdfcairo enhanced font "Arial,12" size 10,6
set output "cache_latency.pdf"

# Titre et labels
set title "Temps d'accès moyen en fonction de la taille du working set" font ",14"
set xlabel "Taille des données (Ko)" font ",12"
set ylabel "Temps d'accès moyen (ns)" font ",12"

# Configuration des axes
set logscale x 2
set logscale y
set grid
set key top left box

# Style de tracé
set style line 1 lc rgb '#0060ad' lt 1 lw 2 pt 7 ps 0.5

# Ignorer les lignes de commentaires
set datafile commentschars "#"
set datafile separator ","

# Tracé des données
plot 'resultats.csv' using 1:2 with linespoints ls 1 title 'Temps accès cache'

# Message de fin
print "Graphique généré: cache_latency.pdf"
