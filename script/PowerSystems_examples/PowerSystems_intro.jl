
# # Introduction to [PowerSystems.jl](https://github.com/NREL-SIIP/PowerSystems.jl)
#

# **Originally Contributed by**: Clayton Barrows and Jose Daniel Lara

# ## Introduction

# This notebook is intended to show a power system data specification framework that exploits the
# capabilities of Julia to improve performance and allow modelers to develop modular software
# to create problems with different complexities and enable large scale analysis.
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
# Users of PowerSystems.jl should not need to interact directly with InfrastructureSystems.jl
#
# The examples in this notebook depend upon Julia 1.2 and a specific set of package releases
# as defined in the `Manifest.toml`.
using Pkg
Pkg.status()

using SIIPExamples;
using PowerSystems;
using D3TypeTrees;

# ## Types in PowerSystems
# PowerSystems.jl provides a type hierarchy for specifying power system data. Data that
# describes infrastructure components is held in `struct`s. For example, a `Bus` is defined
# as follows with fields for the parameters required to describe a bus (along with an
# `internal` field used by InfrastructureSystems to improve the efficiency of handling data).

print_struct(Bus)

# ### Type Hierarchy
# PowerSystems is intended to organize data containers by the behavior of the devices that
# the data represents. To that end, a type hierarchy has been defined with several levels of
# abstract types starting with `PowerSystemType`:
# - `Component`: includes all elements of power system data
#   - `PowerSystems.Topology`: includes non physical elements describing network connectivity
#   - `Service`: includes descriptions of system requirements (other than energy balance)
#   - `Device`: includes descriptions of all the physical devices in a power system
# - `PowerSystems.TechnicalParams`: includes structs that hold data describing the technical or economic capabilities of `Device`some
# - `System`: collects all of the `Component`s
#
# *The following trees are made with [D3TypeTrees](https://github.com/claytonpbarrows/D3TypeTrees.jl),
# nodes that represent Structs will show the Fields in the hoverover tooltip.*

# TypeTree(PowerSystemType)

# ### `Forecasts`
# Every `Component` has a `_forecasts::InfrastructureSystems.Forecasts` field (even composite types).
# `Forecasts` are used to hold time series information that describes the temporally dependent
# data of fields within the same struct. For example, the `ThermalStandard._forecasts` field can
# describe other fields in the struct (`available`, `activepower`, `reactivepower`), while
# the `ThermalStandard.tech._forecasts` holds data for `rating` and other `TechThermal` fields.

# `Forecast`s themselves can take the form of the following:
TypeTree(Forecast)

# In each case, the forecast contains fields for `label` and `data` to identify the `Component`
# field that the forecast describes, and the time series `data`. For example:

print_struct(Deterministic)

# Examples of how to create and add forecasts to system can be found in the
# [Add Forecasts Example](../PowerSystems.jl Examples/add_forecasts.ipynb)

# ### System
# The `System` object collects all of the individual components into a single struct along
# with some metadata about the system itself (e.g. `basepower`)

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

bus1 = get_component(Bus, sys, "nodeA")
@show get_name(bus1);
@show get_magnitude(bus1);

# #### Accessing `Forecast`s

# First we need to add some forecasts to the `System`
loads = collect(get_components(PowerLoad, sys))
for (l, ts) in zip(loads, load_timeseries_DA[2])
    add_time_series!(sys, l, Deterministic("activepower", Dict(TimeSeries.timestamp(load_timeseries_DA[2][1])[1] => ts)))
end

# If we want to access a specific forecast for a specific component, we need to specify:
#  - Forecast type
#  - `component`
#  - initial_time
#  - label
#
# We can find the unique set of initial times of all the forecasts in the system:
get_forecast_initial_times(sys)

# We can find the fields for which a component has a forecast:
@show labels = IS.get_time_series_names(Deterministic, loads[1])

# Or for a specific component:
@show initial_times = IS.get_initial_timestamp(get_time_series(Deterministic, loads[1], labels[1]));
