#jl #! format: off
# # Add time series to `System`

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# An example of how to parse add time series data to a `System` using [PowerSystems.jl](github.com/NREL-SIIP/PowerSystems.jl)
#
# For example, a `System` created by [parsing a MATPOWER file](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/2_PowerSystems_examples/parse_matpower.ipynb)
# doesn't contain any time series data. So a user may want to add time series to the `System`
# ### Dependencies
# Let's use the 5-bus dataset we parsed in the MATPOWER example
using SIIPExamples
using PowerSystems
using JSON3

pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath, "test", "2_PowerSystems_examples", "02_parse_matpower.jl"))

# ### Define pointers to time series files
# For example, if we want to add a bunch of time series files, say one for each load and
# one for each renewable generator, we need to define pointers to each .csv file containing
# the time series in the following format (PowerSystems.jl also supports a CSV format for this file)

FORECASTS_DIR = joinpath(base_dir, "forecasts", "5bus_ts")
fname = joinpath(FORECASTS_DIR, "timeseries_pointers_da.json")
open(fname, "r") do f
    JSON3.@pretty JSON3.read(f)
end

# ### Read and assign time series to `System` using these parameters.
add_time_series!(sys, fname)
sys
