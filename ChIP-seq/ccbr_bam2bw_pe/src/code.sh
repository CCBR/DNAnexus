#!/bin/bash
set -e -x -o pipefail
pkill dstat
interval_in_seconds=10
/usr/bin/dx-dstat $interval_in_seconds

main() {

    echo "Value of Genome: '$Genome'"
    echo "Value of TreatmentBam: '$TreatmentBam'"
	echo "Value of InputBam: '$InputBam'"

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

genomesize=$(python /get_fileid.py $Genome 'effectiveSize' $genome2resources)

treatmentbw=`echo $treatmentbam|sed "s/.bam/.bw/g"`
inputbw=`echo $inputbam|sed "s/.bam/.bw/g"`
inputnormbw=`echo $treatmentbam|sed "s/.bam/.inputnorm.bw/g"`

dx-docker run \
-v /data/:/data \
nciccbr/ccbr_deeptools:v0.0.6 ccbr_bam2bw_pe.bash \
--treatmentbam $treatmentbam \
--inputbam $inputbam \
--effectivegenomesize $genomesize \
--ncpus $cpus


    TreatmentBigwig=$(dx upload /data/$treatmentbw --brief)
    InputBigwig=$(dx upload /data/$inputbw --brief)
    InputNormBigwig=$(dx upload /data/$inputnormbw --brief)


    dx-jobutil-add-output TreatmentBigwig "$TreatmentBigwig" --class=file
    dx-jobutil-add-output InputBigwig "$InputBigwig" --class=file
    dx-jobutil-add-output InputNormBigwig "$InputNormBigwig" --class=file

    kill -9 $SAR_PID
    # SarTxt=$(dx upload $sarfile --brief)
    # dx-jobutil-add-output SarTxt "$SarTxt" --class=file

}
