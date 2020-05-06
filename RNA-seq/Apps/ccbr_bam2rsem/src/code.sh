#!/bin/bash
# ccbr_bam2rsemcounts 0.0.7
# See https://wiki.dnanexus.com/Developer-Portal for tutorials on how
# to modify this file.

run_rsemcounts() {
	mkdir -p /data
	mkdir -p /data/tmp
	cd /data

	bam=$(dx describe "$Bam" --name)
	dx download "$Bam" -o $bam
	dx download "$RSEMindex" -o rsemindex.tar.gz
	cpus=`nproc`
	tar xzvf rsemindex.tar.gz

	# Get RSEM Reference files prefix, since some reference genomes point to rsem reference built with different prefix names
	genome_prefix=$(tar -tf rsemindex.tar.gz | grep '.chrlist$' | sed 's/.chrlist//g')
	echo -e "Value of $Genome and $genome_prefix"

	prefix="${Prefix}.RSEM"
	outRSEMgenes="${Prefix}.RSEM.genes.results"
	outRSEMisoforms="${Prefix}.RSEM.isoforms.results"

	(>&2 echo "DEBUG:Listing all files in data")
	(>&2 tree /data)
	(>&2 echo "Done listing")

	dx-docker run -v /data/:/data kopardev/ccbr_rsem_1.3.1 rsem-calculate-expression \
		--no-bam-output \
		--calc-ci \
		--seed 12345 \
		--bam \
		--paired-end \
		-p $cpus \
		$bam \
		$genome_prefix \
		$prefix \
		--time \
		--temporary-folder /data/tmp \
		--keep-intermediate-files

	(>&2 echo "DEBUG:Listing all files in data")
	(>&2 tree /data)
	(>&2 echo "Done listing")

	OutRSEMgenes=$(dx upload $outRSEMgenes --brief)
	dx-jobutil-add-output OutRSEMgenes "$OutRSEMgenes" --class=file

	OutRSEMisoforms=$(dx upload $outRSEMisoforms --brief)
	dx-jobutil-add-output OutRSEMisoforms "$OutRSEMisoforms" --class=file
}

main() {
	# Printing command-line arguments
	echo "Value of TranscriptomeBam: '${TranscriptomeBam[@]}'"
	echo "Value of Genome: '$Genome'"
	echo "Value of GenomeResources: $GenomeResources"

	# Download Reference File Mapper: genome2resources.tsv
	genomeresources=$(dx describe "$GenomeResources" --name)
	dx download "$GenomeResources" -o "/${genomeresources}" # download to '/'

	mkdir -p /data
	mkdir -p $HOME/out/OutRSEMisoforms
	mkdir -p $HOME/out/OutRSEMgenes

	rsemindex=$(python /get_fileid.py $Genome 'rsemindex')
	subjobids=""
	for (( i=0; i<${#TranscriptomeBam[@]} ; i+=1 )) ; do
		bam=$(dx describe "${TranscriptomeBam[$i]}" --name)
		prefix=`echo $bam|awk -F ".p2." '{print $1}'`
		outRSEMgenes="${prefix}.RSEM.genes.results"
		outRSEMisoforms="${prefix}.RSEM.isoforms.results"
		process_job=$(dx-jobutil-new-job run_rsemcounts -iBam=$bam -iRSEMindex=$rsemindex -iGenome=$Genome -iPrefix=$prefix --instance-type="mem1_ssd1_x32")
		echo "Value of process_job: '$process_job'"
		subjobids="$subjobids $process_job"
		echo -ne "$process_job\t$outRSEMgenes\t$outRSEMisoforms\n" >> /data/lookuptable.txt
	done

	while read jobid rsemgenes rsemisoforms;do

		dx wait $jobid

		cd $HOME/out/OutRSEMgenes
		dx download $jobid:OutRSEMgenes -o $rsemgenes

		cd $HOME/out/OutRSEMisoforms
		dx download $jobid:OutRSEMisoforms -o $rsemisoforms

	done < /data/lookuptable.txt

	(>&2 echo "DEBUG:Listing all files in out")
	(>&2 tree $HOME/out)
	(>&2 echo "Done listing")

	dx-upload-all-outputs --parallel

}
