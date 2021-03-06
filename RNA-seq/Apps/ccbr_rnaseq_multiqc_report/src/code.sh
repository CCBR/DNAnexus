#!/bin/bash
# ccbr_rnaseq_multiqc_report 0.0.5
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

    echo "Value of FastQC_files: '${FastQC_files[@]}'"
    echo "Value of RawFastQC_files: '${RawFastQC_files[@]}'"
    echo "Value of FastqScreenDB1_files: '${FastqScreenDB1_files[@]}'"
    echo "Value of FastqScreenDB2_files: '${FastqScreenDB2_files[@]}'"
    echo "Value of Picard_duplic_files: '${Picard_duplic_files[@]}'"
    echo "Value of Picard_RNASeqMetrics_files: '${Picard_RNASeqMetrics_files[@]}'"
    echo "Value of STAR_final_out_files: '${STAR_final_out_files[@]}'"

    mkdir -p /data
    cd /data

    # Moving assets to /data/
    mv /CCBR_LOGO.png /data/
    mv /multiqc_config.yaml /data/

    dx-download-all-inputs --parallel

    (>&2 echo "Listing all files after download: $HOME/in")
    (>&2 ls -Rlarth $HOME/in/)
    (>&2 echo "Done Listing")

    mkdir -p /data/FQscreen/ /data/FQscreen2/ /data/rawQC/ /data/QC/ /data/rsem/ /data/star/ /data/logfiles/

    # Creating Symlinks from $HOME/in to similar directory structure on Biowulf
    find /home/dnanexus/in/ -type f -iname '*_db1_screen.txt' -exec ln -s {} /data/FQscreen/ \;
    find /home/dnanexus/in/ -type f -iname '*_db2_screen.txt' -exec ln -s {} /data/FQscreen2/ \;
    find /home/dnanexus/in/ -type f -iname '*.R?_fastqc.zip' -exec ln -s {} /data/rawQC/ \;
    find /home/dnanexus/in/ -type f -iname '*.trimmed_fastqc.zip' -exec ln -s {} /data/QC/ \;
    find /home/dnanexus/in/ -type f -iname '*.RnaSeqMetrics.txt' -exec ln -s {} /data/logfiles/ \;
    find /home/dnanexus/in/ -type f -iname '*.star.duplic' -exec ln -s {} /data/logfiles/ \;
    find /home/dnanexus/in/ -type f -iname '*.Log.final.out' -exec ln -s {} /data/logfiles/ \;

    (>&2 echo "File Directory Structure in /data/")
    (>&2 tree /data/)
    (>&2 echo "Done Listing")

    dx-docker run -v "$HOME/in":"$HOME/in" -v "/data":"/data" -w "/data" ewels/multiqc:v1.6 multiqc -f -c multiqc_config.yaml --interactive  -d .  -n multiqc_report.html -v

    OutHtml=$(dx upload /data/multiqc_report.html --brief)

    dx-jobutil-add-output OutHtml "$OutHtml" --class=file
}
