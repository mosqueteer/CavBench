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
// This program computes the pairs of of dummy atoms (i,j) of overlapping cavities,
// where i denotes the i-th ground-truth cavity, and j the j-th method-specific cavity.
//
// REMARK:
// ------
// We assume that two dummy atoms overlap when the distance between their centers are 
// within 2 Angstroms.
// We also assume that every single dummy atom is radius 1.
//
// SYNOPSIS:
// --------
// 	dummyatompairs.exe <gt-file.csv> <ms-file.csv>
//
// where:
//		gt-file.csv: a ground-truth .csv file describing the cavities of a protein;
//		ms-file.csv: a method-specific .csv file describing the cavities of a protein;
// 
// INPUT FILE FORMAT:
// -----------------
//	x y z id
//
// 	where
//		(x,y,z): Cartesian coordinates of each dummy atom center
//		id: 	 cavity identifier
//---------------------------------------------------------------------------------------


#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <vector>

using namespace std;

class CAVPOINT3D{
public:
    float coord[3];	// Cartesian coordinates
    int id;		// cavity id
};

class DUMMYATOMPAIR{
public:
	int i;			// ground-truth cavity id
	int j; 			// method-specific cavity id
};

vector<CAVPOINT3D> U;
vector<CAVPOINT3D> V;
vector<DUMMYATOMPAIR> D;

//---------------------------------------------------------------------------------------
int main(int argc, char* argv[])
{
  
  FILE *fU, *fV;
  float x,y,z;
  int id; 
  float a;
  float distance = 2.0; // reference distance between dummy atoms
  
  fU=fopen(argv[1], "r"); 	// first input file <gt-file.csv> 
  fV=fopen(argv[2], "r"); 	// second input file <ms-file.csv> 
  
  if(!fU || !fV){
      printf("Error in openning input files");
  }  
  
  while (!feof(fU)) {      
      fscanf(fU,"%f %f %f %d",&x,&y,&z,&id);
      CAVPOINT3D *p = new CAVPOINT3D();
      p->coord[0] = x;
      p->coord[1] = y;
      p->coord[2] = z; 
      p->id = id;
      U.push_back(*p);
  }
   
   // read in dummy atoms of the cavities for a specific cavity detection method 
  while (!feof(fV)) {       
       fscanf(fV,"%f %f %f %d",&x,&y,&z,&id);
       CAVPOINT3D *p = new CAVPOINT3D();
       p->coord[0] = x;
       p->coord[1] = y;
       p->coord[2] = z; 
       p->id = id;
       V.push_back(*p);
  }
  
  fclose(f);
  fclose(g);


	// compute dummy atom pairs
  for(int i=0;i<U.size(); i++){
       for(int j=0;j<V.size(); j++){
        	a = (powf((U[i].coord[0]-V[j].coord[0]),2)+powf((U[i].coord[1]-V[j].coord[1]),2)+powf((U[i].coord[2]-V[j].coord[2]),2))-distance;
           
           	if(a<0){
               DUMMYATOMPAIR *d = new DUMMYATOMPAIR();
               d->i = U[i].id;
               d->j = V[j].id;
               D.push_back(*d);
           	}
       }
   }
   
	// writing pairs of dummy atoms (cavity spheres) to the output file 
  for(int i=0;i<D.size();i++){
        printf("%i\t%i\n",D[i].i,D[i].j);
    }
}

// end of the file

