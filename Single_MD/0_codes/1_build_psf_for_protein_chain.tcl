## MD simulation script for spider silk protein
## Author: Wei Lu & Markus J. Buehler, Department of Civil and Environmental Engineering, Massachusetts Institute of Technology
## November 2024

### prepare
source path_lib.dat

# set raw_pdb_file 1ubq_from_web
set prefix TestProt
#
set chain 0

package require psfgen


topology ../${code_path}/top_all27_prot_lipid.inp
# topology ./top_all36_prot.rtf
# topology ./par_all27_prot_lipid.inp

pdbalias residue HIS HSE
pdbalias atom ILE CD1 CD

# segment U {pdb ./${prefix}_chain_${chain}.pdb}
# coordpdb ./${prefix}_chain_${chain}.pdb U
segment U {pdb ./RAW_PDB.pdb}
coordpdb ./RAW_PDB.pdb U
guesscoord


writepdb ./${prefix}_chain_${chain}_after_psf.pdb
writepsf ./${prefix}_chain_${chain}_after_psf.psf

exit
