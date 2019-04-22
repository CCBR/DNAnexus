#!/bin/bash
# ccbr_ppqt 0.0.1
# Generated by dx-app-wizard.
#
# Basic execution pattern: Your app will run on a single machine from
# beginning to end.
#
# Your job's input variables (if any) will be loaded as environment
# variables before this script runs.  Any array inputs will be loaded
# as bash arrays.
#
# Any code outside of main() (or any entry point you may add) is
# ALWAYS executed, followed by running the entry point itself.
#
# See https://wiki.dnanexus.com/Developer-Portal for tutorials on how
# to modify this file.

main() {

    echo "Value of Bam: '$Bam'"

mkdir -p /data
cd /data
cpus=`nproc`

sarfile="/data/${DX_JOB_ID}_sar.txt"
sar 5 > $sarfile &
SAR_PID=$!

bam=$(dx describe "$Bam" --name)
dx download "$Bam" -o $bam

bambase=${bam%.*}

ccurve=${bambase}.c_curve
nrf=${bambase}.nrf.txt
idxstats=${bam}.idxstats

dx-docker run -v /data/:/data nciccbr/ccbr_preseq:v0.0.1 ccbr_chipseq_preseq.bash --bam=$bam --ncpus=$cpus

    CCurve=$(dx upload /data/$ccurve --brief)
    NRF=$(dx upload /data/$nrf --brief)
    IdxStats=$(dx upload /data/$idxstats --brief)

    dx-jobutil-add-output CCurve "$CCurve" --class=file
    dx-jobutil-add-output NRF "$NRF" --class=file
    dx-jobutil-add-output IdxStats "$IdxStats" --class=file

    kill -9 $SAR_PID
    SarTxt=$(dx upload $sarfile --brief)
    dx-jobutil-add-output SarTxt "$SarTxt" --class=file
}