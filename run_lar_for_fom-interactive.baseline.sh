#!/usr/bin/env bash

# NOTE: Make sure that the current working directory contains a `ts-model`
# directory with CP49.ts etc. (See /global/cfs/cdirs/m5170/ts-model).
# Otherwise you'll get an error saying "no TorchScript model file provided".

export HDF5_USE_FILE_LOCKING=FALSE

infiles=(
    /global/cfs/cdirs/m5170/data/fom_inputs/np02vd_raw_run039252_1176_df-s03-d3_dw_0_20250830T054542.hdf5
    /global/cfs/cdirs/m5170/data/fom_inputs/np02vd_raw_run039350_2842_df-s04-d2_dw_0_20250911T235510.hdf5
)

# models=(CP49 unet)
## it appears that the unet model doesn't work on CPUs
## ("Legacy model format is not supported on mobile.")
models=(CP49)
device=cpu
nruns=3

source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh
setup dunesw v10_17_00d00 -q e26:prof
export WIRECELL_PATH=$DUNERECO_DIR/wire-cell-cfg/pgrapher/experiment/protodunevd:$WIRECELL_PATH

for infile in "${infiles[@]}"; do
    for model in "${models[@]}"; do
        ./run_lar_for_fom-interactive.sh "$infile" "$model" "$device" "$nruns"
    done
done
