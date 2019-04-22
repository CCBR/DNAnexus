#!/bin/bash
set -e -x -o pipefail
# ccbr_bigwig_correlation_plots 1)heatmap 2)scatterplot


main() {

mkdir -p /data
cd /data
cpus=`nproc`

sarfile="/data/${DX_JOB_ID}_sar.txt"
sar 5 > $sarfile &
SAR_PID=$!

treatmentbigwigrep1=$(dx describe "$TreatmentBigwigRep1" --name)
dx download "$TreatmentBigwigRep1" -o $treatmentbigwigrep1
inputbigwigrep1=$(dx describe "$InputBigwigRep1" --name)
dx download "$InputBigwigRep1" -o $inputbigwigrep1
treatmentbigwigrep2=$(dx describe "$TreatmentBigwigRep2" --name)
dx download "$TreatmentBigwigRep2" -o $treatmentbigwigrep2
inputbigwigrep2=$(dx describe "$InputBigwigRep2" --name)
dx download "$InputBigwigRep2" -o $inputbigwigrep2

heatmap=bigwig_correlation_heatmap.pdf
scatterplot=bigwig_correlation_scatterplot.pdf

dx-docker run -v /data/:/data nciccbr/ccbr_deeptools:v0.0.5 /opt/ccbr_bigwigcorrelation_2replicates.bash \
--treatmentbigwigrep1 $treatmentbigwigrep1 \
--treatmentbigwigrep2 $treatmentbigwigrep2 \
--inputbigwigrep1 $inputbigwigrep1 \
--inputbigwigrep2 $inputbigwigrep2 \
--ncpus $cpus

CorrelationHeatmap=$(dx upload /data/$heatmap --brief)
CorrelationScatterPlot=$(dx upload /data/$scatterplot --brief)

dx-jobutil-add-output CorrelationHeatmap "$CorrelationHeatmap" --class=file
dx-jobutil-add-output CorrelationScatterPlot "$CorrelationScatterPlot" --class=file

kill -9 $SAR_PID
SarTxt=$(dx upload $sarfile --brief)
dx-jobutil-add-output SarTxt "$SarTxt" --class=file
}
