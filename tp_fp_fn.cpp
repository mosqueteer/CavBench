//---------------------------------------------------------------------------------------
//
//	CavBench - A benchmark to compare protein cavity detection methods
//
//  	Copyright (C) 2018 Instituto de Telecomunicações & University of Beira Interior
//
//  	This program is free software: you can redistribute it and/or modify
//  	it under the terms of the GNU General Public License as published by
//  	the Free Software Foundation, either version 3 of the License, or
//  	(at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//	Contacts: 
//			Sergio Dias <sergioduartedias@sapo.pt>
//			Abel Gomes <agomes@di.ubi.pt>
//---------------------------------------------------------------------------------------


//---------------------------------------------------------------------------------------
// DESCRIPTION:
// -----------
// This program computes the number of TP, FP, and FN from the overlapping matrix of a
// protein for a given method. 
//
// SYNOPSIS:
// --------
// 	tp_fp_fn.exe <omatrix.txt> <n> <m> 
//
// where:
//	    omatrix.txt: the .txt file describing the overlapping matrix for a protein $p and method $m;
//  	<n>:		 the number of ground-truth cavities of a protein
//  	<m>: 		 the number of method-specific cavities of a protein
// 
//---------------------------------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <math.h>
#include <vector>


using namespace std;


//---------------------------------------------------------------------------------------
int main(int argc, char* argv[])
{

    FILE *f;
    float x;
    int TP=0, FP=0, FN=0;

		// open .txt file describing overlapping matrix
    f=fopen(argv[1], "r"); 
    
    	// check if overlapping matrix file has been opened correctly
    if(!f){
      printf("Error in openning overlapping matrix file");
    }
    
    int ngc = atoi(argv[3]); 
    int nmc = atoi(argv[4]);  
    

    	// create memory room for overlapping matrix
    	// rows -> method-specific cavities $nmc
    	// columns -> ground-truth cavities $ngc
    float **overlappingmatrix;
    overlappingmatrix=(float **)malloc(nmc*sizeof(float*));
    for(int i=0;i<nmc;i++)
        overlappingmatrix[rt]=(float *)malloc(ngc*sizeof(float));

    	// fill in overlapping matrix 
    for(int i=0;i<nmc;i++){
        for(int j=0;j<ngc;j++){
        	fscanf(f,"%f",&x);
            overlappingmatrix[i][j]=x;
        }
    }
    
    
    
    	// compute true positives (TP) 
    for(int i=0;i<nmc;i++){
        for(int j=0;j<ngc;j++){
            if(overlappingmatrix[i][j]>0)
                TP++;
        }
    }
    
 
    
    	// compute false negatives (FN);
    	// one FN corresponds to a column of zeros
    for(int j=0;j<ngc;j++){
        int counter=0;
        for(int i=0;i<nmc;i++){
            if(overlappingmatrix[i][j]==0){
                counter++;
            }
        }        
        if(counter==nmc){
            FN++;
        }
    }

     
    	// compute false positives (FP);
    	// one FP corresponds to a row of zeros
    for(int i=0;i<nmc;i++){
        int counter=0;
        for(int j=0;j<ngc;j++){
            if(overlappingmatrix[i][j]==0){
                counter++;
            }
        }        
        if(counter==ngc){
            FP++;
        }
    }


    printf("%d\t%d\t%d\t%d\n",nmc,TP,FP,FN);
}

// end of the file


