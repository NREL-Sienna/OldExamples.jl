#! format: off

using SIIPExamples
using PowerSystems
using JSON3

pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath, "test", "2_PowerSystems_examples", "02_parse_matpower.jl"))

FORECASTS_DIR = joinpath(base_dir, "forecasts", "5bus_ts")
fname = joinpath(FORECASTS_DIR, "timeseries_pointers_da.json")
open(fname, "r") do f
    JSON3.@pretty JSON3.read(f)
end

add_time_series!(sys, fname)
sys

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
