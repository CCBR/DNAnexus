#!/bin/bash
set -e -x -o pipefail
# ccbr_fingerprint_plot


main() {

mkdir -p /data
cd /data
cpus=`nproc`

sarfile="/data/${DX_JOB_ID}_sar.txt"
sar 5 > $sarfile &
SAR_PID=$!

genome2resources=$(dx describe "$Genome2Resources" --name)
dx download "$Genome2Resources" -o $genome2resources
treatmentbam=$(dx describe "$TreatmentBam" --name)
dx download "$TreatmentBam" -o $treatmentbam
inputbam=$(dx describe "$InputBam" --name)
dx download "$InputBam" -o $inputbam
treatmentbigwig=$(dx describe "$TreatmentBigwig" --name)
dx download "$TreatmentBigwig" -o $treatmentbigwig
inputbigwig=$(dx describe "$InputBigwig" --name)
dx download "$InputBigwig" -o $inputbigwig

GenesBed=$(python /get_fileid.py $Genome 'genesBed' $genome2resources)
genesBed=$(dx describe "$GenesBed" --name)
dx download "$GenesBed" -o $genesBed

t_label=${treatmentbam%%.*}
i_label=${inputbam%%.*}
fingerprintplot=${treatmentbam%.*}_vs_${inputbam%.*}.fingerprint.pdf
metageneheatmap=${treatmentbam%.*}_vs_${inputbam%.*}.metageneheatmap.pdf
metageneprofileplot=${treatmentbam%.*}_vs_${inputbam%.*}.metageneprofile.pdf

cpus=`nproc`

treatmentsortedbam=`echo $treatmentbam|sed "s/.bam/.sorted.bam/g"`
inputsortedbam=`echo $inputbam|sed "s/.bam/.sorted.bam/g"`

dx-docker run -v /data/:/data nciccbr/ccbr_deeptools:v0.0.4 /opt/ccbr_fingerprintplot.bash \
--treatmentbam $treatmentbam \
--treatmentbigwig $treatmentbigwig \
--inputbam $inputbam \
--inputbigwig $inputbigwig \
--genesbed $genesBed \
--ncpus $cpus

FingerPrintPlot=$(dx upload /data/$fingerprintplot --brief)
MetageneHeatMap=$(dx upload /data/$metageneheatmap --brief)
MetageneProfilePlot=$(dx upload /data/$metageneprofileplot --brief)


dx-jobutil-add-output FingerPrintPlot "$FingerPrintPlot" --class=file
dx-jobutil-add-output MetageneHeatMap "$MetageneHeatMap" --class=file
dx-jobutil-add-output MetageneProfilePlot "$MetageneProfilePlot" --class=file

kill -9 $SAR_PID
SarTxt=$(dx upload $sarfile --brief)
dx-jobutil-add-output SarTxt "$SarTxt" --class=file
}
