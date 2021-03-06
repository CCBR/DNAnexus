#!/bin/bash
# ccbr_cutadapt_1.18 0.0.1
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

mkdir -p /data/
cd /data
sarfile="/data/${DX_JOB_ID}_sar.txt"
sar 5 > $sarfile &
SAR_PID=$!

rep1=$(dx describe "$Rep1" --name)
dx download "$Rep1" -o $rep1
rep1Pr1=$(dx describe "$Rep1Pr1" --name)
dx download "$Rep1Pr1" -o $rep1Pr1
rep1Pr2=$(dx describe "$Rep1Pr2" --name)
dx download "$Rep1Pr1" -o $rep1Pr2
rep2=$(dx describe "$Rep2" --name)
dx download "$Rep2" -o $rep2
rep2Pr1=$(dx describe "$Rep2Pr1" --name)
dx download "$Rep2Pr1" -o $rep2Pr1
rep2Pr2=$(dx describe "$Rep2Pr2" --name)
dx download "$Rep2Pr1" -o $rep2Pr2
rep0=$(dx describe "$Rep0" --name)
dx download "$Rep0" -o $rep0
rep0Pr1=$(dx describe "$Rep0Pr1" --name)
dx download "$Rep0Pr1" -o $rep0Pr1
rep0Pr2=$(dx describe "$Rep0Pr2" --name)
dx download "$Rep0Pr1" -o $rep0Pr2

if [ $Broad ]
then

	dx-docker run -v `pwd`/:/data nciccbr/ccbr_bedtools:v0.0.2 ccbr_chipseq_overlap_filtering_broad.bash \
	--PeaksRep1Pr1 $rep1Pr1 \
	--PeaksRep1Pr2 $rep1Pr2 \
	--PeaksRep1 $rep1 \
	--PeaksRep0Pr1 $rep0Pr1 \
	--PeaksRep0Pr2 $rep0Pr2 \
	--PeaksRep0 $rep0 \
	--PeaksRep2Pr1 $rep2Pr1 \
	--PeaksRep2Pr2 $rep2Pr2 \
	--PeaksRep2 $rep2

	resultsfile="results.broadPeak.txt"
	N1file="N1.broadPeak"
	N2file="N2.broadPeak"
	Ntfile="Nt.broadPeak"
	Npfile="Np.broadPeak"
	optimalfile="Optimal_broad_peaks.bed"
	conservativefile="Conservative_broad_peaks.bed"

else

	dx-docker run -v `pwd`/:/data nciccbr/ccbr_bedtools:v0.0.2 ccbr_chipseq_overlap_filtering_narrow.bash \
	--PeaksRep1Pr1 $rep1Pr1 \
	--PeaksRep1Pr2 $rep1Pr2 \
	--PeaksRep1 $rep1 \
	--PeaksRep0Pr1 $rep0Pr1 \
	--PeaksRep0Pr2 $rep0Pr2 \
	--PeaksRep0 $rep0 \
	--PeaksRep2Pr1 $rep2Pr1 \
	--PeaksRep2Pr2 $rep2Pr2 \
	--PeaksRep2 $rep2

	resultsfile="results.narrowPeak.txt"
	N1file="N1.narrowPeak"
	N2file="N2.narrowPeak"
	Ntfile="Nt.narrowPeak"
	Npfile="Np.narrowPeak"
	optimalfile="Optimal_narrow_peaks.bed"
	conservativefile="Conservative_narrow_peaks.bed"

fi

Results=$(dx upload /data/$resultsfile --brief)
dx-jobutil-add-output Results "$Results" --class=file
N1=$(dx upload /data/$N1file --brief)
dx-jobutil-add-output N1 "$N1" --class=file
N2=$(dx upload /data/$N2file --brief)
dx-jobutil-add-output N2 "$N2" --class=file
Nt=$(dx upload /data/$Ntfile --brief)
dx-jobutil-add-output Nt "$Nt" --class=file
Np=$(dx upload /data/$Npfile --brief)
dx-jobutil-add-output Np "$Np" --class=file
Optimal=$(dx upload /data/$optimalfile --brief)
dx-jobutil-add-output Optimal "$Optimal" --class=file
Conservative=$(dx upload /data/$conservativefile --brief)
dx-jobutil-add-output Conservative "$Conservative" --class=file

kill -9 $SAR_PID
SarTxt=$(dx upload $sarfile --brief)
dx-jobutil-add-output SarTxt "$SarTxt" --class=file


}
