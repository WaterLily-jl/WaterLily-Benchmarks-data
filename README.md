# WaterLily-Benchmarks data

Raw data of [WaterLily-Benchmarks](https://github.com/WaterLily-jl/WaterLily-Benchmarks) studies of [WaterLily.jl](https://github.com/WaterLily-jl/WaterLily.jl) that are reported in issues, PRs or papers, kept so that the results can be checked and re-analysed later.

## Layout

One folder per study, named `<date>_<topic>_<hardware>`:

- `README.md`: what was measured and why, where it was reported, hardware, software versions, the exact commands, and how the files are organised.
- `data/`: the benchmark JSON files exactly as `benchmark.sh` writes them.
- `manifests/`: the resolved Julia `Manifest.toml` of the runs, one per distinct environment. Packages used from a local clone (`Pkg.develop`) have their path replaced by the package name; the study README gives their commits.
- `suite.patch`: the changes made to WaterLily-Benchmarks for the study, if any.
- Data produced outside the suite go in their own folder, together with the script that produced them.

## Re-running the comparison

`compare.jl` reads a study's `data/` folder directly. Use the WaterLily-Benchmarks commit given in the study README to get the same tables, and point `WATERLILY_DIR` to a WaterLily.jl clone so that commits are labelled with their tags and branches:

```sh
git clone https://github.com/WaterLily-jl/WaterLily-Benchmarks
cd WaterLily-Benchmarks
WATERLILY_DIR=<WaterLily.jl clone> julia --project compare.jl --data_dir=<this repo>/<study>/data --speedup_base="CPUx01,master"
```

## Adding a study

Add only the data, the metadata needed to understand it, and the suite patch. Derived results such as tables, figures and analysis scripts belong where the study is reported. Copy the JSON files without renaming them. They are small (about 5 KB each), so plain git is enough.
