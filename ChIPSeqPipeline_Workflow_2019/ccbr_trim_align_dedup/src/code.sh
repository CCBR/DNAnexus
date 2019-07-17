#!/bin/bash

run_trim_align_dedup_lwf() {
    mkdir -p /data/
    cd /data

    infq=$(dx describe "$InFq" --name)
    dx download "$InFq" -o $infq

    genome2resources=$(dx des)

    outfilename=`echo $infq|sed "s/.fastq.gz/.trim.fastq.gz/g"`
    samplename=`echo $infq|sed "s/.fastq.gz//g"|sed "s/.R1//g"`
    nreads=${samplename}.nreads.txt

    ncpus=`nproc`

    dx-run workflow-FXfJvF00vbJ9F8G532Fk3PxP \
        -iInputFastq=$infq \
        -iGenome2Resources=$genome2resources \
        -iGenome=$genome \
        --destination=$destination
    
    
}

main() {

echo "Value of InputFastqRep1: '$InputFastqRep1'"
echo "Value of TreatmentFastqRep1: '$TreatmentFastqRep1'"
echo "Value of Genome: '$Genome'"
echo "Value of Genome2Resoures: '$Genome2Resoures'"

mkdir -p /data/
cd /data

sarfile="/data/${DX_JOB_ID}_sar.txt"
sar 5 > $sarfile &
SAR_PID=$!



subjobids=""
for i in ${InputFastqRep1} ${TreatmentFastqRep1}
do
process_job=$(dx-jobutil-new-job run_trim -iInFq="${InFq[$i]}" --instance-type="mem1_ssd1_x16" --destination="trim")
subjobids="$subjobids $process_job"
done

    # Fill in your application code here.
    #
    # To report any recognized errors in the correct format in
    # $HOME/job_error.json and exit this script, you can use the
    # dx-jobutil-report-error utility as follows:
    #
    #   dx-jobutil-report-error "My error message"
    #
    # Note however that this entire bash script is executed with -e
    # when running in the cloud, so any line which returns a nonzero
    # exit code will prematurely exit the script; if no error was
    # reported in the job_error.json file, then the failure reason
    # will be AppInternalError with a generic error message.

    # The following line(s) use the dx command-line tool to upload your file
    # outputs after you have created them on the local file system.  It assumes
    # that you have used the output field name for the filename for each output,
    # but you can change that behavior to suit your needs.  Run "dx upload -h"
    # to see more options to set metadata.


    OutFq=$(dx upload /data/$outfilename --brief)
    Nreads=$(dx upload /data/$nreads --brief)

    # The following line(s) use the utility dx-jobutil-add-output to format and
    # add output variables to your job's output as appropriate for the output
    # class.  Run "dx-jobutil-add-output -h" for more information on what it
    # does.

    dx-jobutil-add-output OutFq "$OutFq" --class=file
    dx-jobutil-add-output Nreads "$Nreads" --class=file
    
    kill -9 $SAR_PID
    SarTxt=$(dx upload $sarfile --brief)
    dx-jobutil-add-output SarTxt "$SarTxt" --class=file


}
