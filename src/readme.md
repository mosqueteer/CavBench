# .cpp Files 

This folder contains the three .cpp files of CavBench:

<code>dummyatompairs.cpp</code> : this file produces the pairs <C,c> that identify the the overlapping dummy atoms between ground-truth cavities (C) and method-specific cavities (c).

<code>overlappingmatrices.cpp</code> : This file produces an overlapping matrix for each protein. These overlapping matrices are calculated from dummy atom pairs above.

<code>tp_fp_fn.cpp</code> : This file calculates the values of true positives (TP), false positives (FP), and false negatives for each protein. These values are obtained from the overlapping matrices calculated previously.

# Compilation

These three files are compiled by the shell script <code>cavbench.sh</code> in the CavBench root folder.

