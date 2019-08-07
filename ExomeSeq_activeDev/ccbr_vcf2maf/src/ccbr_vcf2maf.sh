#!/bin/bash
# ccbr_vcf2maf
set -e -x -o pipefail
pkill dstat
interval_in_seconds=10
/usr/bin/dx-dstat $interval_in_seconds

main() {

    echo "Value of VCF: '$VCF'"
    echo "Value of GenomeName: '$GenomeName'"
	echo "Value of TumorID: '$TumorID'"
    echo "Value of NormalID: '$NormalID'"
    
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

vcf=$(dx describe "$VCF" --name)
dx download "$VCF" -o $vcf
maf=`echo $vcf|sed "s/.vcf/.maf/g"`
maf=`echo $maf|sed "s/.gz//g"`

genome2resources=$(dx describe "$Genome2Resources" --name)
dx download "$Genome2Resources" -o $genome2resources

echo $vcf
echo $maf
echo $genome2resources

(>&2 echo "DEBUG:Listing all files in data")
(>&2 ls -larth)
(>&2 echo "Done listing")


VEPGENOME=$(python /get_fileid.py $GenomeName 'vep_genome_fa' $genome2resources)
vep_genome=$(dx describe "$VEPGENOME" --name)
dx download "$VEPGENOME" -o $vep_genome

#create the fai and gzi files
dx-docker pull nciccbr/ccbr_vcf2maf_1.6.17:v0.0.3
dx-docker run -v /data/:/data nciccbr/ccbr_vcf2maf_1.6.17:v0.0.3 samtools faidx $vep_genome

VEPEXAC=$(python /get_fileid.py $GenomeName 'vep_exac' $genome2resources)
vep_exac=$(dx describe "$VEPEXAC" --name)
dx download "$VEPEXAC" -o $vep_exac
dx-docker run -v /data/:/data nciccbr/ccbr_vcf2maf_1.6.17:v0.0.3 tabix $vep_exac

# VEPEXACINDEX=$(python /get_fileid.py $GenomeName 'vep_exac_tbi' $genome2resources)
# dx download "$VEPEXACINDEX" -o ${vep_exac}.tbi

(>&2 echo "DEBUG:Listing all files in data")
(>&2 ls -larth)
(>&2 echo "Done listing")


VEPTAR=$(python /get_fileid.py $GenomeName 'vep_tarball' $genome2resources)
vep_tarball=$(dx describe "$VEPTAR" --name)
dx download "$VEPTAR" -o $vep_tarball
tar xvf $vep_tarball


# VEPGENOMEINDEX=$(python /get_fileid.py $GenomeName 'vep_genome_fai' $genome2resources)
# dx download "$VEPGENOMEINDEX" -o ${vep_genome}.fai

# VEPGENOMEINDEX2=$(python /get_fileid.py $GenomeName 'vep_genome_gzi' $genome2resources)
# dx download "$VEPGENOMEINDEX2" -o ${vep_genome}.gzi


ncbi_build="unknown"
species="unknown"
if [ $GenomeName == "hg38" ]; then
	ncbi_build="GRCh38"
	species="homo_sapiens"
fi

if [ $GenomeName == "hg19" ]; then
	ncbi_build="GRCh37"
	species="homo_sapiens"
fi

cpus=`nproc`

(>&2 echo "DEBUG:Listing all files in data")
(>&2 ls -larth)
(>&2 echo "Done listing")

dx-docker run \
-v /data/.vep:/opt/vep/.vep \
-v /data:/data \
nciccbr/ccbr_vcf2maf_1.6.17:v0.0.3 vcf2maf.pl \
--vep-forks 1 \
--input-vcf $vcf \
--output-maf $maf \
--tumor-id $TumorID \
--normal-id $NormalID \
--vep-path /opt/vep/src/ensembl-vep \
--vep-data /opt/vep/.vep \
--filter-vcf /data/$vep_exac \
--ncbi-build $ncbi_build \
--species $species \
--ref-fasta /data/$vep_genome

(>&2 echo "DEBUG:Listing all files in data")
(>&2 ls -larth)
(>&2 echo "Done listing")

MAF=$(dx upload /data/$maf --brief)
dx-jobutil-add-output MAF "$MAF" --class=file

}
