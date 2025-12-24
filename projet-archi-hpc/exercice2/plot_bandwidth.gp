# Script gnuplot - Exercice 2 : Bande passante mémoire
# Projet Architecture des Processeurs Hautes Performances

# Configuration de sortie
set terminal pdfcairo enhanced font "Arial,12" size 10,6
set output "bandwidth.pdf"

# Titre et labels
set title "Bande passante mémoire en fonction du pas d'accès" font ",14"
set xlabel "Pas d'accès (Ko)" font ",12"
set ylabel "Bande passante (Go/s)" font ",12"

# Configuration des axes
set logscale x 2
set grid
set key top right box

# Style de tracé
set style line 1 lc rgb '#dd181f' lt 1 lw 2 pt 5 ps 1

# Ignorer les commentaires
set datafile commentschars "#"
set datafile separator ","

# Tracé - première section du fichier
plot 'resultats.csv' every ::1 using 1:3 with linespoints ls 1 title 'Bande passante'

# Second graphique : bande passante séquentielle
set output "bandwidth_seq.pdf"
set title "Bande passante séquentielle en fonction de la taille du buffer" font ",14"
set xlabel "Taille du buffer (Mo)" font ",12"
set ylabel "Bande passante (Go/s)" font ",12"

set style line 2 lc rgb '#0060ad' lt 1 lw 2 pt 7 ps 1

# Trouver la section séquentielle (après la ligne vide)
# Note: vous devrez peut-être séparer manuellement les données

print "Graphiques générés: bandwidth.pdf et bandwidth_seq.pdf"
