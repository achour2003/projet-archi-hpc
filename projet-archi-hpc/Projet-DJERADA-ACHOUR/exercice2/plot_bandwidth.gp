set datafile commentschars "#"
set datafile separator ","
set terminal pdfcairo enhanced font "Arial,12" size 10,6

# Graphique 1 : Lecture de resultats.csv (standard)
set output "bandwidth.pdf"
set title "Bande passante vs Pas (i7-13650HX)"
set xlabel "Pas (Ko)"
set ylabel "Go/s"
set logscale x 2
set xrange [0.05:4096]
set yrange [0:40]
set grid
set style line 1 lc rgb '#dd181f' lt 1 lw 2 pt 7
plot 'resultats.csv' using 1:3 with linespoints ls 1 title 'Pas'

# Graphique 2 : Lecture de resultats_seq.csv (nouveau fichier)
set output "bandwidth_seq.pdf"
set title "Bande passante Séquentielle (L3 = 24 Mo)"
set xlabel "Taille Buffer (Mo)"
unset logscale x
set xrange [0:100]
set yrange [0:35]
set arrow from 24,0 to 24,35 nohead lt 0 lw 2 lc rgb "red"
set label "L3" at 25,5 tc rgb "red"
set style line 2 lc rgb '#0060ad' lt 1 lw 2 pt 7
plot 'resultats_seq.csv' using 1:2 with linespoints ls 2 title 'Seq'
