//---------------------------------------------------------------------------------------
//
//	CavBench - A benchmark to compare protein cavity detection methods
//
//  	Copyright (C) 2018 Instituto de Telecomunicações (www.it.pt)
//  	Copyright (C) 2018 Universidade da Beira Interior (www.ubi.pt)
// 	Copyright (C) 2018 INESC-ID, Universidade de Lisboa (www.inesc.pt)
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
// This program computes the overlapping matrix for a protein, i.e. the percentages of 
// its cavities that are intersected by cavities of a specific method.
//
// SYNOPSIS:
// --------
// 	overlappingmatrix.exe <gt-file.csv>  <da-file.txt> <n> <m> 
//
// where:
//		gt-file.csv: ground-truth .csv file describing the cavities of a protein;
//		ms-file.csv: method-specific .csv file describing the cavities of a protein;
//  	<n>:		 the number of ground-truth cavities of a protein
//  	<m>: 		 the number of method-specific cavities of a protein
// 
// INPUT FILE FORMAT of <gt-file.csv>:
// -----------------
//	x y z id
//
// 	where
//		 (x,y,z): Cartesian coordinates of each dummy atom center
//		 id: 	  cavity identifier
//
// INPUT FILE FORMAT of <da-file.txt>:
// -----------------
//	i j 
//
//  where
// 		i: identifier of the ground-truth cavity
//		j: identifier of the method-specific cavity


//---------------------------------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <math.h>
#include <vector>

using namespace std;

class CAVPOINT3D{
public:
    float coord[3];			// Cartesian coordinates
    int id;					// cavity id
};

class DUMMYATOMPAIR{
public:
	int i;					// ground-truth cavity id
	int j; 					// method-specific cavity id
};

vector<int> ID;				// vector to host the 4-th colum of ids in .csv file concerning ground-truth cavities for a protein
vector<DUMMYATOMPAIR> D;	// vector to host dummy atom pairs (C,c) for a protein



//-----------------------------------------------------------------------------
// 
int main(int argc, char* argv[])
//-----------------------------------------------------------------------------
{

    FILE *f,*g;
    float x,y,z;
    int id;


		// .csv file describing the method-specific cavities for a protein 
		// according to the format (x,y,z,id)
    f=fopen(argv[1], "r"); 
    
    	// .txt file containing the dummy atom pairs (C,c) for a protein,
    	// C is an id of some ground-truth cavity and
    	// c is an id of some method-specific cavity
    g=fopen(argv[2], "r"); 
    
    	//check if files are open correctly
    if(!f || !g){
        printf("Error open the files");
    }
    
    	// number of method-specific cavities for a protein
    int ngc = atoi(argv[3]); 
    
    	// number of method-specific cavities for a protein
    int nmc =atoi(argv[4]);  
    

    	// read .csv file concerning ground-truth cavities for a protein
    while (!feof(f)){        
        fscanf(f,"%f %f %f %f",&x,&y,&z,&id);
        	// ignores (x,y,z) for counting dummy atoms of ground-truth cavities for a protein
        ID.push_back(*id);  
    }
    
    
    float i,j;   
    	// read .txt file containing pairs of dummy atoms for a protein
    while (!feof(g)){        
        fscanf(g,"%f %f",&i,&j);       
        DUMMYATOMPAIR *d = new DUMMYATOMPAIR();
        d->i = i; 
        d->j = j; 
        D.push_back(*d);
    }
    
    fclose(f);
    fclose(g);
         
     	// initialize vector to store the number of dummy atoms for each ground-truth cavity
	int *V;
	V = (int *)malloc(ngc*sizeof(int));
	for(int i=0;i<ngc;i++){
            V[i]=0;
    }
    

		// count the number of dummy atoms for each ground-truth cavity
    for(int i=0;i<ID.size();i++){
        for(int j=0;j<ngc;j++){
            if(ID[i]==j){
                V[j]++;
            }
        }
    }
    
    
    	// create memory room for overlapping matrix
    	// rows -> method-specific cavities $nmc
    	// columns -> ground-truth cavities $ngc
    float **overlappingmatrix;
    overlappingmatrix=(float **)malloc(nmc*sizeof(float*));
    for(int i=0;i<nmc;i++)
        overlappingmatrix[rt]=(float *)malloc(ngc*sizeof(float));

    	// initialize overlapping matrix with 0s
    for(int i=0;i<nmc;i++){
        for(int j=0;j<ngc;j++){
            overlappingmatrix[i][j]=0;
        }
    }
    
    
    	// filling in overlapping matrix with data concerning overlapping dummy atoms
    for(int k=0;k<D.size();k++){
        int i=D[k].i;
        int j=D[k].j;
        overlappingmatrix[i][j]=overlappingmatrix[i][j]+1;
    }
    

    	// computes percentages of ground-truth cavities that re overlapped by method-specific cavities
    for(int i=0;i<nmc;i++){
        for(int j=0;j<ngc;j++){
            if(overlappingmatrix[i][j]>0)
                overlappingmatrix[i][j] = (overlappingmatrix[i][j] * 100) / V[j];
        }
    }
    
         
		// writing overlapping matrix to a .txt output file 
    for(int i=0;i<nmv;i++){
        for(int j=0;j<ngc;j++){
            printf("%0.3f\t",overlappingmatrix[i][j]);
        }
        printf("\n");
    }
    
    
}

// end of the file
