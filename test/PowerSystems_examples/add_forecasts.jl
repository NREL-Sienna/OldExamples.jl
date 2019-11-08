
using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath,"test/PowerSystems_examples/parse_matpower.jl"))


FORECASTS_DIR = joinpath(base_dir,"data/forecasts/5bus_ts")
fname = joinpath(FORECASTS_DIR,"timeseries_pointers_da.json")
open(fname,"r") do f
    for line in eachline(f)
        println(line)
    end
end


label_mapping = Dict(("electricload","MW Load") => "maxactivepower",
    ("generator","PMax MW") => "rating")


ts_pointers = IS.read_time_series_metadata(fname, label_mapping)


add_forecasts!(sys, ts_pointers)
sys

