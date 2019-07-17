#!/bin/bash
# ccbr_rsem_merge 0.0.2

# See https://wiki.dnanexus.com/Developer-Portal for tutorials on how
# to modify this file.

main() {

    echo "Value of GeneResults: '${GeneResults[@]}'"
    echo "Value of IsoformResults: '${IsoformResults[@]}'"

	mkdir -p /data
	cd /data
	mkdir -p $HOME/out/ExpectedCounts
	mkdir -p $HOME/out/TPM
	mkdir -p $HOME/out/FPKM

    for i in ${!GeneResults[@]}
    do
    	genes=$(dx describe "${GeneResults[$i]}" --name)
    	dx download "${GeneResults[$i]}" -o $genes
    done

    for i in ${!IsoformResults[@]}
    do
    	isoforms=$(dx describe "${IsoformResults[$i]}" --name)
    	dx download "${IsoformResults[$i]}" -o $isoforms
    done

	python /rsem_merge_results.py /${Genome}.annotate.genes.txt /data /data

    (>&2 echo "DEBUG:Listing all files in data")
    (>&2 tree /data)
    (>&2 echo "Done listing")

	mv *expected_count.all_samples.txt $HOME/out/ExpectedCounts
	mv *TPM.all_samples.txt $HOME/out/TPM
	mv *FPKM.all_samples.txt $HOME/out/FPKM

    (>&2 echo "DEBUG:Listing all files in out")
    (>&2 tree $HOME/out)
    (>&2 echo "Done listing")

    dx-upload-all-outputs --parallel

}
