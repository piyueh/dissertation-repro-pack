#! /bin/sh
#
# job.sh
# Copyright (C) 2022 Pi-Yueh Chuang <pychuang@gwu.edu>
#
# Distributed under terms of the BSD 3-Clause license.
#

#SBATCH --job-name="TGV100"
#SBATCH --nodes=1
#SBATCH --gpus=1
#SBATCH --cpus-per-gpu=10
#SBATCH --partition=batch
#SBATCH --exclude dgx1-[000-002,004]
#SBATCH --time=0-04:00:00
#SBATCH --output=slurm-%A_%a.out
#SBATCH --array=1-1%1  # submit this job 6 times but only run 1 at a time


# get the path to this script (method depending on whether using Slurm)
if [ -n "${SLURM_JOB_ID}" ] ; then
    SCRIPTPATH=$(scontrol show job ${SLURM_JOB_ID} | grep -Po "(?<=Command=).*$")
else
    SCRIPTPATH=$(realpath $0)
fi

# get the path to the directory based on where this script is in
export ROOT=$(dirname ${SCRIPTPATH})

# path to the singularity image
export IMAGE=${HOME}/images/petibm-master-hpcx207-cuda102.sif

# get current time (seconds since epich)
export TIME=$(date +"%s")

# create a log file
mkdir -p ${ROOT}/logs
export LOG=${ROOT}/logs/run-${TIME}.log
echo "Current epoch time: ${TIME}" >> ${LOG}
echo "Case folder: ${ROOT}" >> ${LOG}
echo "Job script: ${SCRIPTPATH}" >> ${LOG}
echo "Singularity image: ${IMAGE}" >> ${LOG}
echo "Number of GPUs: ${SLURM_GPUS}" >> ${LOG}
echo "CPUs per GPUs: ${SLURM_CPUS_PER_GPU}" >> ${LOG}
echo "Total allocated CPUs: $((${SLURM_CPUS_PER_GPU}*${SLURM_GPUS}))" >> ${LOG}

echo "" >> ${LOG}
echo "===============================================================" >> ${LOG}
lscpu 2>&1 >> ${LOG}
echo "===============================================================" >> ${LOG}

echo "" >> ${LOG}
echo "===============================================================" >> ${LOG}
nvidia-smi -L 2>&1 >> ${LOG}
echo "===============================================================" >> ${LOG}

# run with gpus
echo "Start the run" >> ${LOG}

# set to physical cores; this cluster has hyperthreading enabled
export _NTASKS=$((${SLURM_CPUS_PER_GPU}/2))
echo "CPU cores used: ${_NTASKS}" >> ${LOG}

mpiexec -n ${_NTASKS} \
    singularity exec --nv ${IMAGE} petibm-navierstokes -directory ${ROOT} \
    2>&1 >> ${LOG}