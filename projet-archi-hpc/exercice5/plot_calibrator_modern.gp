# Script auto-généré
set terminal pdfcairo enhanced font "Arial,12" size 10,10
set output "calibrator_results.pdf"
set datafile commentschars "#"
set multiplot layout 2,1 title "Analyse Calibrator (Intel i7-13650HX)"
set title "1. Latence Mémoire par Taille de Buffer" font ",14"
set xlabel "Taille du buffer (Ko)"
set ylabel "Latence (ns)"
set logscale x 2
set logscale y 10
set grid xtics ytics mytics
set format x "%.0s%c"
set key top left box
plot 'test_run.cache-miss-latency.data' using (1024*$1):7 with linespoints pt 7 ps 0.8 lw 2 lc rgb '#D32F2F' title 'Accès séquentiel', \
     'test_run.cache-miss-latency.data' using (1024*$1):13 with linespoints pt 5 ps 0.8 lw 2 lc rgb '#1976D2' title 'Accès optimisé'
set title "2. Latence TLB (Pagination)" font ",14"
set xlabel "Nombre de pages accédées (Spots)"
set logscale x 2
set logscale y 10
plot 'test_run.TLB-miss-latency.data' using 1:7 with linespoints pt 7 ps 0.5 lw 1.5 title 'Stride A', \
     'test_run.TLB-miss-latency.data' using 1:13 with linespoints pt 5 ps 0.5 lw 1.5 title 'Stride B'
unset multiplot
