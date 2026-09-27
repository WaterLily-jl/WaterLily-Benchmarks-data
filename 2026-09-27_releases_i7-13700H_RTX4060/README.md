# WaterLily releases v1.6.1, v1.7.0, v1.8.0 and master

Benchmarks of four WaterLily versions on the WaterLily-Benchmarks cases `tgv`, `sphere` and `jelly`, and the kinetic energy and dissipation of the Taylor-Green vortex at Re=1600 for the same versions. Measured on 2026-09-27. Reported in [WaterLily.jl#335](https://github.com/WaterLily-jl/WaterLily.jl/issues/335).

## Hardware and software

- Laptop with an Intel i7-13700H (6 performance and 8 efficiency cores) and an NVIDIA RTX 4060 Laptop GPU (8 GB, driver 615.71.09), Arch Linux, Julia 1.11.5.

| Label | WaterLily commit | BiotSavartBCs commit |
|---|---|---|
| v1.6.1 | 29f9f43 | d405017 |
| v1.7.0 | de13bc8 | 6ffe945 (`main`) |
| v1.8.0 | 2a2b2ba | 6ffe945 (`main`) |
| master | 2478147 | 6ffe945 (`main`) |

BiotSavartBCs `main` requires WaterLily 1.7, so v1.6.1 used d405017, the last commit before that requirement. BiotSavartBCs is only used by `jelly`. Both packages were used from local clones at these commits, which the manifests list as `path = "WaterLily.jl"` and `path = "BiotSavartBCs.jl"`.

## Benchmarks (`data/`, `manifests/`, `suite.patch`)

Cases `tgv` (`log2p=6,7`), `sphere` (`log2p=3,4`) and `jelly` (`log2p=5,6`), Float32, developed-flow checkpoints, 5 runs of 25 steps per process, 3 repetitions in separate processes, backends CPUx01, CPUx04 and GPU. The suite was WaterLily-Benchmarks `main` at 0703e67 with the changes in `suite.patch`:

```sh
WATERLILY_DIR=<WaterLily.jl clone> sh benchmark.sh -w "v1.6.1 v1.7.0 v1.8.0 master" -bs "d405017 main main main" -bsd <BiotSavartBCs clone> \
    -v "1.11.5" -b "Array CuArray" -t "1 4" -u true -r 3 -c "tgv jelly" -dd data_releases
# same again with -c sphere
```

- `suite.patch`: versions before 1.8 do not accept the `u0` keyword, so the `tgv` case passes its initial condition as `uλ` for them. The extra line in `benchmark.sh` only copies each run's resolved manifest.
- `data/arch_<commit>/`: the 108 JSON files, named `<case>_<sizes>_<steps>_<type>_<backend>_<commit>_<julia>_r<repetition>.json` (`arch` is the host name).
- `manifests/`: one manifest per WaterLily version; the 18 runs of each version resolved identical manifests. Every run used KernelAbstractions 0.9.42, CUDA.jl 6.3.1 and GPUArrays 11.5.14.

The reported tables come from `compare.jl` at WaterLily-Benchmarks `main` d61523b, which takes the reference time from the mean step of each run:

```sh
julia --project compare.jl --data_dir=data --speedup_base="CPUx01,master"
```

## TGV kinetic energy and dissipation (`tgv_accuracy/`)

Same setup as the CPC 2024 validation (`jl/validation/tgv.jl` in [WaterLily.jl_CPC_2024](https://github.com/WaterLily-jl/WaterLily.jl_CPC_2024)): Re=1600, 128³ (`log2p=7`), Float64 on the GPU, up to t=20. The DNS reference of Dairay et al. (2017) is `jl/validation/data/tgv/TGV_Re1600.dat` in that repository.

- `tgv_run.jl`: runs one version and writes `data/tgv_p7_<label>.jld2`, with `julia +1.11.5 --project=<environment> tgv_run.jl <label> 7`. The environment has WaterLily from a local clone at the commit above, CUDA.jl 6.4.0 and JLD2 0.6.7.
- `data/tgv_p7_<label>.jld2`: one file per version, with the time series `E` (kinetic energy per cell), `Z` (dissipation, ν L Σ|ω|² / cells) and `t` (convective time, `t π/L`), one entry per time step, plus `p`, `label`, `commit`, `version` and `walltime` (seconds).
