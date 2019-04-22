#!/bin/bash
# ccbr_fastqc 0.0.1

main() {

echo "Value of InFq: '$InFq'"
mkdir -p /data
cd /data
cpus=`nproc`

sarfile="/data/${DX_JOB_ID}_sar.txt"
sar 5 > $sarfile &
SAR_PID=$!

InFq=$(dx describe "$InFq" --name)
dx download "$InFq" -o $InFq

dx-docker run -v /data/:/data nciccbr/fastqc:v0.0.1 fastqc -f fastq --extract --threads $cpus $InFq

result_base=`echo $InFq|awk -F".fastq" '{print $1}'`
outHtml=${result_base}_fastqc.html
outTxt=${result_base}_fastqc.txt
mv ${result_base}_fastqc/fastqc_data.txt $outTxt

OutHtml=$(dx upload /data/$outHtml --brief)
OutTxt=$(dx upload /data/$outTxt --brief)

dx-jobutil-add-output OutHtml "$OutHtml" --class=file
dx-jobutil-add-output OutTxt "$OutTxt" --class=file

kill -9 $SAR_PID
SarTxt=$(dx upload $sarfile --brief)
dx-jobutil-add-output SarTxt "$SarTxt" --class=file
}
