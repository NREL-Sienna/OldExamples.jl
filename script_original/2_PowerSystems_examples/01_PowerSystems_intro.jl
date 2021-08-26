
#jl #! format: off
# # Introduction to [PowerSystems.jl](https://github.com/NREL-SIIP/PowerSystems.jl)
#

# **Originally Contributed by**: Clayton Barrows and Jose Daniel Lara

# ## Introduction

# This notebook is intended to show a power system data specification framework that exploits the
# capabilities of Julia to improve performance and allow modelers to develop modular software
# to create problems with different complexities and enable large scale analysis. The
# [PowerSystems documentation](https://nrel-siip.github.io/PowerSystems.jl/stable/) is also
# an excellent resource.
#
# ### Objective
# PowerSystems.jl provides a type specification for bulk power system data.
# The objective is to exploit Julia's integration of dynamic types to enable efficient data
# handling and enable functional dispatch in modeling and analysis applications
# As explained in Julia's documentation:
#
# "Julia’s type system is dynamic, but gains some of the advantages of static type systems
# by making it possible to indicate that certain values are of specific types. This can be
# of great assistance in generating efficient code, but even more significantly, it allows
# method dispatch on the types of function arguments to be deeply integrated with the language."
#
# For more details on Julia types, refer to the [documentation](https://docs.julialang.org/en/v1/)
#
#
# ## Environment and packages
#
# PowerSystems.jl relies on a framework for data handling established in
# [InfrastructureSystems.jl](https://github.com/NREL-SIIP/InfrastructureSystems.jl).
# Users of PowerSystems.jl should not need to interact directly with InfrastructureSystems.jl.
# However, it's worth recognizing that InfrastructureSystems provides much of the back end
# code for managing and accessing data, especially time series data.
#
using SIIPExamples;
using PowerSystems;

# Normally, I'd add the following two lines to configure logging behavior, but something about
# Literate.jl makes this fail, so these examples only work with the default log configuration.
# ```julia
# using Logging
# logger = configure_logging(console_level = Logging.Error, file_level = Logging.Info, filename = "ex.log")
# ````

# ## Types in PowerSystems
# PowerSystems.jl provides a type hierarchy for specifying power system data. Data that
# describes infrastructure components is held in `struct`s. For example, a `Bus` is defined
# as follows with fields for the parameters required to describe a bus (along with an
# `internal` field used by InfrastructureSystems to improve the efficiency of handling data).

print_struct(Bus)

# ### Type Hierarchy
# PowerSystems is intended to organize data containers by the behavior of the devices that
# the data represents. To that end, a type hierarchy has been defined with several levels of
# abstract types starting with `InfrastructureSystemsType`. There are a bunch of subtypes of
# `InfrastructureSystemsType`, but the important ones to know about are:
# - `Component`: includes all elements of power system data
#   - `Topology`: includes non physical elements describing network connectivity
#   - `Service`: includes descriptions of system requirements (other than energy balance)
#   - `Device`: includes descriptions of all the physical devices in a power system
# - `InfrastructureSystems.DeviceParameter`: includes structs that hold data describing the
#  dynamic, or economic capabilities of `Device`.
# - `TimeSeriesData`: Includes all time series types
#   - `Forecast`: includes structs to define time series of forecasted data where multiple
# values can represent each time stamp
#   - `StaticTimeSeries`: includes structs to define time series with a single value for each
# time stamp
# - `System`: collects all of the `Component`s
#
print_tree(PowerSystems.IS.InfrastructureSystemsType)

# ### `TimeSeriesData`
# [_Read the Docs!_](https://nrel-siip.github.io/PowerSystems.jl/stable/modeler_guide/time_series/)
# Every `Component` has a `time_series_container::InfrastructureSystems.TimeSeriesContainer`
# field. `TimeSeriesData` are used to hold time series information that describes the
# temporally dependent data of fields within the same struct. For example, the
# `ThermalStandard.time_series_container` field can
# describe other fields in the struct (`available`, `activepower`, `reactivepower`).

# `TimeSeriesData`s themselves can take the form of the following:
print_tree(TimeSeriesData)

# In each case, the time series contains fields for `scaling_factor_multiplier` and `data`
# to identify the details of  th `Component` field that the time series describes, and the
# time series `data`. For example: we commonly want to use a time series to
# describe the maximum active power capability of a renewable generator. In this case, we
# can create a `SingleTimeSeries` with a `TimeArray` and an accessor function to the
# maximum active power field in the struct describing the generator. In this way, we can
# store a scaling factor time series that will get multiplied by the maximum active power
# rather than the magnitudes of the maximum active power time series.

print_struct(Deterministic)

# Examples of how to create and add time series to system can be found in the
# [Add Time Series Example](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/2_PowerSystems_examples/05_add_forecasts.ipynb)

# ### System
# The `System` object collects all of the individual components into a single struct along
# with some metadata about the system itself (e.g. `base_power`)

print_struct(System)

# ## Basic example
# PowerSystems contains a few basic data files (mostly for testing and demonstration).

BASE_DIR = abspath(joinpath(dirname(Base.find_package("PowerSystems")), ".."))
include(joinpath(BASE_DIR, "test", "data_5bus_pu.jl")) #.jl file containing 5-bus system data
nodes_5 = nodes5() # function to create 5-bus buses

# ### Create a `System`

sys = System(
    100.0,
    nodes_5,
    vcat(thermal_generators5(nodes_5), renewable_generators5(nodes_5)),
    loads5(nodes_5),
    branches5(nodes_5),
)

# ### Accessing `System` Data
# PowerSystems provides functional interfaces to all data. The following examples outline
# the intended approach to accessing data expressed using PowerSystems.

# PowerSystems enforces unique `name` fields between components of a particular concrete type.
# So, in order to retrieve a specific component, the user must specify the type of the component
# along with the name and system

# #### Accessing components
@show get_component(Bus, sys, "nodeA")
@show get_component(Line, sys, "1")

# Similarly, you can access all the components of a particular type: *note: the return type
# of get_components is a `FlattenIteratorWrapper`, so call `collect` to get an `Array`

get_components(Bus, sys) |> collect

# `get_components` also works on abstract types:

get_components(Branch, sys) |> collect

# The fields within a component can be accessed using the `get_*` functions:
# *It's highly recommended that users avoid using the `.` to access fields since we make no
# guarantees on the stability field names and locations. We do however promise to keep the
# accessor functions stable.*

bus1 = get_component(Bus, sys, "nodeA")
@show get_name(bus1);
@show get_magnitude(bus1);

# #### Accessing `TimeSeries`

# First we need to add some time series to the `System`
loads = collect(get_components(PowerLoad, sys))
for (l, ts) in zip(loads, load_timeseries_DA[2])
    add_time_series!(
        sys,
        l,
        Deterministic(
            "activepower",
            Dict(TimeSeries.timestamp(load_timeseries_DA[2][1])[1] => ts),
        ),
    )
end

# If we want to access a specific time series for a specific component, we need to specify:
#  - time series type
#  - `component`
#  - initial_time
#  - label
#
# We can find the initial time of all the time series in the system:
get_forecast_initial_times(sys)

# We can find the names of all time series attached to a component:
ts_names = get_time_series_names(Deterministic, loads[1])

# We can access a specific time series for a specific component:
ta = get_time_series_array(Deterministic, loads[1], ts_names[1])

# Or, we can just get the values of the time series:
ts = get_time_series_values(Deterministic, loads[1], ts_names[1])
