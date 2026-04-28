#!/usr/bin/env bash

infile=$1; shift
model=$1; shift
device=$1; shift
nruns=${1:-1}; shift

fhicl=reco_pdvd_tpcsigproc_dnnroi_${model}_${device}.fcl

mkdir -p output logs timing
outfile=output/$(basename "$infile" .hdf5).$model.$device.RECO.root
logfile=logs/$(basename "$infile" .hdf5).$model.$device.log
timefile=timing/$(basename "$infile" .hdf5).$model.$device.time

for _ in $(seq $nruns); do
    rm -f "$outfile"
    /usr/bin/time -f "%P %M %E" -a -o "$timefile" \
        lar -c "$fhicl" "$infile" -o "$outfile" 2>&1 | tee -a "$logfile"
done
