### MD simulation script for spider silk protein
### Author: Wei Lu & Markus J. Buehler, Department of Civil and Environmental Engineering, Massachusetts Institute of Technology
### November 2024

#!/bin/bash
#SBATCH --job-name=""
#SBATCH --output=cout.txt
#SBATCH --error=cerr.txt

echo
echo "============================ Messages from Goddess ============================"
echo " * Job starting from: "`date`
echo " * Job ID           : "$SLURM_JOBID
echo " * Job name         : "$SLURM_JOB_NAME
echo " * Working directory: "${SLURM_SUBMIT_DIR/$HOME/"~"}
echo "==============================================================================="
echo

# module load namd/2.14
module load gcc/9.3.0
module load namd/3.0alpha9

module add anaconda3/2021.11
module add cuda/10.2
module add cudnn/8.2.2_cuda10.2

source activate SilkProtein #GNN_Ex3

echo "Preparation is done"


### 
vmd_commad=/home/wl7/ondemand/Software/vmd-1.9.3/bin/vmd
namd_commad=/home/wl7/ondemand/Software/NAMD_2.14_Linux-x86_64-multicore/namd2
catdcd_commad=/home/wl7/ondemand/Software/catdcd/LINUXAMD64/bin/catdcd4.0/catdcd

### ---------------------------------
# Define the file name as a variable
file_name="KRT31.pdb"
pdb_path_batch="../datafile/1_50/"
### ---------------------------------

pdb_path="${pdb_path_batch}${file_name}"

# locate the pdb file
cp ${pdb_path} ./
mv ${file_name} temp.pdb

###
### control keys
# IF_Sepe_Chain=1
IF_Gene_psf=1
IF_Prep_WS=1
IF_Run_Eq=1
IF_Ana_eq=1
IF_Run_SMD=1
IF_Ana_smd=1
IF_Make_Movie=0

#p16 tested faster than 32, 8, 4
num_cpu=16

this_pdb=temp.pdb

# preparation
code_path=0_codes
work_path=1_working_dir
resu_path=2_results_dir

# under the work_path
MD_eqi_path=1_Equilibrate_system/
MD_smd_path=2_Loading/
MD_pict=md_pict

if [[ -d "./${work_path}" ]]; ### if path exists
then
    echo "Working path exists. May clean it up"
else
    echo "Creating the working path"
    mkdir ./${work_path}
fi

cd ${work_path}

log_file=$PWD/run_monitor.log
# make one-time log file
echo "Beginning of a run..." > ${log_file}
# copy the scripts
cp ../${code_path}/path_lib.dat ./
cp ../${code_path}/0_seperate_pdb_into_chains.tcl ./
cp ../${code_path}/1_build_psf_for_protein_chain.tcl ./

cp ../${code_path}/2_rotate_and_position_one_chain_ImplicitWater.tcl ./
# # MD: eq

# 
cp ../$this_pdb ./RAW_PDB.pdb


# 1. psf file generation
time_1=$SECONDS

if [ $IF_Gene_psf -eq 1 ]
then
    log_line="1. Create psf for chain A..."
    echo $log_line
	echo $log_line >> ${log_file}
    # should get TestProt_chain_0_after_psf.pdb+psf, check

    check_file=./TestProt_chain_0_after_psf.psf
    if [[ -f ${check_file} ]]; then
        log_line="Already done."
        echo $log_line
	    echo $log_line >> ${log_file}
    else
        ${vmd_commad} -dispdev text -e ./1_build_psf_for_protein_chain.tcl
	
        if [[ -f ./TestProt_chain_0_after_psf.pdb && -f ./TestProt_chain_0_after_psf.psf ]];
        then
            log_line="Excuting: Done."
        else
            log_line="Excuting: Error!!!!!!!!!!!!!!"
        fi
        echo $log_line
        echo $log_line >> ${log_file}
    fi	
fi
time_2=$SECONDS
echo "used time: $(($time_2-$time_1))" >>  ${log_file}


# 2. solvation
time_1=$SECONDS
if [ $IF_Prep_WS -eq 1 ]
then
    log_line="2. Add into water sphere..."
    echo $log_line
	echo $log_line >> ${log_file}

    # should get TestProt_chain_0_after_psf_AlongX_WS.pdf+psf+ref
    check_file_1=./TestProt_chain_0_after_psf_AlongX.ref
    check_file_2=./TestProt_chain_0_after_psf_AlongX.pdb
    # check_file_3=./TestProt_chain_0_after_psf_AlongX_WS.psf
    # if [[ -f $check_file_1 && -f $check_file_2 && -f $check_file_3 ]]; then
    if [[ -f $check_file_1 && -f $check_file_2 ]]; then
        log_line="Already done."
        echo $log_line
	    echo $log_line >> ${log_file}
    else

        ${vmd_commad} -dispdev text -e 2_rotate_and_position_one_chain_ImplicitWater.tcl
        # should get TestProt_chain_0_after_psf_AlongX_WB.ref, check
        if [[ -f "./TestProt_chain_0.pdb" ]];
        then
            log_line="Excuting: Done."
        else
            log_line="Excuting: Error!!!!!!!!!!!!!!"
        fi
        echo $log_line
        echo $log_line >> ${log_file}
    fi
fi
time_2=$SECONDS
echo "used time: $(($time_2-$time_1))" >>  ${log_file}


# 3. Equilibration - NPT
mkdir -p $MD_eqi_path
cd $MD_eqi_path
# for continous operation
ContiFile=./ContiInfo.dat
# for real run
if [[ ! -e $ContiFile ]]; then
    touch $ContiFile
    echo "set MinStep     10000" >> $ContiFile
    echo "set NPTStep_S1 250000"  >> $ContiFile
    echo "set NPTStep_S2 250000"  >> $ContiFile
    echo "set NPTStep_S3 300000"  >> $ContiFile
fi
# # for debug
# if [[ ! -e $ContiFile ]]; then
    # touch $ContiFile
    # echo "set MinStep    10000" >> $ContiFile
    # echo "set NPTStep_S1 4000"  >> $ContiFile
    # echo "set NPTStep_S2 4000"  >> $ContiFile
    # echo "set NPTStep_S3 4000"  >> $ContiFile
# fi
# for MD log files
target_word="End of program"

log_line="3. Minimization + NPT with OX constrain ..."
echo $log_line
echo $log_line >> ${log_file}

# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# S1
time_1=$SECONDS
if [ $IF_Run_Eq -eq 1 ]
then
    log_line="3.1 Stage 1 of 3 ..."
    echo $log_line
    echo $log_line >> ${log_file}

    # 1. check wether it has been finished
    task_name=0_EneMin_NPT_withConstrain_S1

    task_log_file=${task_name}.log
    last_line=$( tail -n 1 $task_log_file )
    last_three_word=$( echo $last_line | rev | awk '{NF=3}1' |rev )
    # for debug
    echo $last_three_word

    if [[ "$last_three_word" == "$target_word" ]]; then
        log_line="Already done."
        echo $log_line
	    echo $log_line >> ${log_file}
    else
        log_line="Excuting ..."
        echo $log_line
	    echo $log_line >> ${log_file}

        # cp ../../${code_path}/0_EneMin_NPT_withConstrain.conf ./
        cp ../../${code_path}/${task_name}.conf ./

        NODELIST=./namd3.nodelist
        echo "group main ++cpus $SLURM_CPUS_ON_NODE" > $NODELIST
        for host in $(scontrol show hostname $SLURM_JOB_NODELIST); do
        echo " host $host ++shell "ssh -o StrictHostKeyChecking=no"" >> $NODELIST
        done
        
        chmod 777 ./namd3.nodelist
        
        namdc=/home/software/namd/3.0alpha9/namd3
       
        time $namdc +p4 +setcpuaffinity --CUDASOAintegrate off +idlepoll +devices 0 +ignoresharing ${task_name}.conf > $task_log_file

        rm $NODELIST

        last_line=$( tail -n 1 $task_log_file )
        last_three_word=$( echo $last_line | rev | awk '{NF=3}1' |rev )

        if [[ "$last_three_word" == "$target_word" ]]; then
            log_line="Done"
        else
            log_line="Error!!!!!!!!!!!!!!"
        fi
        echo $log_line
        echo $log_line >> ${log_file}
    fi
fi
time_2=$SECONDS
echo "used time: $(($time_2-$time_1))" >>  ${log_file}

# S2
time_1=$SECONDS
if [ $IF_Run_Eq -eq 1 ]
then
    log_line="3.2 Stage 2 of 3 ..."
    echo $log_line
    echo $log_line >> ${log_file}

    # 1. check wether it has been finished
    task_name=0_EneMin_NPT_withConstrain_S2

    task_log_file=${task_name}.log
    last_line=$( tail -n 1 $task_log_file )
    last_three_word_2=$( echo $last_line | rev | awk '{NF=3}1' |rev )

    if [[ "$last_three_word_2" == "$target_word" ]]; then
        log_line="Already done."
        echo $log_line
	    echo $log_line >> ${log_file}
    else
        log_line="Excuting ..."
        echo $log_line
	    echo $log_line >> ${log_file}

        # cp ../../${code_path}/0_EneMin_NPT_withConstrain.conf ./
        cp ../../${code_path}/${task_name}.conf ./

        NODELIST=./namd3.nodelist
        echo "group main ++cpus $SLURM_CPUS_ON_NODE" > $NODELIST
        for host in $(scontrol show hostname $SLURM_JOB_NODELIST); do
        echo " host $host ++shell "ssh -o StrictHostKeyChecking=no"" >> $NODELIST
        done
        
        chmod 777 ./namd3.nodelist
        
        namdc=/home/software/namd/3.0alpha9/namd3
        
        # Dynamics
        # for j in 1 2 ; do
        # 	echo "Running eq$j... | `date`"
        # 	time $namdc +p4 +setcpuaffinity --CUDASOAintegrate off +idlepoll +devices 0 +ignoresharing eq$j.namd > eq$j.log
        # done
        
        time $namdc +p4 +setcpuaffinity --CUDASOAintegrate off +idlepoll +devices 0 +ignoresharing ${task_name}.conf > $task_log_file
        # time $namdc +p16 +setcpuaffinity --CUDASOAintegrate off +idlepoll +devices 0 +ignoresharing ${task_name}.conf > $task_log_file

        rm $NODELIST

        last_line=$( tail -n 1 $task_log_file )
        last_three_word=$( echo $last_line | rev | awk '{NF=3}1' |rev )

        if [[ $last_three_word=='End_of program' ]]; then
            log_line="Done"
        else
            log_line="Error!!!!!!!!!!!!!!"
        fi
        echo $log_line
        echo $log_line >> ${log_file}
    fi
fi
time_2=$SECONDS
echo "used time: $(($time_2-$time_1))" >>  ${log_file}


# S3
time_1=$SECONDS
if [ $IF_Run_Eq -eq 1 ]
then
    log_line="3.3 Stage 3 of 3 ..."
    echo $log_line
    echo $log_line >> ${log_file}

    # 1. check wether it has been finished
    task_name=0_EneMin_NPT_withConstrain_S3

    task_log_file=${task_name}.log
    last_line=$( tail -n 1 $task_log_file )
    last_three_word_3=$( echo $last_line | rev | awk '{NF=3}1' |rev )

    if [[ "$last_three_word_3" == "$target_word" ]]; then
        log_line="Already done."
        echo $log_line
	    echo $log_line >> ${log_file}
    else
        log_line="Excuting ..."
        echo $log_line
	    echo $log_line >> ${log_file}

        # cp ../../${code_path}/0_EneMin_NPT_withConstrain.conf ./
        cp ../../${code_path}/${task_name}.conf ./

        NODELIST=./namd3.nodelist
        echo "group main ++cpus $SLURM_CPUS_ON_NODE" > $NODELIST
        for host in $(scontrol show hostname $SLURM_JOB_NODELIST); do
        echo " host $host ++shell "ssh -o StrictHostKeyChecking=no"" >> $NODELIST
        done
        
        chmod 777 ./namd3.nodelist
        
        namdc=/home/software/namd/3.0alpha9/namd3
        
        time $namdc +p4 +setcpuaffinity --CUDASOAintegrate off +idlepoll +devices 0 +ignoresharing ${task_name}.conf > $task_log_file
        # time $namdc +p16 +setcpuaffinity --CUDASOAintegrate off +idlepoll +devices 0 +ignoresharing ${task_name}.conf > $task_log_file

        rm $NODELIST

        last_line=$( tail -n 1 $task_log_file )
        last_three_word=$( echo $last_line | rev | awk '{NF=3}1' |rev )

        if [[ $last_three_word=='End_of program' ]]; then
            log_line="Done"
        else
            log_line="Error!!!!!!!!!!!!!!"
        fi
        echo $log_line
        echo $log_line >> ${log_file}
    fi
fi
time_2=$SECONDS
echo "used time: $(($time_2-$time_1))" >>  ${log_file}

# Merge the results
time_1=$SECONDS
if [ $IF_Run_Eq -eq 1 ]
then
    log_line="Merge the results and prepare the next step."
    echo $log_line
    echo $log_line >> ${log_file}

    out_dcd="./TestProt_chain_0_after_psf_AlongX_NPT.dcd"
    if [[ ! -e $out_dcd ]]; then
        # on dcd
        dcd_1=TestProt_chain_0_after_psf_AlongX_NPT_S1.dcd
        dcd_2=TestProt_chain_0_after_psf_AlongX_NPT_S2.dcd
        dcd_3=TestProt_chain_0_after_psf_AlongX_NPT_S3.dcd

        # dcd_out=TestProt_chain_0_after_psf_AlongX_WB_NPT.dcd
        ${catdcd_commad} -o ${out_dcd} ${dcd_1} ${dcd_2} ${dcd_3}

    fi

    # on log file
    out_log="./0_EneMin_NPT_withConstrain.log"
    if [[ ! -e $out_log ]]; then
        ene_log_1=0_EneMin_NPT_withConstrain_S1.log
        ene_log_2=0_EneMin_NPT_withConstrain_S2.log
        ene_log_3=0_EneMin_NPT_withConstrain_S3.log

        cat ${ene_log_1} ${ene_log_2} ${ene_log_3} > $out_log 

    fi

    # on the restart files
    rest_1=TestProt_chain_0_after_psf_AlongX_NPT.restart.coor
    rest_2=TestProt_chain_0_after_psf_AlongX_NPT.restart.vel
    rest_3=TestProt_chain_0_after_psf_AlongX_NPT.restart.xsc
    if [[ ! -e $rest_1 ]]; then
        cp TestProt_chain_0_after_psf_AlongX_NPT_S3.restart.coor ${rest_1}
    fi
    if [[ ! -e $rest_2 ]]; then
        cp TestProt_chain_0_after_psf_AlongX_NPT_S3.restart.vel  ${rest_2}
    fi
    if [[ ! -e $rest_3 ]]; then
        cp TestProt_chain_0_after_psf_AlongX_NPT_S3.restart.xsc  ${rest_3}
    fi

    log_line="Done."
    echo $log_line
    echo $log_line >> ${log_file}
fi
time_2=$SECONDS
echo "used time: $(($time_2-$time_1))" >>  ${log_file}
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
cd ../


# 4. Equilibration result analysis
# prepare to collect results:
time_1=$SECONDS
if [ $IF_Ana_eq -eq 1 ]
then
    log_line="4. Analyze the eq results..."
    echo $log_line
    echo $log_line >> ${log_file}

    # deliver files
    cp ../${code_path}/3_analyze_eq.tcl ./
    cp ../${code_path}/fun_0_namdstats_adjusted.tcl ./

	mkdir -p ./collect_results

    check_file=./collect_results/TOTAL.dat
    if [[ -f ${check_file} ]]; then
        log_line="Already done."
        echo $log_line
	    echo $log_line >> ${log_file}
    else
        log_line="4. Excuting..."
        echo $log_line
        echo $log_line >> ${log_file}

        ${vmd_commad} -dispdev text -e 3_analyze_eq.tcl

        if [[ -f ${check_file} ]]; then
            log_line="Done"
        else
            log_line="Error!!!!!!!!!!!!!!!!!!"
        fi
        echo $log_line
        echo $log_line >> ${log_file}
    fi

fi
time_2=$SECONDS
echo "used time: $(($time_2-$time_1))" >>  ${log_file}


# 5. SMD
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
log_line="5. NVT + SMD ..."
echo $log_line
echo $log_line >> ${log_file}

mkdir -p $MD_smd_path
cd $MD_smd_path

target_word="End of program"

# S1
time_1=$SECONDS
if [ $IF_Run_SMD -eq 1 ]
then    

    log_line="5.1 Stage 1 of 3 ..."
    echo $log_line
    echo $log_line >> ${log_file}

    # 1. check wether it has been finished
    task_name=1_Tension_AlongX_S1

    task_log_file=${task_name}.log
    last_line=$( tail -n 1 $task_log_file )
    last_three_word=$( echo $last_line | rev | awk '{NF=3}1' |rev )
    # for debug
    echo $last_three_word

    if [[ "$last_three_word" == "$target_word" ]]; then
        log_line="Already done."
        echo $log_line
	    echo $log_line >> ${log_file}
    else
        log_line="Excuting ..."
        echo $log_line
	    echo $log_line >> ${log_file}

        cp ../../${code_path}/${task_name}.conf ./

        NODELIST=./namd3.nodelist
        echo "group main ++cpus $SLURM_CPUS_ON_NODE" > $NODELIST
        for host in $(scontrol show hostname $SLURM_JOB_NODELIST); do
        echo " host $host ++shell "ssh -o StrictHostKeyChecking=no"" >> $NODELIST
        done
        
        chmod 777 ./namd3.nodelist
        
        namdc=/home/software/namd/3.0alpha9/namd3
  
        time $namdc +p4 +setcpuaffinity --CUDASOAintegrate off +idlepoll +devices 0 +ignoresharing ${task_name}.conf > $task_log_file
        # time $namdc +p16 +setcpuaffinity --CUDASOAintegrate off +idlepoll +devices 0 +ignoresharing ${task_name}.conf > $task_log_file

        rm $NODELIST

        last_line=$( tail -n 1 $task_log_file )
        last_three_word=$( echo $last_line | rev | awk '{NF=3}1' |rev )

        if [[ "$last_three_word" == "$target_word" ]]; then
            log_line="Done"
        else
            log_line="Error!!!!!!!!!!!!!!"
        fi
        echo $log_line
        echo $log_line >> ${log_file}
    fi

fi
time_2=$SECONDS
echo "used time: $(($time_2-$time_1))" >>  ${log_file}


# S2
time_1=$SECONDS
if [ $IF_Run_SMD -eq 1 ]
then    

    log_line="5.1 Stage 2 of 3 ..."
    echo $log_line
    echo $log_line >> ${log_file}

    # 1. check wether it has been finished
    task_name=1_Tension_AlongX_S2

    task_log_file=${task_name}.log
    last_line=$( tail -n 1 $task_log_file )
    last_three_word=$( echo $last_line | rev | awk '{NF=3}1' |rev )
    # for debug
    echo $last_three_word

    if [[ "$last_three_word" == "$target_word" ]]; then
        log_line="Already done."
        echo $log_line
	    echo $log_line >> ${log_file}
    else
        log_line="Excuting ..."
        echo $log_line
	    echo $log_line >> ${log_file}

        cp ../../${code_path}/${task_name}.conf ./

        NODELIST=./namd3.nodelist
        echo "group main ++cpus $SLURM_CPUS_ON_NODE" > $NODELIST
        for host in $(scontrol show hostname $SLURM_JOB_NODELIST); do
        echo " host $host ++shell "ssh -o StrictHostKeyChecking=no"" >> $NODELIST
        done
        
        chmod 777 ./namd3.nodelist
        
        namdc=/home/software/namd/3.0alpha9/namd3
        
        time $namdc +p4 +setcpuaffinity --CUDASOAintegrate off +idlepoll +devices 0 +ignoresharing ${task_name}.conf > $task_log_file
        # time $namdc +p16 +setcpuaffinity --CUDASOAintegrate off +idlepoll +devices 0 +ignoresharing ${task_name}.conf > $task_log_file

        rm $NODELIST

        # check
        # task_log_file=0_EneMin_NPT_withConstrain_S1.log
        last_line=$( tail -n 1 $task_log_file )
        last_three_word=$( echo $last_line | rev | awk '{NF=3}1' |rev )

        if [[ "$last_three_word" == "$target_word" ]]; then
            log_line="Done"
        else
            log_line="Error!!!!!!!!!!!!!!"
        fi
        echo $log_line
        echo $log_line >> ${log_file}
    fi

fi
time_2=$SECONDS
echo "used time: $(($time_2-$time_1))" >>  ${log_file}


# S3
time_1=$SECONDS
if [ $IF_Run_SMD -eq 1 ]
then    

    log_line="5.1 Stage 3 of 3 ..."
    echo $log_line
    echo $log_line >> ${log_file}

    # 1. check wether it has been finished
    task_name=1_Tension_AlongX_S3

    task_log_file=${task_name}.log
    last_line=$( tail -n 1 $task_log_file )
    last_three_word=$( echo $last_line | rev | awk '{NF=3}1' |rev )
    # for debug
    echo $last_three_word

    if [[ "$last_three_word" == "$target_word" ]]; then
        log_line="Already done."
        echo $log_line
	    echo $log_line >> ${log_file}
    else
        log_line="Excuting ..."
        echo $log_line
	    echo $log_line >> ${log_file}

        cp ../../${code_path}/${task_name}.conf ./

        NODELIST=./namd3.nodelist
        echo "group main ++cpus $SLURM_CPUS_ON_NODE" > $NODELIST
        for host in $(scontrol show hostname $SLURM_JOB_NODELIST); do
        echo " host $host ++shell "ssh -o StrictHostKeyChecking=no"" >> $NODELIST
        done
        
        chmod 777 ./namd3.nodelist
        
        namdc=/home/software/namd/3.0alpha9/namd3
        
        time $namdc +p4 +setcpuaffinity --CUDASOAintegrate off +idlepoll +devices 0 +ignoresharing ${task_name}.conf > $task_log_file

        rm $NODELIST

        last_line=$( tail -n 1 $task_log_file )
        last_three_word=$( echo $last_line | rev | awk '{NF=3}1' |rev )

        if [[ "$last_three_word" == "$target_word" ]]; then
            log_line="Done"
        else
            log_line="Error!!!!!!!!!!!!!!"
        fi
        echo $log_line
        echo $log_line >> ${log_file}
    fi

fi
time_2=$SECONDS
echo "used time: $(($time_2-$time_1))" >>  ${log_file}


# Merge the results
time_1=$SECONDS
if [ $IF_Run_Eq -eq 1 ]
then
    log_line="Merge the results and prepare the next step."
    echo $log_line
    echo $log_line >> ${log_file}

    out_dcd="./smdout.dcd"
    if [[ ! -e $out_dcd ]]; then
        # on dcd
        dcd_1=smdout_S1.dcd
        dcd_2=smdout_S2.dcd
        dcd_3=smdout_S3.dcd

        ${catdcd_commad} -o ${out_dcd} ${dcd_1} ${dcd_2} ${dcd_3}

    fi

    out_log="./0_Tension_AlongX_np.log"
    if [[ ! -e $out_log ]]; then
        ene_log_1="1_Tension_AlongX_S1.log"
        ene_log_2="1_Tension_AlongX_S2.log"
        ene_log_3="1_Tension_AlongX_S3.log"
    
        # Create a temporary file to store concatenated content
        temp_file=$(mktemp)
    
        # Function to delete lines before "TCL: Running" in a log file
        delete_lines() {
            awk '/TCL: Running/{p=1}p' "$1"
        }
    
        # Delete lines before "TCL: Running" in each log file and concatenate them
        delete_lines "$ene_log_1" >> "$temp_file"
        delete_lines "$ene_log_2" >> "$temp_file"
        delete_lines "$ene_log_3" >> "$temp_file"
    
        # Move the concatenated content to the output log file
        mv "$temp_file" "$out_log"
    fi

    log_line="Done."
    echo $log_line
    echo $log_line >> ${log_file}
fi
time_2=$SECONDS
echo "used time: $(($time_2-$time_1))" >>  ${log_file}
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
cd ../ 


# 6. Collect the results
time_1=$SECONDS
if [ $IF_Ana_smd -eq 1 ]
then

    cp ../${code_path}/4_analyze_smd.tcl ./

    out_mp4="./collect_results/SMDHist_x_Fn.jpg"
    if [[ ! -e $out_mp4 ]]; then
    	${vmd_commad} -dispdev text -e 4_analyze_smd.tcl
    fi
fi
time_2=$SECONDS
echo "used time: $(($time_2-$time_1))" >>  ${log_file}

# 8. Make a Movie if needed
time_1=$SECONDS
if [ $IF_Make_Movie -eq 1 ]
then

    cp ../${code_path}/5_make_movie.tcl  ./

	log_line="7. Make movie of MD loading ...."
	echo $log_line
    echo $log_line >> ${log_file}
	
    mkdir -p $MD_pict
    # rm test_smd_x.mp4

    ${vmd_commad} -dispdev text -e 5_make_movie.tcl

    out_mp4="./test_smd_x.mp4"
    if [[ ! -e $out_mp4 ]]; then
        ffmpeg -framerate 30 -i ./md_pict/%05d.tga test_smd_x.mp4
    fi

fi
time_2=$SECONDS
echo "used time: $(($time_2-$time_1))" >>  ${log_file}


# 7. collect the results and clean up
time_1=$SECONDS
if [ ! -d "../${resu_path}" ]; then
    mkdir ../${resu_path}
fi
if [ ! -d "../${resu_path}/${MD_eqi_path}" ]; then
    mkdir ../${resu_path}/${MD_eqi_path}
fi
if [ ! -d "../${resu_path}/${MD_smd_path}" ]; then
    mkdir ../${resu_path}/${MD_smd_path}
fi
cp ./${MD_eqi_path}/0_EneMin_NPT_withConstrain.log ../${resu_path}/${MD_eqi_path}/
cp ./${MD_eqi_path}/TestProt_chain_0_after_psf_AlongX_NPT.dcd ../${resu_path}/${MD_eqi_path}/
cp ./${MD_eqi_path}/ContiInfo.dat ../${resu_path}/${MD_eqi_path}/
cp ./${MD_smd_path}/0_Tension_AlongX_np.log ../${resu_path}/${MD_smd_path}/
cp ./${MD_smd_path}/smdout.dcd ../${resu_path}/${MD_smd_path}/
cp -r ./collect_results ../${resu_path}/
cp ./box_dimension.dat ../${resu_path}/
cp ./run_monitor.log ../${resu_path}/
cp ./TestProt_chain_0_after_psf_AlongX.pdb ../${resu_path}/
cp ./TestProt_chain_0_after_psf_AlongX.ref ../${resu_path}/
cp ./TestProt_chain_0_after_psf.psf ../${resu_path}/

cd ../
time_2=$SECONDS
echo "used time: $(($time_2-$time_1))" >>  ${log_file}
echo "Done."

###----------------------------------------------------------------------------------
# module unload namd/2.14
module unload gcc/9.3.0
module unload namd/3.0alpha9

echo
echo "============================ Messages from Goddess ============================"
echo " * Job ended at     : "`date`
echo "==============================================================================="
echo
