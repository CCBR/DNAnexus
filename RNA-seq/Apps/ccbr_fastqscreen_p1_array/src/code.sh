#!/bin/bash
set -e -x -o pipefail
# ccbr_fastqscreen_p1_array 0.0.1
# See https://wiki.dnanexus.com/Developer-Portal for tutorials on how
# to modify this file.

main() {

	# Create data directory
	mkdir -p /data
	cd /data

	cpus=`nproc`

	# Create output directories for uploading in parallel
	mkdir -p $HOME/out/OutTxt
	mkdir -p $HOME/out/OutPng
	mkdir -p $HOME/out/OutHtml

	# Downloading Resources
	dx download project-FPkJp0Q0xx3Y9XXKKzB0408Y:file-FQ3BFy00xx3q68f5B0x3j17Q -o db.tar.gz
	pigz -p $cpus -dc db.tar.gz |tar xf -

	(>&2 echo "Listing all files in data")
	(>&2 tree /data)
	(>&2 echo "Done listing")

	echo "Value of InFq: '${InFq[@]}'"

	# The following line(s) use the dx command-line tool to download your file
	# inputs to the local file system using variable names for the filenames. To
	# recover the original filenames, you can use the output of "dx describe
	# "$variable" --name".

	for i in ${!InFq[@]}
	do
		infq=$(dx describe "${InFq[$i]}" --name)
		echo "Downloading: '${InFq[$i]}'"
		dx download "${InFq[$i]}" -o $infq
	done

	(>&2 echo "Listing all files in /data after downloading them")
	(>&2 tree /data)
	(>&2 echo "Done listing")

	cpus=`nproc`
	dx-docker run -v /data/:/data kopardev/ccbr_fastq_screen_0.13.0 fastq_screen --conf `ls *.conf` `ls *.fastq.gz|sort` --threads $cpus --aligner bowtie2 --subset 1000000

	# Renaming the output files
	for f in `ls *_screen.*`;do
		g=`echo $f|sed "s/_screen/_db1_screen/g"`
		mv $f $g
	done

	(>&2 echo "Listing all files in /data after running fastq_screen")
	(>&2 tree /data)
	(>&2 echo "Done listing")

	# Moving the output files to the output directories for parallel upload
	mv *.txt $HOME/out/OutTxt
	mv *.png $HOME/out/OutPng
	mv *.html $HOME/out/OutHtml

	(>&2 echo "Listing all files in the output directories")
	(>&2 tree $HOME/out)
	(>&2 echo "Done listing")

	dx-upload-all-outputs --parallel

}
