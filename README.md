# Scripts for benchmarking Wire-Cell at NERSC

This repository contains NERSC-specific scripts, config files, etc., for running [Wire-Cell](https://github.com/WireCell/wire-cell-toolkit) as part of the LArSoft-based DUNE software stack. The main motivation for this, currently, is to enable performance studies at NERSC of Wire-Cell's DNNROI algorithm (Deep Neural Network Region-Of-Interest finding) on both CPU and GPU hardware. As Wire-Cell's algorithms (and their hardware requirements) continue to evolve, so will this repository.

## Obtaining a baseline performance Figure of Merit (FOM)

The following instructions describe how to run a minimal LArSoft job that calls Wire-Cell after decoding the raw data from the ProtoDUNE Vertical Drift detector.

### Cloning the repository and copying the required file

Clone this repository and copy the TorchScript model directory into the working tree:

``` bash
git clone https://github.com/lbl-neutrino/wire-cell-example.git
cd wire-cell-example
scp -r /global/cfs/cdirs/m5170/ts-model .
```

The current workflow expects the working directory to contain `ts-model`, including files such as `CP49.ts`.

### Running the FOM benchmark

The baseline benchmark is now split across a four-script calling chain:

- `run_lar_for_fom.baseline.submit.sh`: lists the input HDF5 files and submits one Slurm job per input file.
- `run_lar_for_fom.baseline.outer.sh`: the Slurm batch script. It sets the `#SBATCH` resources and starts the container (Shifter, Podman-hpc, or Apptainer) with `srun`.
- `run_lar_for_fom.baseline.middle.sh`: runs inside the container. It sets up DUNE software, configures paths, chooses model/device/run settings, and dispatches one process per Slurm task.
- `run_lar_for_fom.baseline.inner.sh`: runs one `lar` process for one input/model/device/index combination and writes output, log, and timing files.

Submit the full baseline batch workflow from a Perlmutter login node:

``` bash
cd wire-cell-example
./run_lar_for_fom.baseline.submit.sh
```

The submit script currently loops over two ProtoDUNE VD input files and calls.

Each Slurm task launched by the outer script runs the middle script through this `srun` command:

``` bash
srun --no-kill -K0 shifter --module=cvmfs,gpu ./run_lar_for_fom.baseline.middle.sh "$infile"
```

The middle script currently uses the `CP49` model on `cpu`, runs each process 3 times, and processes 18 events per run. Those defaults are controlled by the `models`, `device`, `nruns`, and `nevents` variables in `run_lar_for_fom.baseline.middle.sh`.

So, if you want to submit one input file manually, run:

``` bash
sbatch run_lar_for_fom.baseline.outer.sh /global/cfs/cdirs/m5170/data/fom_inputs/np02vd_raw_run039252_1176_df-s03-d3_dw_0_20250830T054542.hdf5
```

### Extracting the FOM

After the scripts have been run, three new directories should exist: `output`, `logs`, and `timing`. The `timing` directory contains one subdirectory per ProtoDUNE input file. Each process writes a `foo.time` file containing one line per run, with peak CPU usage, peak memory usage, and wall time. This last quantity serves as our FOM.


### Running interactively

For an interactive allocation, obtain a CPU node:

``` bash
salloc -N 1 -q interactive -C cpu -t 240 -A m5170
```

### Entering the container

For an interactive run, enter DUNE's Scientific Linux 7 container. (Eventually we will switch to a modern AlmaLinux 9 container.) For example, using Apptainer:

``` bash
/cvmfs/oasis.opensciencegrid.org/mis/apptainer/current/bin/apptainer shell --nv --shell=/bin/bash -B /cvmfs,/global/cfs,/global/common,/pscratch --ipc --pid /cvmfs/singularity.opensciencegrid.org/fermilab/fnal-dev-sl7:latest
```

Or Shifter:

``` bash
shifter --image=fermilab/fnal-wn-sl7 --module=cvmfs,gpu -- /bin/bash
```

Or podman-hpc:

``` bash
podman-hpc run --rm -it --gpu --nccl-cu12 -v /cvmfs:/cvmfs -v /global/cfs:/global/cfs -v /global/common:/global/common -v /pscratch:/pscratch -v "$PWD":"$PWD" -w "$PWD" docker.io/fermilab/fnal-dev-sl7:latest bash
```

### Running the benchmark

Now simply run the script:

``` bash
./run_lar_for_fom-interactive.baseline.sh && exit   
```
This will run a minimal LArSoft/Wire-Cell workflow on two ProtoDUNE VD files sequentially (one containing 8 GeV/c beam data, the other containing just cosmic rays). Each file is processed 3 times in a row to confirm that there's minimal variance in run time. (This can be changed by altering the nruns variable in the script.)
