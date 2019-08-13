#!/bin/bash
# ccbr_chipseq_TAD
# Generated by dx-app-wizard.
#
main() {

    echo "Value of InFqR1: '$InFqR1'"
    echo "Value of InFqR2: '$InFqR2'"
    echo "Value of Genome2Resources: '$Genome2Resources'"
    echo "Value of Genome: '$Genome'"
    echo "Value of SampleName: '$SampleName'"


mkdir -p /data
cd /data

sarfile="/data/${DX_JOB_ID}_sar.txt"
sar 5 > $sarfile &
SAR_PID=$!

infqr1=$(dx describe "$InFqR1" --name)
dx download "$InFqR1" -o $infqr1
infqr2=$(dx describe "$InFqR2" --name)
dx download "$InFqR2" -o $infqr2


genome2resources=$(dx describe "$Genome2Resources" --name)
dx download "$Genome2Resources" -o $genome2resources

# download and untar genome bwa index
RefTarGz=$(python /get_fileid.py $Genome 'bwa' $genome2resources)
reftargz=$(dx describe "$RefTarGz" --name)
mkdir -p /index 
cd /index
dx download "$RefTarGz" -o $reftargz
tar xzvf $reftargz
cd /data


ncpus=`nproc`


dx-docker run \
-v /data/:/data \
-v /index/:/index \
nciccbr/ccbr_chipseq_trim_align_dedup:v0.0.1 /opt/ccbr_chipseq_trim_align_dedup_pe.bash \
--samplename $SampleName \
--infastq1 $infqr1 \
--infastq2 $infqr2 \
--genome $Genome


bambase=${SampleName}.Q5
ccurve=${bambase}.c_curve
nrf=${bambase}.nrf.txt
idxstats=${bambase}.bam.idxstats

dx-docker run \
-v /data/:/data \
nciccbr/ccbr_preseq:v0.0.1 ccbr_chipseq_preseq.bash \
--bam=${bambase}.bam \
--ncpus=$ncpus \
--paired

    (>&2 echo "DEBUG:Listing all files in data")
    (>&2 ls -larth)
    (>&2 echo "Done listing")


Q5bam=$(dx upload /data/${SampleName}.Q5.bam --brief)
Q5flagstat=$(dx upload /data/${SampleName}.Q5.bam.flagstat --brief)
Q5DDbam=$(dx upload /data/${SampleName}.Q5DD.bam --brief)
Q5DDflagstat=$(dx upload /data/${SampleName}.Q5DD.bam.flagstat --brief)
r1fastqzip=`echo $infqr1|awk -F".fastq" '{printf("%s_fastqc.zip",$1)}'`
r2fastqzip=`echo $infqr2|awk -F".fastq" '{printf("%s_fastqc.zip",$1)}'`
r1fastqhtml=${r1fastqzip%.*}.html
r2fastqhtml=${r2fastqzip%.*}.html
R1fastqzip=$(dx upload /data/$r1fastqzip --brief)
R2fastqzip=$(dx upload /data/$r2fastqzip --brief)
noblr1fastqzip=${SampleName}.R1.noBL_fastqc.zip
noblr2fastqzip=${SampleName}.R2.noBL_fastqc.zip
noBLR1fastqzip=$(dx upload /data/$noblr1fastqzip --brief)
noBLR2fastqzip=$(dx upload /data/$noblr2fastqzip --brief)
nreads=${SampleName}.nreads.txt
Nreads=$(dx upload /data/$nreads --brief)
    CCurve=$(dx upload /data/$ccurve --brief)
    NRF=$(dx upload /data/$nrf --brief)
    IdxStats=$(dx upload /data/$idxstats --brief)


    dx-jobutil-add-output Q5bam "$Q5bam" --class=file
    dx-jobutil-add-output Q5flagstat "$Q5flagstat" --class=file
    dx-jobutil-add-output Q5DDbam "$Q5DDbam" --class=file
    dx-jobutil-add-output Q5DDflagstat "$Q5DDflagstat" --class=file
    dx-jobutil-add-output R1fastqzip "$R1fastqzip" --class=file
    dx-jobutil-add-output R2fastqzip "$R2fastqzip" --class=file
    dx-jobutil-add-output noBLR1fastqzip "$noBLR1fastqzip" --class=file
    dx-jobutil-add-output noBLR2fastqzip "$noBLR2fastqzip" --class=file
    dx-jobutil-add-output Nreads "$Nreads" --class=file
    dx-jobutil-add-output CCurve "$CCurve" --class=file
    dx-jobutil-add-output NRF "$NRF" --class=file
    dx-jobutil-add-output IdxStats "$IdxStats" --class=file


    kill -9 $SAR_PID
#    SarTxt=$(dx upload $sarfile --brief)
#    dx-jobutil-add-output SarTxt "$SarTxt" --class=file


}
