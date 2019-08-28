#!/bin/bash
# ccbr_rsem_merge 0.0.3


main() {

    # Printing Command-line arguments
    echo "Value of GeneResults: '${GeneResults[@]}'"
    echo "Value of IsoformResults: '${IsoformResults[@]}'"
    echo "Value of GenomeResources: $GenomeResources"

    mkdir -p /data

    # Download Reference File Mapper: genome2resources.tsv
    genomeresources=$(dx describe "$GenomeResources" --name)
    dx download "$GenomeResources" -o "/${genomeresources}" # download to '/'

    # Downloading Annotate Genes Reference File
    annotate_id=$(python /get_fileid.py $Genome 'annotategenes')
    annotategenes=$(dx describe "$annotate_id" --name)
    dx download "$annotate_id" -o "/data/${annotategenes}" # download to '/'

    (>&2 ls -larth /)
    mkdir -p /opt/
    mv /rsem_merge_results.py /opt

    # Creating output directories for parallel upload
    cd /data
    mkdir -p $HOME/out/ExpectedCounts
    mkdir -p $HOME/out/TPM
    mkdir -p $HOME/out/FPKM

    # Generating Genes Counts Matrix
    for i in ${!GeneResults[@]}
    do
        genes=$(dx describe "${GeneResults[$i]}" --name)
        dx download "${GeneResults[$i]}" -o $genes
    done

    # Generating Isoform Counts Matrix
    for i in ${!IsoformResults[@]}
    do
        isoforms=$(dx describe "${IsoformResults[$i]}" --name)
        dx download "${IsoformResults[$i]}" -o $isoforms
    done


    #python /rsem_merge_results.py /$annotategenes /data /data
    dx-docker run -v /data/:/data -v /opt/:/opt nciccbr/ccbr_python python /opt/rsem_merge_results.py /data/$annotategenes /data /data


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

