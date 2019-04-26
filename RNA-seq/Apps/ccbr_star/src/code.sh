#!/bin/bash

set -e -x -o pipefail

# ccbr_star_p1 0.0.5
# See https://wiki.dnanexus.com/Developer-Portal for tutorials on how
# to modify this file.

run_star() {
	mkdir -p /data
	cd /data
	r1=$(dx describe "$R1" --name)
	prefix="${r1%%.*}.p2."
	r2=$(dx describe "$R2" --name)
	dx download "$R1" -o $r1
	dx download "$R2" -o $r2
	dx download "$GTFfile" -o genes.gtf
	cpus=`nproc`
	dx download "$Tarfile" -o starindex.tar.gz
	tar xzvf starindex.tar.gz

	(>&2 echo "DEBUG:Listing all files in data")
	(>&2 tree /data)
	(>&2 echo "Done listing")

	genomeDir=`find /data/ -maxdepth 1 -name "*genes-*"`

	dx-docker run -v /data/:/data kopardev/ccbr_star_2.6.0a STAR \
		--genomeDir ${genomeDir} \
		--outFilterIntronMotifs RemoveNoncanonicalUnannotated \
		--outSAMstrandField None \
		--outFilterType BySJout \
		--outFilterMultimapNmax 20 \
		--alignSJoverhangMin 8 \
		--alignSJDBoverhangMin 1 \
		--outFilterMismatchNmax 999 \
		--outFilterMismatchNoverLmax 0.3 \
		--alignIntronMin 20 \
		--alignIntronMax 1000000 \
		--alignMatesGapMax 1000000 \
		--readFilesIn $r1 $r2 \
		--readFilesCommand zcat \
		--runThreadN $cpus \
		--outFileNamePrefix ${prefix} \
		--outWigType None \
		--outWigStrand Stranded \
		--sjdbGTFfile genes.gtf \
		--limitSjdbInsertNsj 4000000 \
		--quantMode TranscriptomeSAM GeneCounts \
		--outSAMtype BAM SortedByCoordinate
	
	outTab="${prefix}SJ.out.tab"
	outSortedByCoordBam="${prefix}Aligned.sortedByCoord.out.bam"
	outReadsPerGeneTab="${prefix}ReadsPerGene.out.tab"
	outTranscriptomeBam="${prefix}Aligned.toTranscriptome.out.bam"
	outLog="${prefix}Log.final.out"
	
	
	(>&2 echo "DEBUG:Listing all files in data")
	(>&2 tree /data)
	(>&2 echo "Done listing")
	
	OutTab=$(dx upload $outTab --brief)
	dx-jobutil-add-output OutTab "$OutTab" --class=file
	
	OutSortedByCoordBam=$(dx upload $outSortedByCoordBam --brief)
	dx-jobutil-add-output OutSortedByCoordBam "$OutSortedByCoordBam" --class=file
	
	OutReadsPerGeneTab=$(dx upload $outReadsPerGeneTab --brief)
	dx-jobutil-add-output OutReadsPerGeneTab "$OutReadsPerGeneTab" --class=file
	
	OutTranscriptomeBam=$(dx upload $outTranscriptomeBam --brief)
	dx-jobutil-add-output OutTranscriptomeBam "$OutTranscriptomeBam" --class=file
	
	OutLog=$(dx upload $outLog --brief)
	dx-jobutil-add-output OutLog "$OutLog" --class=file	

}

run_dedup() {
	mkdir -p /data
	cd /data
	bam=$(dx describe "$Bam" --name)
	dx download "$Bam" -o $bam
	refflat=$(dx describe "$RefFlat" --name)
	dx download "$RefFlat" -o $refflat
	rrnalist=$(dx describe "$RRNAList" --name)
	dx download "$RRNAList" -o $rrnalist

	(>&2 echo "DEBUG:Listing all files in data")
	(>&2 ls -larth /)
	(>&2 echo "Done listing")

	mkdir -p /${bam}_tmp1
	mkdir -p /${bam}_tmp2
	mkdir -p /${bam}_tmp3
	
	readGroupBam="${Prefix}.RG.bam"
	outStarDmarkBam="${Prefix}.dmark.bam"
	outStarDmarkBai="${Prefix}.dmark.bai"
	outStarDuplic="${Prefix}.star.duplic"
	outRnaSeqMetricsTxt="${Prefix}.RnaSeqMetrics.txt"
	
	java -Xmx120g -jar /picardcloud.jar AddOrReplaceReadGroups \
		I=${bam} \
		O=${readGroupBam} \
		TMP_DIR=/${bam}_tmp1 \
		RGID=id \
		RGLB=library \
		RGPL=illumina \
		RGPU=machine \
		RGSM=sample
	
	java -Xmx120g -jar /picardcloud.jar MarkDuplicates \
		I=${readGroupBam} \
		O=${outStarDmarkBam} \
		TMP_DIR=/${bam}_tmp2 \
		CREATE_INDEX=true \
		VALIDATION_STRINGENCY=SILENT \
		METRICS_FILE=${outStarDuplic}
	
	sed -i 's/MarkDuplicates/picard.sam.MarkDuplicates/g' ${outStarDuplic}
	
	java -Xmx120g -jar /picardcloud.jar CollectRnaSeqMetrics \
		REF_FLAT=${refflat} \
		I=${outStarDmarkBam} \
		O=${outRnaSeqMetricsTxt} \
		RIBOSOMAL_INTERVALS=${rrnalist} \
		STRAND_SPECIFICITY=SECOND_READ_TRANSCRIPTION_STRAND \
		TMP_DIR=/${bam}_tmp3  \
		VALIDATION_STRINGENCY=SILENT
	
	sed -i 's/CollectRnaSeqMetrics/picard.analysis.CollectRnaSeqMetrics/g' ${outRnaSeqMetricsTxt}

	OutStarDmarkBam=$(dx upload $outStarDmarkBam --brief)
	dx-jobutil-add-output OutStarDmarkBam "$OutStarDmarkBam" --class=file	

	OutStarDmarkBai=$(dx upload $outStarDmarkBai --brief)
	dx-jobutil-add-output OutStarDmarkBai "$OutStarDmarkBai" --class=file	
	
	OutStarDuplic=$(dx upload $outStarDuplic --brief)
	dx-jobutil-add-output OutStarDuplic "$OutStarDuplic" --class=file		

	OutRnaSeqMetricsTxt=$(dx upload $outRnaSeqMetricsTxt --brief)
	dx-jobutil-add-output OutRnaSeqMetricsTxt "$OutRnaSeqMetricsTxt" --class=file	
}


main() {

    echo "Value of RawFq: '${RawFq[@]}'"
    echo "Value of TrimmedFq: '${TrimmedFq[@]}'"
    echo "Value of TrimmedFastqcTxt: '${TrimmedFastqcTxt[@]}'"
    echo "Value of Genome: '$Genome'"
    
	mkdir -p /data
	mkdir -p $HOME/out/OutTab
	mkdir -p $HOME/out/OutReadsPerGeneTab
	mkdir -p $HOME/out/OutTranscriptomeBam
	mkdir -p $HOME/out/OutLog
	mkdir -p $HOME/out/OutStarDuplic
	mkdir -p $HOME/out/OutStarDmarkBam
	mkdir -p $HOME/out/OutStarDmarkBai
	mkdir -p $HOME/out/OutRnaSeqMetricsTxt
	
	mkdir -p /data/txt
	cd /data/txt
	for i in ${!TrimmedFastqcTxt[@]}
	do
			txt=$(dx describe "${TrimmedFastqcTxt[$i]}" --name)
			dx download "${TrimmedFastqcTxt[$i]}" -o $txt
	done
	cd /data
	
	(>&2 echo "DEBUG:Listing all files in data")
	(>&2 tree /data)
	(>&2 echo "Done listing")

	tarfile=$(python /get_starindexid.py /data/txt $Genome)
	tarfile="project-FPkJp0Q0xx3Y9XXKKzB0408Y:${tarfile}"
 	
	gtffile=$(python /get_fileid.py $Genome 'gtffile')
	refflat=$(python /get_fileid.py $Genome 'refflat')
	rrnalist=$(python /get_fileid.py $Genome 'rrnalist')

	projectid="project-FPkJp0Q0xx3Y9XXKKzB0408Y"

	gtffile="${projectid}:${gtffile}"
	refflat="${projectid}:${refflat}"
	rrnalist="${projectid}:${rrnalist}"
	

	(>&2 echo "GTFFILE :")
	(>&2 echo $gtffile)

	subjobids=""
	for (( i=0; i<${#RawFq[@]} ; i+=2 )) ; do
		r1=$(dx describe "${RawFq[$i]}" --name)
		r2=$(dx describe "${RawFq[$i+1]}" --name)
		r1=`echo $r1|sed "s/.fastq/.trimmed.fastq/g"`
		r2=`echo $r2|sed "s/.fastq/.trimmed.fastq/g"`
		process_job=$(dx-jobutil-new-job run_star -iR1=$r1 -iR2=$r2 -iTarfile=$tarfile -iGTFfile=$gtffile --instance-type="mem1_ssd1_x32")
		echo "Value of process_job: '$process_job'"
		subjobids="$subjobids $process_job"
	done

	count=0
	for i in $subjobids	
	do
		echo "Waiting for ",$i
		dx wait $i
		
		cd $HOME/out/OutTab
		dx download $i:OutTab
		
		cd $HOME/out/OutReadsPerGeneTab
		dx download $i:OutReadsPerGeneTab
		
		cd $HOME/out/OutTranscriptomeBam
		dx download $i:OutTranscriptomeBam
		
		cd $HOME/out/OutLog
		dx download $i:OutLog

		mkdir -p /data/${count}
		cd /data/${count}
		cp /picardcloud.jar .
		dx download $i:OutSortedByCoordBam

		bam=`ls *.bam`
		prefix=`ls *.bam|awk -F ".p2." '{print $1}'`
		outStarDmarkBam="${prefix}.star_rg_added.sorted.dmark.bam"
		outStarDmarkBai="${prefix}.star_rg_added.sorted.dmark.bai"
		outStarDuplic="${prefix}.star.duplic"
		outRnaSeqMetricsTxt="${prefix}.RnaSeqMetrics.txt"
				
		process_job=$(dx-jobutil-new-job run_dedup -iBam=$bam -iRefFlat=$refflat -iRRNAList=$rrnalist -iPrefix=$prefix --instance-type="mem3_ssd1_x16")
		echo -ne "$process_job\t$outStarDmarkBam\t$outStarDmarkBai\t$outStarDuplic\t$outRnaSeqMetricsTxt\n" >> /data/picardoutfiles.txt

		count=$((count+1))

	done

	(>&2 echo "DEBUG:Cat-ing picardoutfiles.txt and counting number of lines")
	(>&2 cat /data/picardoutfiles.txt)
	(>&2 wc -l /data/picardoutfiles.txt)
	(>&2 echo "Done")
	
	while read jobid bam bai duplic rnaseqmatrics;do

		(>&2 echo "This line from picardoutfiles.txt contains:")
		(>&2 echo $jobid)
		(>&2 echo $bam)
		(>&2 echo $bai)
		(>&2 echo $duplic)
		(>&2 echo $rnaseqmatrics)
		(>&2 echo "Done")

		dx wait $jobid
		
		cd $HOME/out/OutStarDmarkBam/
		dx download $jobid:OutStarDmarkBam -o $bam
		
		cd $HOME/out/OutStarDmarkBai/
		dx download $jobid:OutStarDmarkBai -o $bai
		
		cd $HOME/out/OutStarDuplic/
		dx download $jobid:OutStarDuplic -o $duplic
		
		cd $HOME/out/OutRnaSeqMetricsTxt/
		dx download $jobid:OutRnaSeqMetricsTxt -o $rnaseqmatrics
		
	done < /data/picardoutfiles.txt
		
		

	(>&2 echo "DEBUG:Listing all files in out")
	(>&2 tree $HOME/out)
	(>&2 echo "Done listing")

	dx-upload-all-outputs --parallel 


}
