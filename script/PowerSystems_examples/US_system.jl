# # Creating a `System` representing the entire U.S.

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# This example demonstrates how to assemble a `System` representing the entire U.S. using
# [PowerSystems.jl](https://github.com/NREL-SIIP/powersystems.jl) and the data assembled by
# [Xu, et. al.](https://arxiv.org/abs/2002.06155). We'll use the same tabular data parsing
# capability [demonstrated on the RTS-GMLC dataset](../../notebook/PowerSystems_examples/parse_tabulardata.ipynb).

# ### Environment
# This notebook depends on the SIIPExamples.jl environment which is loaded by default

#nb using Pkg
#nb Pkg.status()

# ### Dependencies
using SIIPExamples
using PowerSystems
using TimeSeries
using Dates
using DataFrames
using CSV

# ### Fetch Data
# PowerSystems.jl links to some test data that is suitable for this example.
# Let's download the test data
@info "downloading data..."
datadir = joinpath(dirname(dirname(pathof(SIIPExamples))), "US-System")
siip_data = joinpath(datadir, "SIIP")
if !isdir(datadir)
    mkdir(datadir)
    mkdir(siip_data)
    tempfilename = download("https://zenodo.org/record/3735409/files/USATestSystem.zip?download=1")
    SIIPExamples.unzip(SIIPExamples.os, tempfilename, datadir)
end

config_dir = joinpath(
    dirname(dirname(pathof(SIIPExamples))),
    "script",
    "PowerSystems_examples",
    "US_config",
)

# ### Data Formatting
# This is a big dataset. Typically one would only want to include one of the interconnects
# available. Lets use Texas to start. You can set `interconnect = nothing` if you want everything.
interconnect = "Texas"

# There are a few minor incompatibilities between the data and the supported tabular data
# format. We can resolve those here.
#
# First, PowerSystems.jl only supports parsing piecewise linear generator costs from tabular
# data. So, we can sample the quadratic polynomial cost curves and provide PWL points.
@info "formatting data ..."
!isnothing(interconnect) && @info "filtering data to include $interconnect ..."
gen = DataFrame(CSV.read(joinpath(datadir, "plant.csv")))
filter!(row -> row[:interconnect] == interconnect, gen)
gencost = CSV.read(joinpath(datadir, "gencost.csv"))
gen = join(gen, gencost, on = :plant_id, makeunique = true)

function make_pwl(gen::DataFrame, traunches = 2)
    output_pct_cols = ["output_percent_" * string(i) for i in 0:traunches]
    hr_cols = ["heat_rate_incr_" * string(i) for i in 1:traunches]
    pushfirst!(hr_cols, "heat_rate_avg_0")
    pwl = DataFrame(repeat([Float64], 6), Symbol.(vcat(output_pct_cols, hr_cols)))
    for row in eachrow(gen)
        traunch_len = (1.0 - row.Pmin / row.Pmax) / traunches
        pct = [row.Pmin / row.Pmax + i * traunch_len for i in 0:traunches]
        c(pct) = pct * row.Pmax * (row.GenIOB + row.GenIOC^2 + row.GenIOD^3)
        hr = [c(pct[1])]
        [push!(hr, c(pct[i + 1]) - hr[i]) for i in 1:traunches]
        push!(pwl, vcat(pct, hr))
    end
    return hcat(gen, pwl)
end

gen = make_pwl(gen)

# There are some incomplete aspects of this dataset. Here, I've assigned some approximate
# minimum up/down times, ramp rates, and some minor adjustments to categories. There are better
# and more efficient ways to do this, but this works for this script...
gen[:, :unit_type] .= "OT"
gen[:, :min_up_time] .= 0.0
gen[:, :min_down_time] .= 0.0
[gen[gen.type .== "wind", col] .= ["Wind", 0.0, 0.0][ix] for (ix, col) in enumerate([:unit_type, :min_up_time, :min_down_time])]
[gen[gen.type .== "solar", col] .= ["PV", 0.0, 0.0][ix] for (ix, col) in enumerate([:unit_type, :min_up_time, :min_down_time])]
[gen[gen.type .== "hydro", col] .= ["HY", 0.0, 0.0][ix] for (ix, col) in enumerate([:unit_type, :min_up_time, :min_down_time])]
[gen[gen.type .== "ng", col] .= [4.5, 8, 5][ix] for (ix, col) in enumerate([:min_up_time, :min_down_time, :ramp_30])]
[gen[gen.type .== "coal", col] .= [24, 48, 4][ix] for (ix, col) in enumerate([:min_up_time, :min_down_time, :ramp_30])]
[gen[gen.type .== "nuclear", col] .= [72, 72, 2][ix] for (ix, col) in enumerate([:min_up_time, :min_down_time, :ramp_30])]

gen[:, :name] = "gen" .* string.(gen.plant_id)
CSV.write(joinpath(siip_data, "gen.csv"), gen)

# Let's also merge the zone.csv with the bus.csv and identify bus types
bus = DataFrame(CSV.read(joinpath(datadir, "bus.csv")))
!isnothing(interconnect) && filter!(row -> row[:interconnect] == interconnect, bus)
zone = CSV.read(joinpath(datadir, "zone.csv"))
bus = join(bus, zone, on = :zone_id, kind = :left)
int2bustype(b) = replace(split(string(PowerSystems.BusTypes.BusType(b)), ".")[end], "]" => "")
bus.bustype = int2bustype.(bus.type)
bus.name = "bus" .* string.(bus.bus_id)
CSV.write(joinpath(siip_data, "bus.csv"), bus)

# We need branch names as strings
branch = DataFrame(CSV.read(joinpath(datadir, "branch.csv")))
!isnothing(interconnect) && filter!(row -> row[:interconnect] == interconnect, branch)
branch.name = "branch" .* string.(branch.branch_id)
branch.ratio = Float64.(branch.ratio)
CSV.write(joinpath(siip_data, "branch.csv"), branch)

# The PowerSystems parser expects the files to be named a certain way.
# And, we need a "control_mode" column in dc-line data
dcbranch = DataFrame(CSV.read(joinpath(datadir, "dcline.csv")))
!isnothing(interconnect) && filter!(row -> row[:from_bus_id] in bus.bus_id, dcbranch)
!isnothing(interconnect) && filter!(row -> row[:to_bus_id] in bus.bus_id, dcbranch)
dcbranch.name = "dcbranch" .* string.(dcbranch.dcline_id)
dcbranch[:, :control_mode] .= "Power"
CSV.write(joinpath(siip_data, "dc_branch.csv"), dcbranch)

# ### We need to create a reference for where to get timeseries data for each component.
timeseries = []
ts_csv = ["wind", "solar", "hydro", "demand"]
plant_ids = Symbol.(string.(gen.plant_id))
for f in ts_csv
    @info "formatting $f.csv ..."
    csvpath = joinpath(siip_data, f * ".csv")
    csv = DataFrame(CSV.read(joinpath(datadir, f * ".csv")))
    (category, name_prefix, label) =
        f == "demand" ? ("Area", "", "get_maxactivepower") :
        ("Generator", "gen", "get_rating")
    if !(:DateTime in names(csv))
        DataFrames.rename!(
            csv,
            (names(csv)[occursin.("UTC", String.(names(csv)))][1] => :DateTime),
        )
        csv.DateTime = replace.(csv.DateTime, " " => "T")
    end
    device_names = f == "demand" ? unique(bus.zone_name) : gen.name
    for id in names(csv)
        colname = id
        if f == "demand"
            if id in Symbol.(zone.zone_id)
                colname = Symbol(zone[Symbol.(zone.zone_id) .== id, :zone_name][1])
                DataFrames.rename!(csv, (id => colname))
            end
        else
            if id in plant_ids
                colname = Symbol(gen[Symbol.(gen.plant_id) .== id, :name][1])
                DataFrames.rename!(csv, (id => colname))
            end
        end
        if String(colname) in device_names
            sf = maximum(csv[:, colname]) == 0.0 ? 1.0 : "Max"
            push!(timeseries, Dict(
                "simulation" => "DA",
                "category" => category,
                "component_name" =>String(colname),
                "label" => label,
                "scaling_factor" => sf,
                "data_file" => csvpath))
        end
    end
    CSV.write(csvpath, csv)
end

timeseries_pointers = joinpath(siip_data, "timeseries_pointers.json")
open(timeseries_pointers, "w") do io
    PowerSystems.InfrastructureSystems.JSON2.write(io, timeseries)
end

# ### The tabular data format relies on a folder containing `*.csv` files and `.yaml` files
# describing the column names of each file in PowerSystems terms, and the PowerSystems
# data type that should be created for each generator type. The respective "us_decriptors.yaml"
# and "US_generator_mapping.yaml" files have already been tailored to this dataset.
@info "parsing csv files..."
rawsys = PowerSystems.PowerSystemTableData(
    siip_data,
    100.0,
    joinpath(config_dir, "us_descriptors.yaml"),
    generator_mapping_file = joinpath(config_dir, "US_generator_mapping.yaml"),
)

# ### Create a `System`
# Next, we'll create a `System` from the `rawsys` data. Since a `System` is predicated on a
# forecast resolution and the `rawsys` data includes both 5-minute and 1-hour resolution
# forecasts, we also need to specify which forecasts we want to include in the `System`.
# The `forecast_resolution` kwarg filters to only include forecasts with a matching resolution.

@info "creating System"
sys = System(rawsys; configpath = joinpath(config_dir, "us_system_validation.json"));
sys

# This all took reasonably long, so we can save our `System` using the serialization
# capability included with PowerSystems.jl:
@info "serializing System"
io = open(joinpath(siip_data, "sys.json"), "w")
to_json(io, sys)
close(io)