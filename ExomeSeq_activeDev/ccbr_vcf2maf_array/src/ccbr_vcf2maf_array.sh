#!/bin/bash
# ccbr_vcf2maf_array
set -e -x -o pipefail
pkill dstat
interval_in_seconds=10
/usr/bin/dx-dstat $interval_in_seconds

main() {

	# Arguments 
	echo "Value of VCF: '${VCF[@]}'"			# Array of TN-pair VCF files
	echo "Value of TumorID: '${TumorID[@]}'"		# Array of strings: sampleName of tumor sample in VCF
	echo "Value of NormalID: '${NormalID[@]}'"		# Array of strings: sampleName of normal sample in VCF
	echo "Value of GenomeName: '${GenomeName}'"		# String: hg38, hg19, mm10

	# Create Output Directory for parallel uploading
	mkdir -p $HOME/out/MAF

	# Listing all files in Root directory
	cd /
	(>&2 echo "DEBUG: Listing all files in root")
	(>&2 ls -larth)
	(>&2 echo "Done listing")

	# Creating a /data directory and downloading the VCF files
	mkdir -p /data/
	cd /data/

	# Getting resources tsv file
	genome2resources=$(dx describe "$Genome2Resources" --name)
	dx download "$Genome2Resources" -o $genome2resources
	
	# Printing out contents of genome2resources files
	(>&2 echo "Value of genome2resources and its contents: $genome2resources")
	(>&2 cat $genome2resources)

	# Getting the UUID for VEP's genomic reference file for downloading: vep_genome_fa
	VEPGENOME=$(python /get_fileid.py $GenomeName 'vep_genome_fa' $genome2resources)
	vep_genome=$(dx describe "$VEPGENOME" --name)
	dx download "$VEPGENOME" -o $vep_genome

	# Creating Index of the genomic fasta resource
	dx-docker pull nciccbr/ccbr_vcf2maf_1.6.17:v0.0.3
	dx-docker run -v /data/:/data nciccbr/ccbr_vcf2maf_1.6.17:v0.0.3 samtools faidx $vep_genome

	# Creating Index of VEP's ExAC VCF resource: vep_exac
	VEPEXAC=$(python /get_fileid.py $GenomeName 'vep_exac' $genome2resources)
	vep_exac=$(dx describe "$VEPEXAC" --name)
	dx download "$VEPEXAC" -o $vep_exac
	dx-docker run -v /data/:/data nciccbr/ccbr_vcf2maf_1.6.17:v0.0.3 tabix $vep_exac


	(>&2 echo "DEBUG: Listing all files in /data after VEP ExAC Download")
	(>&2 ls -larth)
	(>&2 echo "Done listing")
	
	# Getting VEP TAR Ball: vep_tar_ball
	VEPTAR=$(python /get_fileid.py $GenomeName 'vep_tarball' $genome2resources)
	vep_tarball=$(dx describe "$VEPTAR" --name)
	dx download "$VEPTAR" -o $vep_tarball
	tar xvf $vep_tarball


	# Mapping Reference Genome to NCBI build and Species 
	ncbi_build="unknown"
	species="unknown"
	
	if [ $GenomeName == "hg38" ]; then
		ncbi_build="GRCh38"
		species="homo_sapiens"
	elif [ $GenomeName == "hg19" ]; then
		ncbi_build="GRCh37"
		species="homo_sapiens"
	elif [ $GenomeName == "mm10" ]; then
		ncbi_build="GRCm38"
		species="mus_musculus"
	fi

	# Printing out variable names for debugging
	(>&2 echo "Value of ncbi_build: ${ncbi_build}")
	(>&2 echo "Value of species: ${species}")

	for i in ${!VCF[@]}; do 
		vcf=$(dx describe "${VCF[$i]}" --name)
		(>&2 echo "Downloading ${vcf} to /data...")
		dx download "${VCF[$i]}" -o $vcf

		# Creating output filename for MAF file
		maf=$(echo "$vcf" | sed "s/.vcf/.maf/g")
		maf=$(echo "$maf" | sed "s/.gz//g")

		tumor_id="${TumorID[$i]}"
		normal_id="${NormalID[$i]}"

		# Printing out variable names for debugging
		(>&2 echo "Value of vcf: ${vcf}")
		(>&2 echo "Value of maf: ${maf}")
		(>&2 echo "Value of tumor_id: ${tumor_id}")
		(>&2 echo "Value of normal_id: ${normal_id}")

		# Listing downloaded file information 
		(>&2 echo "DEBUG: Listing downloaded file: $vcf")
		(>&2 ls -larth "$vcf")
		(>&2 echo "Done listing")

		cpus=`nproc`
	
		dx-docker run -v /data/.vep:/opt/vep/.vep -v /data:/data \
			nciccbr/ccbr_vcf2maf_1.6.17:v0.0.3 vcf2maf.pl \
				--vep-forks 1 \
				--input-vcf $vcf \
				--output-maf $HOME/out/MAF/$maf \
				--tumor-id $tumor_id \
				--normal-id $normal_id \
				--vep-path /opt/vep/src/ensembl-vep \
				--vep-data /opt/vep/.vep \
				--filter-vcf /data/$vep_exac \
				--ncbi-build $ncbi_build \
				--species $species \
				--ref-fasta /data/$vep_genome
	done

	(>&2 echo "DEBUG: Listing all files in /data after running vcf2maf command")
	(>&2 ls -larth /data/)
	(>&2 echo "Done listing")

	(>&2 echo "DEBUG: Listing all files in $HOME/out/MAF after running vcf2maf command")
	(>&2 ls -larth $HOME/out/MAF)
	(>&2 echo "Done listing")

	# Uploading files to DNAnexus
	(>&2 echo "Uploading MAF Files to DNAnexus")
	dx-upload-all-outputs --parallel
	(>&2 echo "Upload completed")
}
