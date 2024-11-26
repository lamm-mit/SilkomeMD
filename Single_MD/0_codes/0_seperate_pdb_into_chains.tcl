## MD simulation script for spider silk protein
## Author: Wei Lu & Markus J. Buehler, Department of Civil and Environmental Engineering, Massachusetts Institute of Technology
## November 2024

### prepare
source path_lib.dat

set raw_pdb_file RAW_PDB
set prefix TestProt


mol load pdb ./${raw_pdb_file}.pdb
# handle water part
puts "Working on water part"
set water [atomselect top water]
$water writepdb ./${prefix}_0_water.pdb
# handle protein parts
puts "Working on protein part"
set protein [atomselect top protein]
set chains [lsort -unique [$protein get pfrag]]
foreach chain $chains {
set sel [atomselect top "pfrag $chain"]
$sel writepdb ./${prefix}_chain_${chain}.pdb
}
exit

