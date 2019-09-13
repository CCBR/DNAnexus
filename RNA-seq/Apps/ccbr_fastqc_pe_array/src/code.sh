#!/bin/bash

set -e -x -o pipefail
# The -e flag causes bash to exit at any point if there is any error, 
# the -o pipefail flag tells bash to throw an error if it encounters an error within a pipeline, 
# while the -x flag causes bash to output each line as it is executed -- useful for debugging

# ccbr_fastqc_pe_array 0.0.1

run_fastqc() {
        # myfunc only gets called when invoked by main (or by another
        # entry point)
	mkdir -p /data
	cd /data
	echo $input_fastq
	infq=$(dx describe "$input_fastq" --name)
	dx download "$input_fastq" -o $infq
	cpus=`nproc`
	dx-docker run -v /data/:/data kopardev/fastqc_0.11.8 fastqc --extract --threads $cpus $infq
	outhtml=`echo $infq|sed "s/.gz//g"|sed "s/.fastq/_fastqc_report.html/g"`
	outtxt=`echo $infq|sed "s/.gz//g"|sed "s/.fastq/_fastqc_data.txt/g"`
	outzip=`echo $infq|sed "s/.gz//g"|sed "s/.fastq/_fastqc.zip/g"`

	cd *_fastqc
	outdir=`pwd`
	mv fastqc_report.html $outhtml
	mv fastqc_data.txt $outtxt
        cd ..
        OutZip=$(dx upload ${outzip} --brief)
	OutHtml=$(dx upload ${outdir}/${outhtml} --brief)
	OutTxt=$(dx upload ${outdir}/${outtxt} --brief)
	dx-jobutil-add-output OutHtml "$OutHtml" --class=file
	dx-jobutil-add-output OutTxt "$OutTxt" --class=file
	dx-jobutil-add-output OutZip "$OutZip" --class=file
}


main() {

echo "Value of file: '${InFq[@]}'"


mkdir -p /data
cd /data
mkdir -p $HOME/out
mkdir -p $HOME/out/OutHtml
mkdir -p $HOME/out/OutTxt
mkdir -p $HOME/out/OutZip

(>&2 echo "DEBUG:Listing all files in root")
(>&2 ls -larth)
(>&2 echo "Done listing")

subjobids=""
for i in ${!InFq[@]}
do
	process_job=$(dx-jobutil-new-job run_fastqc -iinput_fastq="${InFq[$i]}" --instance-type="mem1_ssd1_x16")
	echo "Value of process_job: '$process_job'"
	subjobids="$subjobids $process_job"
done

count=0
for i in $subjobids
do
	infq=$(dx describe "${InFq[$count]}" --name)
	echo "Waiting for ",$i
	dx wait $i
	echo "Downloading html"
	outname_base="${InFq_prefix[$count]}"
	dx download $i:OutHtml -o $HOME/out/OutHtml/${outname_base}_fastqc_report.html
	echo "Downloading txt"
	dx download $i:OutTxt -o $HOME/out/OutTxt/${outname_base}_fastqc_data.txt
        echo "Downloading Zip"
        dx download $i:OutZip -o $HOME/out/OutZip/${outname_base}_fastqc.zip
	count=$((count+1))
done

(>&2 echo "DEBUG:Listing all files in out")
(>&2 tree $HOME/out)
(>&2 echo "Done listing")

dx-upload-all-outputs --parallel

}
