#!/bin/bash
#
# DART software - Copyright UCAR. This open source software is provided
# by UCAR, "as is", without charge, subject to all terms of use at
# http://www.image.ucar.edu/DAReS/DART/DART_download
#
# DART $Id: launch_cf.sh 13192 2019-07-11 21:56:56Z raeder@ucar.edu $


# for command file jobs.
# Sidd Ghosh Feb 22, 2017
# Slurm added by Kevin Raeder July 6, 2019

if [[ -v PBS_O_WORKDIR ]]; then
#    echo "launch_cf.sh under PBS"
   line=$(expr $PMI_RANK + 1)
elif [[ -v SLURM_SUBMIT_DIR ]]; then
#    echo "launch_cf.sh under slurm"
   line=$(expr $OMPI_COMM_WORLD_RANK + 1)
else
   echo "Batch environment is unknown"
fi

INSTANCE=$(sed -n ${line}p $1)

# The following command showed that 563 tasks are launched within .3 seconds.
# echo "launching $INSTANCE at "; date --rfc-3339=ns

eval "$INSTANCE"
# KDR Maybe not needed anymore, nor when all commands take significant time.
# sleep 1
# echo "   Done with $INSTANCE at "; date --rfc-3339=ns

# <next few lines under version control, do not edit>
# $URL: https://svn-dares-dart.cgd.ucar.edu/DART/branches/reanalysis/models/cam-fv/shell_scripts/cesm2_1/launch_cf.sh $
# $Revision: 13192 $
# $Date: 2019-07-11 15:56:56 -0600 (Thu, 11 Jul 2019) $