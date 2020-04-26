using SIIPExamples
using PowerSystems
using TimeSeries
using Dates
const PSY = PowerSystems
const IS = PSY.InfrastructureSystems;

PSY.download(PSY.TestData; branch = "master") # *note* add `force=true` to get a fresh copy
base_dir = dirname(dirname(pathof(PowerSystems)));

RTS_GMLC_DIR = joinpath(base_dir, "data", "RTS_GMLC");
rawsys = PSY.PowerSystemTableData(
    RTS_GMLC_DIR,
    100.0,
    joinpath(RTS_GMLC_DIR, "user_descriptors.yaml"),
    timeseries_metadata_file = joinpath(RTS_GMLC_DIR, "timeseries_pointers.json"),
    generator_mapping_file = joinpath(RTS_GMLC_DIR, "generator_mapping.yaml"),
)

sys = System(rawsys; forecast_resolution = Dates.Hour(1));
sys

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
