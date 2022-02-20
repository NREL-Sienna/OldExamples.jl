#! format: off

using PowerSystems
using TimeSeries

PowerSystems.download(PowerSystems.TestData; branch = "master")
base_dir = pkgdir(PowerSystems);

sys = System(joinpath(base_dir, "data", "psse_raw", "RTS-GMLC.RAW"));

sys

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
