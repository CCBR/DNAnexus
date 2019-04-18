#!/bin/bash
# ccbr_bwa_align_se 0.0.1
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

    echo "Value of Genome: '$Genome'"
    echo "Value of Genome2Resources: '$Genome2Resources'"
    echo "Value of InFq: '$InFq'"

    # The following line(s) use the dx command-line tool to download your file
    # inputs to the local file system using variable names for the filenames. To
    # recover the original filenames, you can use the output of "dx describe
    # "$variable" --name".

mkdir -p /data
cd /data

sarfile="/data/${DX_JOB_ID}_sar.txt"
sar 5 > $sarfile &
SAR_PID=$!

infq=$(dx describe "$InFq" --name)
dx download "$InFq" -o $infq

genome2resources=$(dx describe "$Genome2Resources" --name)
dx download "$Genome2Resources" -o $genome2resources

nreads=$(dx describe "$Nreads" --name)
dx download "$Nreads" -o $nreads

# download and untar genome bwa index
RefTarGz=$(python /get_fileid.py $Genome 'bwa' $genome2resources)
reftargz=$(dx describe "$RefTarGz" --name)
dx download "$RefTarGz" -o $reftargz
tar xzvf $reftargz

# download and untar blacklist bwa index
BlacklistTarGz=$(python /get_fileid.py $Genome 'blacklist_bwa' $genome2resources)
blacklisttargz=$(dx describe "$BlacklistTarGz" --name)
dx download "$BlacklistTarGz" -o $blacklisttargz
tar xzvf $blacklisttargz

(>&2 echo "DEBUG:Listing all files in data")
(>&2 ls -larth)
(>&2 echo "Done listing")

cpus=`nproc`
basefilename=`echo $infq|sed "s/.fastq.gz//g"`
bamfile=${basefilename}.bam
sortedbamfile=${basefilename}.sorted.bam
sortedbambaifile=${sortedbamfile}.bai
sortedq5bamfile=${basefilename}.sorted.Q5.bam
sortedq5bambaifile=${basefilename}.sorted.Q5.bam.bai
sortedbamflagstatfile=${sortedbamfile}.flagstat
sortedq5bamflagstatfile=${sortedq5bamfile}.flagstat

dx-docker run -v /data/:/data nciccbr/ccbr_bwa:v0.0.2 ccbr_bwa_chipseq_align_se.bash --genome $Genome --infastq $infq
cat nreads.txt >> $nreads

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



    SortedBam=$(dx upload /data/$sortedbamfile --brief)
    SortedBamBai=$(dx upload /data/$sortedbambaifile --brief)
    SortedQ5Bam=$(dx upload /data/$sortedq5bamfile --brief)
    SortedQ5BamBai=$(dx upload /data/$sortedq5bambaifile --brief)
    SortedBamFlagstat=$(dx upload /data/$sortedbamflagstatfile --brief)
    SortedQ5BamFlagstat=$(dx upload /data/$sortedq5bamflagstatfile --brief)
    OutNreads=$(dx upload /data/$nreads --brief)

    # The following line(s) use the utility dx-jobutil-add-output to format and
    # add output variables to your job's output as appropriate for the output
    # class.  Run "dx-jobutil-add-output -h" for more information on what it
    # does.

    dx-jobutil-add-output SortedBam "$SortedBam" --class=file
    dx-jobutil-add-output SortedBamBai "$SortedBamBai" --class=file
    dx-jobutil-add-output SortedQ5Bam "$SortedQ5Bam" --class=file
    dx-jobutil-add-output SortedQ5BamBai "$SortedQ5BamBai" --class=file
    dx-jobutil-add-output SortedBamFlagstat "$SortedBamFlagstat" --class=file
    dx-jobutil-add-output SortedQ5BamFlagstat "$SortedQ5BamFlagstat" --class=file
    dx-jobutil-add-output OutNreads "$OutNreads" --class=file

    kill -9 $SAR_PID
    SarTxt=$(dx upload $sarfile --brief)
    dx-jobutil-add-output SarTxt "$SarTxt" --class=file
}
