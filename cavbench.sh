#---------------------------------------------------------------------------------------
#
#	CavBench - A benchmark to compare protein cavity detection methods
#
#  	Copyright (C) 2018 Instituto de Telecomunicações (www.it.pt)
#  	Copyright (C) 2018 Universidade da Beira Interior (www.ubi.pt)
#  	Copyright (C) 2018 INESC-ID, Universidade de Lisboa (www.inesc.pt)
#
#  	This program is free software: you can redistribute it and/or modify
#  	it under the terms of the GNU General Public License as published by
#  	the Free Software Foundation, either version 3 of the License, or
#  	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#	Contacts: 
#		Sergio Dias <sergioduartedias@sapo.pt>
#		Abel Gomes <agomes@di.ubi.pt>
#---------------------------------------------------------------------------------------

#!/bin/bash
clear

# we assume you are in CavBench's root folder
mypath="$PWD"

# read in the names of protein cavity detection methods in the CavBench dataset
methods=( `cat "txt/methods.txt" `)

# read in the names of apo and holo proteins in the CavBench dataset
proteins=( `cat "txt/proteins.txt" `)

# initialize the number of apo and holo proteins
napo=0
nholo=0

#initialize the number of apo and holo protein cavities in the ground truth
napocavities=0
nholocavities=0

#-----------------------------------------------------------------------------------------
# for each protein, let us calculate how much its method-specific cavities overlap the 
# homologous ground-truth cavities; 
# this computation is performed for every method listed in file "methods.txt" (see above)
#-----------------------------------------------------------------------------------------
for p in "${proteins[@]}"
do

    	# apoflag takes on the value either 0 (not apo protein) or 1 (apo protein) 
    apoflag=$(grep -c "$p" txt/apos.txt)
    	# number of apo proteins is being updated
    napo=$((apoflag+napo))
    
    	# holoflag takes on the value either 0 (not holo protein) or 1 (holo protein) 
    holoflag=$(grep -c "$p" txt/holos.txt)
    	# number of holo proteins is being updated
    nholo=$((holoflag+nholo))
    
    	# get number of cavities $nc of protein $p in the ground truth
    nc=$(sort -s -n -k 4,4 "$mypath"/datasets/ground_thruth_csv/"$p".csv  |tail -n 1  | awk '{print $NF}')
    	# update total number of cavities for either apos or holos
    if [ "$apoflag" -eq 0 ];then
           napocavities=$(( $napocavities + $nc ))
    else
           nholocavities=$(( $nholocavities + $nc ))
    fi


		# for the current protein $p, let us evaluate the overlapping between 
		# its cavities in the ground truth and cavities produced by each method;
		# initialize the number of groud-truth cavities (ngc) 
		# and method-specific cavities (nmc)
	ngc=0
	nmc=0
	
    	# for method $m, calculates overlapping percentages and FN, TP, FP
    for m in "${methods[@]}"
    do
        	# number of cavities (PDBsum clefts + Mole tunnels) in the ground truth 
        	# for the protein $p
        ngc=$(sort -s -n -k 4,4 "$mypath"/datasets/ground_thruth_csv/csv/"$p".csv  |tail -n 1  | awk '{print $NF}') 
        ngc=$((ngc+1))
    
        	# number of cavities identified by the method $m for the protein $p
        nmc=$(sort -s -n -k 4,4 "$mypath"/datasets/"$m"_csv/"$p".csv |tail -n 1  | awk '{print $NF}') 
        nmc=$((nmc+1)) 
    
        	# Compute overlapping dummy atom pairs (C,c) between ground-truth cavities and 
        	# method ($m) cavities for the protein $p; 
        	# C represents a dummy atom of a ground-truth cavity;
        	# c represents a dummy atom of a method-specific cavity;
        	# This computation is performed using the executable program 
        	# called dummyatompairs.exe whose source code is also in the folder /bin
        ./bin/dummyatompairs.exe "$mypath"/datasets/ground_thruth_csv/"$p".csv "$mypath"/datasets/"$m"_csv/"$p".csv  >> dummyatompairs_temp.txt
        
        	# Remove last line (blank line) of the file
        sed '$d' dummyatompairs_temp.txt > dummyatompairs.txt
        	# Remove temporary file
        rm -r -f dummyatompairs_temp.txt


        	# Compute overlapping matrix;
        	# This computation is performed using the executable program 
        	# called overlappingmatrix.exe whose source code is also in the folder /bin
        ./bin/overlappingmatrix.exe "$mypath"/datasets/ground_thruth_csv/"$p".csv dummyatompairs.txt  "$ngc" "$nmc" > "$mypath"/temp/overlappingmatrix_temp.txt
        	# store overlapping matrix of protein $p for the method $m 
        mv "$mypath"/temp/overlappingmatrix_temp.txt  "$mypath"/results/overlaping_matrices/"$p"_"$m"_overlappingmatrix.txt


			# Compute TP (true positives), FP (false positives), and FN (false negatives)
        	# This computation is performed using the executable program 
        	# called tp_fp_fn.exe whose source code is also in the folder /bin
        ./bin/tp_fp_fn.exe "$mypath"/results/overlaping_matrices/"$p"_"$m"_overlappingmatrix.txt "$ngc" "$nmc" > "$mypath"/temp/tp_fp_fn_temp.txt
        	# Remove file no longer necessary
        rm -r -f dummyatompairs.txt

			# Copy the single-row results (TP,FP,FN) for a protein $p and method $m$ 
			# into three single-row separate files, depending on they concern an agnostic, 
			# apo, or holo protein.  
        head -1 "$mypath"/temp/tp_fp_fn_temp.txt  > "$mypath"/results/temp/"$p"_"$m"_tp_fp_fn_apo_holo.txt
        if [ "$apoflag" -eq 0 ];then
           head -1 "$mypath"/temp/tp_fp_fn_temp.txt  > "$mypath"/results/temp/"$p"_"$m"_tp_fp_fn_apo.txt
         else
           head -1 "$mypath"/temp/tp_fp_fn_temp.txt  > "$mypath"/results/temp/"$p"_"$m"_tp_fp_fn_holo.txt
         fi
         
        	# Remove any file no longer necessary
        rm -r -f "$mypath"/temp/* 

    done
    echo "Cavities of "$p" as detected by the last method "$m" have been benchmarked against ground-truth cavities."
done

#-----------------------------------------------------------------------------------------
# Join results (TP,FP,FN) in single-row files into three separate files;
# This aggregation of results is done per cavity detection method.
#-----------------------------------------------------------------------------------------
for m in "${methods[@]}"
do
    cat "$mypath"/results/temp/*_"$m"_tp_tn_fp_fn_apo_holo.txt > "$mypath"/results/temp/"$m"_tp_fp_fn_apo_holo.txt
    cat "$mypath"/results/temp/*_"$m"_tp_tn_fp_fn_apo.txt > "$mypath"/results/temp/"$m"_tp_fp_fn_apo.txt
    cat "$mypath"/results/temp/*_"$m"_tp_tn_fp_fn_holo.txt > "$mypath"/results/temp/"$m"_tp_fp_fn_holo.txt
done


#-----------------------------------------------------------------------------------------
# Sum up the results (TP,FP,FN) in a component-wise manner for each method;
# That is, all TPs of the first colum, all FPs of the second column, and all FNs 
# of the third column;
# This is done for each method $m. 
#-----------------------------------------------------------------------------------------
for m in "${methods[@]}"
do
     awk '{for (i=1;i<=NF;i++) sum[i]+=$i;}; END{for (i in sum) print sum[i]}' "$mypath"/results/temp/"$m"_tp_fp_fn_apo_holo.txt >> "$mypath"/results/temp/"$m"_TPFPFN_apo_holo_temp.txt
     awk '{for (i=1;i<=NF;i++) sum[i]+=$i;}; END{for (i in sum) print sum[i]}' "$mypath"/results/temp/"$m"_tp_fp_fn_apo.txt >> "$mypath"/results/temp/"$m"_TPFPFN_apo_temp.txt
     awk '{for (i=1;i<=NF;i++) sum[i]+=$i;}; END{for (i in sum) print sum[i]}' "$mypath"/results/temp/"$m"_tp_fp_fn_holo.txt >> "$mypath"/results/temp/"$m"_TPFPFN_holo_temp.txt
done


#-----------------------------------------------------------------------------------------
# Dealing with formatting issues resulting from using awk;
# replacing '\n' between columns by blank space ' '; 
#-----------------------------------------------------------------------------------------
for m in "${methods[@]}"
do

      tr '\n' ' ' < "$mypath"/results/temp/"$m"_TPFPFN_apo_holo_temp.txt > "$mypath"/results/temp/"$m"_TPFPFN_apo_holo.txt 
      echo "" >> "$mypath"/results/temp/"$m"_TPFPFN_apo_holo.txt
      
      tr '\n' ' ' < "$mypath"/results/temp/"$m"_TPFPFN_apo_temp.txt > "$mypath"/results/temp/"$m"_TPFPFN_apo.txt 
      echo "" >> "$mypath"/results/temp/"$m"_TPFPFN_apo.txt

      tr '\n' ' ' < "$mypath"/results/temp/"$m"_TPFPFN_holo_temp.txt > "$mypath"/results/temp/"$m"_TPFPFN_holo.txt 
      echo "" >> "$mypath"/results/temp/"$m"_TPFPFN_holo.txt
done

#-----------------------------------------------------------------------------------------
# Join results (TP,FP,FN) of all methods per type of protein (apo, holo, and apo+holo).
# These results are organized as shown in Table 1 of the paper.
#-----------------------------------------------------------------------------------------
for m in "${methods[@]}"
do
    cat "$mypath"/results/temp/"$m"_TPFPFN_apo_holo.txt >> "$mypath"/results/csv/TPFPFN_apo_holo.txt
    cat "$mypath"/results/temp/"$m"_TPFPFN_apo.txt >> "$mypath"/results/csv/TPFPFN_apo.txt
    cat "$mypath"/results/temp/"$m"_TPFPFN_holo.txt >> "$mypath"/results/csv/TPFPFN_holo.txt
done


#-----------------------------------------------------------------------------------------
# Let us starting to produce final results into a .csv file called 'results.csv';
# First, we write ground truth data into results.csv.
#-----------------------------------------------------------------------------------------
napoholo=$(( $napo + $nholo ))
napoholocavities=$(( $napocavities + $nholocavities ))
printf "\tGROUND TRUTH\t\t\n" >> "$mypath"/results/csv/results.csv
printf "\t\t#Proteins\t#Cavities\n" >> "$mypath"/results/csv/results.csv
printf "\tAPOs\t"$apo"\t"$napocavities"\n" >> "$mypath"/results/csv/results.csv
printf "\tHOLOs\t"$holo"\t"$nholocavities"\n" >> "$mypath"/results/csv/results.csv
printf "\tTotal\t"$napoholo"\t"$napoholocavities"\n\n" >> "$mypath"/results/csv/results.csv


#-----------------------------------------------------------------------------------------
# Joint APO and HOLO results into a separate table  of 'results.csv';
# these results are produced for the four methods in CaVBench;
# note that the precision, recall and F-score are here calculated from TP, FP, and FN
#-----------------------------------------------------------------------------------------
fpocket_geral=$(head -1 "$mypath"/results/csv/TPFPFN_apo_holo.txt | tail -1 | awk '{printf ("\tFpocket\t%d\t%d\t%d\t%d\t\t%0.4f\t%0.4f\t%0.4f\n",$1,$2,$3,$4,$2/($2+$3),$2/($2+$4),2*$2/((2*$2)+$3+$4))}')
gaussian_geral=$(head -2 "$mypath"/results/csv/TPFPFN_apo_holo.txt | tail -1 | awk '{printf ("\tGaussian\t%d\t%d\t%d\t%d\t\t%0.4f\t%0.4f\t%0.4f\n",$1,$2,$3,$4,$2/($2+$3),$2/($2+$4),2*$2/((2*$2)+$3+$4))}')
ghecom_geral=$(head -3 "$mypath"/results/csv/TPFPFN_apo_holo.txt | tail -1 | awk '{printf ("\tGhecom\t%d\t%d\t%d\t%d\t\t%0.4f\t%0.4f\t%0.4f\n",$1,$2,$3,$4,$2/($2+$3),$2/($2+$4),2*$2/((2*$2)+$3+$4))}')
kvfinder_geral=$(head -4 "$mypath"/results/csv/TPFPFN_apo_holo.txt | tail -1 | awk '{printf ("\tKvfinder\t%d\t%d\t%d\t%d\t\t%0.4f\t%0.4f\t%0.4f\n",$1,$2,$3,$4,$2/($2+$3),$2/($2+$4),2*$2/((2*$2)+$3+$4))}')
printf "\t\t\tResults\n" >> "$mypath"/results/csv/results.csv
printf "\t\t#Cavities\tTP\tFP\tFN\t\tPrecision\tRecall\tFscore\n" >> "$mypath"/results/csv/results.csv
echo "$fpocket_geral" >> "$mypath"/results/csv/results.csv
echo "$gaussian_geral" >> "$mypath"/results/csv/results.csv
echo "$ghecom_geral" >> "$mypath"/results/csv/results.csv
echo "$kvfinder_geral" >> "$mypath"/results/csv/results.csv
printf "\n\n" >> "$mypath"/results/csv/results.csv

#-----------------------------------------------------------------------------------------
# APO results into a separate table  of 'results.csv';
# these results are produced for the four methods in CaVBench;
# note that the precision, recall and F-score are here calculated from TP, FP, and FN
#-----------------------------------------------------------------------------------------
fpocket_apo=$(head -1 "$mypath"/results/csv/TPFPFN_apo.txt | tail -1 | awk '{printf ("\tFpocket\t%d\t%d\t%d\t%d\t\t%0.4f\t%0.4f\t%0.4f\n",$1,$2,$3,$4,$2/($2+$3),$2/($2+$4),2*$2/((2*$2)+$3+$4))}')
gaussian_apo=$(head -2 "$mypath"/results/csv/TPFPFN_apo.txt | tail -1 | awk '{printf ("\tGaussian\t%d\t%d\t%d\t%d\t\t%0.4f\t%0.4f\t%0.4f\n",$1,$2,$3,$4,$2/($2+$3),$2/($2+$4),2*$2/((2*$2)+$3+$4))}')
ghecom_apo=$(head -3 "$mypath"/results/csv/TPFPFN_apo.txt | tail -1 | awk '{printf ("\tGhecom\t%d\t%d\t%d\t%d\t\t%0.4f\t%0.4f\t%0.4f\n",$1,$2,$3,$4,$2/($2+$3),$2/($2+$4),2*$2/((2*$2)+$3+$4))}')
kvfinder_apo=$(head -4 "$mypath"/results/csv/TPFPFN_apo.txt | tail -1 | awk '{printf ("\tKvfinder\t%d\t%d\t%d\t%d\t\t%0.4f\t%0.4f\t%0.4f\n",$1,$2,$3,$4,$2/($2+$3),$2/($2+$4),2*$2/((2*$2)+$3+$4))}')
printf "\t\t\tAPOs\n" >> "$mypath"/results/csv/results.csv
printf "\t\t#Cavities\tTP\tFP\tFN\t\tPrecision\tRecall\tFscore\n" >> "$mypath"/results/csv/results.csv
echo "$fpocket_apo" >> "$mypath"/results/csv/results.csv
echo "$gaussian_apo" >> "$mypath"/results/csv/results.csv
echo "$ghecom_apo" >> "$mypath"/results/csv/results.csv
echo "$kvfinder_apo" >> "$mypath"/results/csv/results.csv
printf "\n\n" >> "$mypath"/results/csv/results.csv

#-----------------------------------------------------------------------------------------
# HOLO results into a separate table  of 'results.csv'
# these results are produced for the four methods in CaVBench;
# note that the precision, recall and F-score are here calculated from TP, FP, and FN
#-----------------------------------------------------------------------------------------
fpocket_holo=$(head -1 "$mypath"/results/csv/TPFPFN_holo.txt | tail -1 | awk '{printf ("\tFpocket\t%d\t%d\t%d\t%d\t\t%0.4f\t%0.4f\t%0.4f\n",$1,$2,$3,$4,$2/($2+$3),$2/($2+$4),2*$2/((2*$2)+$3+$4))}')
gaussian_holo=$(head -2 "$mypath"/results/csv/TPFPFN_holo.txt | tail -1 | awk '{printf ("\tGaussian\t%d\t%d\t%d\t%d\t\t%0.4f\t%0.4f\t%0.4f\n",$1,$2,$3,$4,$2/($2+$3),$2/($2+$4),2*$2/((2*$2)+$3+$4))}')
ghecom_holo=$(head -3 "$mypath"/results/csv/TPFPFN_holo.txt | tail -1 | awk '{printf ("\tGhecom\t%d\t%d\t%d\t%d\t\t%0.4f\t%0.4f\t%0.4f\n",$1,$2,$3,$4,$2/($2+$3),$2/($2+$4),2*$2/((2*$2)+$3+$4))}')
kvfinder_holo=$(head -4 "$mypath"/results/csv/TPFPFN_holo.txt | tail -1 | awk '{printf ("\tKvfinder\t%d\t%d\t%d\t%d\t\t%0.4f\t%0.4f\t%0.4f\n",$1,$2,$3,$4,$2/($2+$3),$2/($2+$4),2*$2/((2*$2)+$3+$4))}')
printf "\t\t\tHOLOs\n" >> "$mypath"/results/csv/results.csv
printf "\t\t#Cavities\tTP\tFP\tFN\t\tPrecision\tRecall\tFscore\n" >> "$mypath"/results/csv/results.csv
echo "$fpocket_holo" >> "$mypath"/results/csv/results.csv
echo "$gaussian_holo" >> "$mypath"/results/csv/results.csv
echo "$ghecom_holo" >> "$mypath"/results/csv/results.csv
echo "$kvfinder_holo" >> "$mypath"/results/csv/results.csv
printf "\n\n" >> "$mypath"/results/csv/results.csv


#-----------------------------------------------------------------------------------------
#remove all the temporary files needed
#-----------------------------------------------------------------------------------------
rm -r -f "$mypath"/results/csv/TPFPFN_apo_holo.txt "$mypath"/results/csv/TPFPFN_holo.txt "$mypath"/results/csv/TPFPFN_apo.txt
rm -r -f  "$mypath"/results/temp/* 

# end of the file
