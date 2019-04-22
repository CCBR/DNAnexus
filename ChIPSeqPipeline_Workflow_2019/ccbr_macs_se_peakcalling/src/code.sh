#!/bin/bash
# ccbr_macs_se_peakcalling 0.0.1


main() {

echo "Value of TreatmentTagAlign: '$TreatmentTagAlign'"
echo "Value of TreatmentPPQT: '$TreatmentPPQT'"
echo "Value of InputTagAlign: '$InputTagAlign'"
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

t_tagalign=$(dx describe "$TreatmentTagAlign" --name)
dx download "$TreatmentTagAlign" -o $t_tagalign
t_ppqt=$(dx describe "$TreatmentPPQT" --name)
dx download "$TreatmentPPQT" -o $t_ppqt
i_tagalign=$(dx describe "$InputTagAlign" --name)
dx download "$InputTagAlign" -o $i_tagalign

outname=${t_tagalign}_vs_${i_tagalign}
if [ $Broad ]
then
    broadPeak=${outname}_peaks.broadPeak
    broadPeakBed=${outname}_peaks.broadPeak.bed
    #call broad peaks
    dx-docker run -v /data/:/data nciccbr/ccbr_macs:v0.0.3 ccbr_macs_callpeak_se.bash --treatment $t_tagalign --input $i_tagalign --outprefix $outname --genomesize $genomesize --treatmentppqt $t_ppqt --broad
    Peak=$(dx upload /data/$broadPeak --brief)
    PeakBed=$(dx upload /data/$broadPeakBed --brief)
else
    narrowPeak=${outname}_peaks.narrowPeak
    narrowPeakBed=${outname}_peaks.narrowPeak.bed
    #call narrow peaks
    dx-docker run -v /data/:/data nciccbr/ccbr_macs:v0.0.3 ccbr_macs_callpeak_se.bash --treatment $t_tagalign --input $i_tagalign --outprefix $outname --genomesize $genomesize --treatmentppqt $t_ppqt 
    Peak=$(dx upload /data/$narrowPeak --brief)
    PeakBed=$(dx upload /data/$narrowPeakBed --brief)
fi

dx-jobutil-add-output Peak "$Peak" --class=file
dx-jobutil-add-output PeakBed "$PeakBed" --class=file

kill -9 $SAR_PID
SarTxt=$(dx upload $sarfile --brief)
dx-jobutil-add-output SarTxt "$SarTxt" --class=file
}
