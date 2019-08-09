#!/bin/bash
# ccbr_create_star_index 0.0.1
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

    echo "Value of RefFa: '$RefFa'"
    echo "Value of GenesGTF: '$GenesGTF'"
    echo "Value of GenomeName: '$GenomeName'"

    # The following line(s) use the dx command-line tool to download your file
    # inputs to the local file system using variable names for the filenames. To
    # recover the original filenames, you can use the output of "dx describe
    # "$variable" --name".

#     dx download "$RefFa" -o RefFa
# 
#     dx download "$GenesGTF" -o GenesGTF

cd /
(>&2 echo "DEBUG:Listing all files in root")
(>&2 ls -larth)
(>&2 echo "Done listing")


mkdir -p /data/
cd /data
(>&2 echo "DEBUG:Listing all files in data")
(>&2 ls -larth)
(>&2 echo "Done listing")

(>&2 echo "Downloading")

dx download "$RefFa" -o ref.fa
dx download "$GenesGTF" -o genes.gtf
cpus=`nproc`

mkdir -p ~/out/OutTarGzs

for readlength in 50 75 100 125 150;
do
	mkdir ./genes-${readlength}
	dx-docker run -v /data/:/data nciccbr/ccbr_star_2.7.0f:v0.0.1 STAR \
	--runThreadN $cpus \
	--runMode genomeGenerate \
	--genomeDir ./genes-${readlength} \
	--genomeFastaFiles ./ref.fa \
	--sjdbGTFfile ./genes.gtf \
	--sjdbOverhang `echo $readlength|awk '{print $1-1}'`
	tar czvf ${GenomeName}_${readlength}.tar.gz genes-${readlength}
	ls -alrth
	mv ${GenomeName}_${readlength}.tar.gz ~/out/OutTarGzs/
	ls -larth ~/out/OutTarGzs
done

(>&2 echo "DEBUG:Listing all files in data")
(>&2 ls -larth)
(>&2 echo "Done listing")

dx-upload-all-outputs

}