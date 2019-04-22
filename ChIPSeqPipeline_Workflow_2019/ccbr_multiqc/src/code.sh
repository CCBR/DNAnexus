#!/bin/bash
# ccbr_multiqc 0.0.1

set -e -x -o pipefail

main() {

mkdir -p /data/
cd /data
sarfile="/data/${DX_JOB_ID}_sar.txt"
sar 5 > $sarfile &
SAR_PID=$!

dx-download-all-inputs --parallel

dx-docker run -v `pwd`/:/data -v $HOME/in:/input ewels/multiqc:1.7 /input -o /data --interactive

OutHtml=$(dx upload /data/multiqc_report.html --brief)
dx-jobutil-add-output OutHtml "$OutHtml" --class=file

kill -9 $SAR_PID
SarTxt=$(dx upload $sarfile --brief)
dx-jobutil-add-output SarTxt "$SarTxt" --class=file


}
