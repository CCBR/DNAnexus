#!/bin/bash

set -e -x -o pipefail

# ccbr_TrimQCSTAR1p_pe 0.0.1
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

    echo "Value of Read1: '$Read1'"
    echo "Value of Read2: '$Read2'"
    
    mkdir -p /data
    cd /data

    # The following line(s) use the dx command-line tool to download your file
    # inputs to the local file system using variable names for the filenames. To
    # recover the original filenames, you can use the output of "dx describe
    # "$variable" --name".
		read1=$(dx describe "$Read1" --name)
		dx download "$Read1" -o $read1
		read2=$(dx describe "$Read2" --name)
		dx download "$Read2" -o $read2

(>&2 echo "DEBUG:Listing all files in data")
(>&2 tree /data)
(>&2 echo "Done listing")

		jobid=$(dx run workflow-FQ3Y4Q80xx3v5kxK9Y1Z773q -iRead1=$read1 -iRead2=$read2 --brief --destination=/data -y)
		dx wait $jobid
		
(>&2 echo "DEBUG:Listing all files in data")
(>&2 tree /data)
(>&2 echo "Done listing")		
		
		dx download $jobid:Read1_OutHtml -o ${Read1_prefix}_fastqc.html
		dx download $jobid:Read1_OutTxt -o ${Read1_prefix}_fastqc.txt
		dx download $jobid:Read2_OutHtml -o ${Read2_prefix}_fastqc.html
		dx download $jobid:Read2_OutTxt -o ${Read2_prefix}_fastqc.txt
		
	
(>&2 echo "DEBUG:Listing all files in data")
(>&2 tree /data)
(>&2 echo "Done listing")

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

    R1_fastqc_html=$(dx upload ${Read1_prefix}_fastqc.html --brief)
    R2_fastqc_html=$(dx upload ${Read2_prefix}_fastqc.html --brief)
    R1_fastqc_txt=$(dx upload ${Read1_prefix}_fastqc.txt --brief)
    R2_fastqc_txt=$(dx upload ${Read2_prefix}_fastqc.txt --brief)

    # The following line(s) use the utility dx-jobutil-add-output to format and
    # add output variables to your job's output as appropriate for the output
    # class.  Run "dx-jobutil-add-output -h" for more information on what it
    # does.

    dx-jobutil-add-output R1_fastqc_html "$R1_fastqc_html" --class=file
    dx-jobutil-add-output R2_fastqc_html "$R2_fastqc_html" --class=file
    dx-jobutil-add-output R1_fastqc_txt "$R1_fastqc_txt" --class=file
    dx-jobutil-add-output R2_fastqc_txt "$R2_fastqc_txt" --class=file
}
