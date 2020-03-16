using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath,"test", "PowerSystems_examples", "parse_matpower.jl"))

FORECASTS_DIR = joinpath(base_dir,"forecasts", "5bus_ts")
fname = joinpath(FORECASTS_DIR,"timeseries_pointers_da.json")
open(fname,"r") do f
    for line in eachline(f)
        println(line)
    end
end

ts_pointers = IS.read_time_series_metadata(fname)

add_forecasts!(sys, ts_pointers)
sys

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

