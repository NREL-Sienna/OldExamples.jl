using Pkg
Pkg.status()

using SIIPExamples
using PowerSystems
using TimeSeries

PowerSystems.download(PowerSystems.TestData; branch = "master")
base_dir = dirname(dirname(pathof(PowerSystems)));

sys = System(PowerModelsData(joinpath(base_dir, "data", "psse_raw", "RTS-GMLC.RAW")));

sys

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
