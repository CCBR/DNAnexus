#!/bin/bash
# ccbr_macs_pe_peakcalling 0.0.1
set -e -x -o pipefail
pkill dstat
interval_in_seconds=10
/usr/bin/dx-dstat $interval_in_seconds

main() {

echo "Value of TreatmentBam: '$TreatmentBam'"
echo "Value of InputBam: '$InputBam'"
echo "Value of Genome: '$Genome'"
echo "Value of Broad: $Broad"

mkdir -p /data
cd /data
cpus=`nproc`

sarfile="/data/${DX_JOB_ID}_sar.txt"
sar 5 > $sarfile &
SAR_PID=$!

genome2resources=$(dx describe "$Genome2Resources" --name)
dx download "$Genome2Resources" -o $genome2resources

genomesize=$(python /get_fileid.py $Genome 'effectiveSize' $genome2resources)

t_bam=$(dx describe "$TreatmentBam" --name)
dx download "$TreatmentBam" -o $t_bam
i_bam=$(dx describe "$InputBam" --name)
dx download "$InputBam" -o $i_bam

outname=${t_bam}_vs_${i_bam}

if [ $Broad ]
then
    broadPeak=${outname}_peaks.broadPeak
    broadPeakBed=${outname}_peaks.broadPeak.bed
    #call broad peaks
    dx-docker run -v /data/:/data nciccbr/ccbr_macs:v0.0.4 ccbr_macs_callpeak_pe.bash --treatment $t_bam --input $i_bam --outprefix $outname --genomesize $genomesize --broad
    Peak=$(dx upload /data/$broadPeak --brief)
    PeakBed=$(dx upload /data/$broadPeakBed --brief)
else
    narrowPeak=${outname}_peaks.narrowPeak
    narrowPeakBed=${outname}_peaks.narrowPeak.bed
    #call narrow peaks
    dx-docker run -v /data/:/data nciccbr/ccbr_macs:v0.0.4 ccbr_macs_callpeak_pe.bash --treatment $t_bam --input $i_bam --outprefix $outname --genomesize $genomesize  
    Peak=$(dx upload /data/$narrowPeak --brief)
    PeakBed=$(dx upload /data/$narrowPeakBed --brief)
fi

dx-jobutil-add-output Peak "$Peak" --class=file
dx-jobutil-add-output PeakBed "$PeakBed" --class=file

kill -9 $SAR_PID
# SarTxt=$(dx upload $sarfile --brief)
# dx-jobutil-add-output SarTxt "$SarTxt" --class=file
}
