#' ---
#' title: Parsing MATPOWER Files
#' ---

#' **Originally Contributed by**: Clayton Barrows

#' ## Introduction

#' An example of how to parse MATPOWER files and create a `System` using [PowerSystems.jl](github.com/NREL/PowerSystems.jl)

#' ### Environemnt
#' This notebook depends on the SIIPExamples.jl environment

using Pkg
Pkg.activate("../../.")


#' ### Dependencies

using PowerSystems
using TimeSeries
const PSY = PowerSystems
const IS = PSY.InfrastructureSystems;

#' ### Fetch Data
#' PowerSystems.jl links to some test data that is suitable for this example. 
#' Let's download the test data
PSY.download(PSY.TestData; branch = "master")
base_dir = dirname(dirname(pathof(PowerSystems)));

#' ### Create a `System`
sys_matpower = PSY.parse_standard_files(joinpath(base_dir, "data/matpower/RTS_GMLC.m"));

sys_matpower





sys_psse = PSY.parse_standard_files(joinpath(base_dir,"data/psse_raw/RTS-GMLC.RAW"));

sys_psse

sys_psse





RTS_GMLC_DIR = joinpath(base_dir,"data/RTS_GMLC");

#parse in tabular data
rawsys = PSY.PowerSystemTableData(RTS_GMLC_DIR,100.0, joinpath(RTS_GMLC_DIR,"user_descriptors.yaml"))

#create an hourly model from tabular data
sys = System(rawsys; forecast_resolution = Dates.Hour(1));

sys





FORECASTS_DIR = joinpath(base_dir,"data/forecasts/")


sys_5 = PSY.parse_standard_files(joinpath(base_dir, "data/matpower", "case5_re.m"))

label_mapping = Dict(("electricload","MW Load") => "maxactivepower",
    ("generator","PMax MW") => "rating")

ts_pointers = IS.read_time_series_metadata(joinpath(FORECASTS_DIR,
                            "5bus_ts","timeseries_pointers_da.json"), label_mapping)

fieldnames(PowerLoad)

add_forecasts!(sys_5, ts_pointers)
sys_5







path, io = mktemp()
@info "Serializing to $path"
to_json(io, sys)
close(io)

filesize(path)/1000000 #MB

sys2 = System(path)








