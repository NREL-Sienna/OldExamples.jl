using PowerSystems
using TimeSeries
using Dates

PowerSystems.download(PowerSystems.TestData; branch = "master") # *note* add `force=true` to get a fresh copy
base_dir = dirname(dirname(pathof(PowerSystems)));

RTS_GMLC_DIR = joinpath(base_dir, "data", "RTS_GMLC");
rawsys = PowerSystems.PowerSystemTableData(
    RTS_GMLC_DIR,
    100.0,
    joinpath(RTS_GMLC_DIR, "user_descriptors.yaml"),
    timeseries_metadata_file = joinpath(RTS_GMLC_DIR, "timeseries_pointers.json"),
    generator_mapping_file = joinpath(RTS_GMLC_DIR, "generator_mapping_multi_start.yaml"),
)

sys = System(rawsys; time_series_resolution = Dates.Hour(1));
horizon = 24;
interval = Dates.Hour(24);
transform_single_time_series!(sys, horizon, interval);
sys

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
