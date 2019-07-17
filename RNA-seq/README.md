# DNAnexus RNA-seq Documentation


## 0. Best Practices for Experimental Design
1. Factor in at least 3 replicates (absolute minimum), but 4 if possible (optimum minimum). Biological replicates are recommended rather than technical replicates.
1.  Always process your RNA extractions at the same time. Extractions done at different times lead to unwanted batch effects.
1. There are two major considerations for RNA-seq libraries: 
    - If you are interested in coding mRNA, you can select to use the mRNA library prep. The recommended sequencing depth is between 10-20M paired-end (PE) reads. Your RNA has to be high quality (RIN > 8).
    - If you are interested in long noncoding RNA as well, you can select the total RNA method, with sequencing depth ~25-60M PE reads. This is also an option if your RNA is degraded.
Other Considerations:
Ideally to avoid lane batch effects, all samples would need to be multiplexed together and run on the same lane. This may require an initial MiSeq run for library balancing. Additional lanes can be run if more sequencing depth is needed. If you are unable to process all your RNA samples together and need to process them in batches, make sure that replicates for each condition are in each batch so that the batch effects can be measured and removed.
For sequence depth and machine requirements, visit  [Illumina Sequencing Coverage website](http://support.illumina.com/downloads/sequencing_coverage_calculator.html).


## 1. RNA-seq Pipeline
#### Where is my counts file generated?
The processing of data, starting from raw data (FastQ files) to a raw count's matrix, occurs on the DNAnexus platform. DNAnexus is a cloud-based data analysis platform tailored to analyzing NGS data. The workflows developed on DNAnexus mirror the pipelines CCBR has developed on the NIH's Biowulf Cluster. These workflows allow a user to select a set of FastQ files and process them on DNAnexus platform to reach an endpoint, such as a raw counts matrix. Once a raw counts matrix has been generated, it is pulled into the Palantir platform for downstream analysis. 
#### What should I know about the process to generate the counts file?
The process of assessing the quality of your data to generating raw counts from raw data is resource, CPU, and memory intensive. Throughout the entire process hundreds of CPU hours are accrued. The process of job submission, resource allocation, and parallelization have been abstracted away from the end-user. CCBR has benchmarked and optimized our workflows to minimize direct costs. It is important to note that the cost of processing data on DNAnexus is not free. Once a job has been submitted to DNAnexus, a cost will also be generated. It is important to keep this in mind.
#### What is happening on DNAnexus?
Before analyzing your data to draw biological conclusions, it is important to perform quality control checks to ensure that their are no signs of sequencing error, biases in your data, or contamination. Modern high-throughput sequencers generate millions of reads per run, and in the real world, problems can arise. And as so, it is important to asses the quality of the raw data before proceeding to downstream analysis.   
- [__FastQC__](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/):
generates a set of basic statistics to identify potential problems that can arise during the process of sequencing or library preparation. For each sample, FastQC summarizes per base and sequence quality scores, per base and sequence GC content, distribution of sequence lengths, rates of sequence duplication, and rates of sequence diversity (overrepresentation). 

- [__Cutadapt__](https://cutadapt.readthedocs.io/en/stable/): is used to remove any unwanted adapters sequences from your reads in before aligning to the reference genome. Adapter sequences are made up of synthetic sequences which do not occur within the genome. Removing adapter contamination is an import step which reduces alignment issues-- decreasing the number of unaligned reads. Adapter removal is especially import in certain protocols, such as total RNA-seq or miRNA-seq, where small RNAs may be present. With the smaller fragment sizes, it is almost certain there will be adapter contamination. 
- [__FastQ Screen__](https://www.bioinformatics.babraham.ac.uk/projects/fastq_screen/):
During the process of sample collection to library preparation, there is a risk for introducing wanted sources of DNA. FastQ Screen compares your sequencing data to a set of different genomes or databases to determine if there is contamination. FastQ Screen allows you to see if the composition of your library matches with what you expect. If your data has high levels of human, mouse, fungi, or bacterial contamination, FastQ Screen will tell you.
- [__STAR__](https://github.com/alexdobin/STAR/blob/master/doc/STARmanual.pdf):
Accurate alignment of the transcriptome is difficult. Alternative splicing introduces the problem of aligning non-contiguous regions. Using traditional genomic alignment algorithms produces inaccurate or low quality alignments due to alternative splicing and genomic variation (substitutions, insertions and deletions). STAR is 'splice-aware' aligner, and it designed to overcomes these problems.
- [__RSEM__](https://deweylab.github.io/RSEM/):
Transcript quantification has its own set of challenges. How do you handle of reads that map to multiple genes or isoforms? RSEM provides very accurate quantification of gene and isoform expression from RNA-seq data. When using a 'splice aware' aligner, reads can be aligned in such a way as to determine intron-exon divisions and exon-exon links. Gene and transcript expression estimation relies on determining the relative abundance of reads mapping to your genomic or transcriptomic feature of interest. Read counts are then quantified at each locus or for each known transcript to estimate the relative abundances of each transcript.

#### Will I get a notification when my file is ready?
Yes. You will receive notifications when you request the analysis, when the PI approves the analysis and when your data is ready for downstream analysis.


## 2. Reviewing QC Results
#### Where do the QC files come from?
All upstream analysis, which includes step that assess the quality of your data, is conducted on the DNAnexus platform. For a more detailed explanation of the entire process, please see section one: RNA-seq Pipeline. 
#### Why is it important to review QC?
Before analyzing your data to draw biological conclusions, it is important to perform quality control checks to ensure that their are no signs of sequencing error, biases in your data, or contamination. Modern high-throughput sequencers generate millions of reads per run, and in the real world, problems can arise at any stage of the process. And as so, it is important to asses the quality of the raw data before proceeding to downstream analysis. As the adage goes: _garbage in, garbage out!_
#### What are the important files to view?
A good starting point is to look over the MultiQC report. This document aggregates the results from multiples tools that assess the quality of your data into a single interactive report. 
#### What does good/bad look like for each metric I am reviewing?
##### Considerations for different RNA-seq libraries:
- mRNA ~ poly(A)-selection:
    - Recommended Sequencing Depth: 10-20M paired-end reads. Your RNA has to be high quality (RIN > 8).
    - FastQC: Q30 > 70%
    - % Aligned to reference genome: >70%
    - Million Reads Aligned: >7M read pairs or 14M reads (reported by MultiQC)
    - % Duplication: Not Applicable
    - % rRNA: <5%
    - Picard RNAseqMetrics
        - Coding > 50%
        - Intronic + Intergenic < 25%
- Total RNA:
    - Recommended Sequencing Depth: 25-60M PE paired-end reads. Your RNA has to be high quality (RIN > 8).
    - FastQC: Q30 > 70%
    - % Aligned to reference genome: >65%
    - Million Reads Aligned: >16.5M read pairs or 33M reads (reported by MultiQC)
    - % Duplication: Not Applicable
    - % rRNA: <15%
    - Picard RNAseqMetrics
        - Coding > 35%
        - Intronic + Intergenic < 40%  

__FastQC:__ provides a suite of tools to asses the quality of your data. For each sample, a HTML file is generated. These files that can be opened in your browser. FastQC provides an example of a good and bad report:
- [Good Illumina FastQC Report](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/good_sequence_short_fastqc.html#M0)
- [Bad Illumina FastQC Report](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/bad_sequence_fastqc.html)
- [Technical Contamination: Adapter Dimers](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/RNA-Seq_fastqc.html)
- [Overrepresentation of Adapter Sequences (mirRNAs)](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/small_rna_fastqc.html#M8)

__FastQ Screen:__ allows you to screen your library of sequences against a set of sequence databases so you can see if the composition of the library matches with what you expect. FastQ Screen produces easy-to-interpret bar plots that show the percent of your library mapping to a given reference genome.
- [Good and Bad FastQ Screen report](https://www.bioinformatics.babraham.ac.uk/projects/fastq_screen/)
- FastQ Screen also provides a [video](https://www.youtube.com/watch?v=x32k84HHqjQ&list=PLbiByRpDb_hO2dFQDTYeyx4i6X10UtIXG&index=4&t=0s) on interpreting results.
#### What do I do if the QC results are poor?
Please contact a CCBR member. Depending on the severity of the issue, a formal project request may be opened. 

## 3. Downstream Analysis
#### What are counts? 
Counts represent the number of reads that align to a particular gene or feature-- feature meaning a particular genomic region such as a gene, isoform, or exon. The RNA-seq pipeline on DNAnexus generates a raw counts matrix that can be used for differential expression analysis. Before getting started, there are a few things to keep in mind. Raw counts are biased by two factors: 
1. The number of fragments sequenced or library size
    1. As the library size increases, the proportion of reads mapping to a given feature increases
1. The length of a feature of interest
    1. As the size of a given feature of interest increases, the proportion of reads mapping to _said_ feature increases
As so, directly comparing raw counts of gene(s) within and across samples is not permissible. 
#### Why do we remove low count genes?
Genes with low counts across all samples more likely represent noise, and it is a strong indication that the said gene is not expressed in a given sample. It is highly recommended to remove low counts genes before performing differential expression analysis. If low count genes are not filtered, it can interfere with some of the statistical methods employed by limma, DESeq2, and edgeR. In effect, these genes can reduce power to detect differential expressed genes when performing multiple testing correction. And as so, low count genes should be removed before conducting further downstream analysis.
#### What is CPM?
CPM stands for counts per million. CPM normalization addresses the problem that sequencing depths differ across samples. CPM normalized counts have been scaled by the number of fragments sequenced multiplied by one million. CPM normalization allows comparison of expression for a given gene across samples. 
#### What is group-based CPM filtering?
CPM normalization accounts for differences in sequencing depths across samples. It is better to filter based on CPM, as apposed to filtering based on the raw counts, because it takes into consideration differences in library sizes. Also, since differential expression analysis tools like limma, DESeq2, and edgeR compare counts between groups for a given gene, gene-length does not need to be taken in account.  As so, CPM can be used to filter low count genes. 
That being said, it is recommended to filter out any genes that have a `CPM < 0.5 at least two samples` (assuming you have three replicates). 
If you have two replicates per group, you can decrease the minimum sample threshold to 1: `CPM < 0.5 at least one samples`.  

Here is a basic formula to determine the minimum number of samples for CPM filtering:

			MinimumNumberSamples =  ceiling(min(NSampleGroup1, NSamplesGroup2) / 2)
Group based CPM filtering ensures that a gene will be retained if a gene is only expressed in one group.
#### When should you used group-based filtering?
Prior to performing differential expression analysis on the raw counts, low count genes should be filtered using the method above. 


  

