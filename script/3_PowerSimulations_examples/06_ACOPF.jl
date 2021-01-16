# # ACOPF with [PowerSimulations.jl](https://github.com/NREL-SIIP/PowerSimulations.jl) using [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl)

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# PowerSimulations.jl supports non-linear AC optimal power flow through a deep integration
# with [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl). This example shows a
# single multi-period optimization of economic dispatch with a full representation of
# AC optimal power flow.

# ## Dependencies
# We can use the same RTS data and some of the initialization as in
# [OperationsProblem example](../../notebook/3_PowerSimulations_examples/1_operations_problems.ipynb)
# by sourcing it as a dependency.
using SIIPExamples
using Dates

base_dir = PowerSystems.download(PowerSystems.TestData; branch = "master");
sys = System(joinpath(base_dir, "matpower", "RTS_GMLC.m"))
tsp = joinpath(base_dir, "RTS_GMLC", "timeseries_pointers.json")
add_time_series!(sys, tsp, resolution = Hour(1))
#=
pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(
    pkgpath,
    "test",
    "3_PowerSimulations_examples",
    "01_operations_problems.jl",
));
=#
transform_single_time_series!(sys, 2, Hour(1))

# Since we'll be doing non-linear optimization, we need a solver that supports non-linear
# problems. Ipopt is quite good.
using Ipopt
solver = optimizer_with_attributes(Ipopt.Optimizer)

# In the [OperationsProblem example](../../notebook/3_PowerSimulations_examples/1_operations_problems.ipynb)
# we defined a unit-commitment problem with a copper plate representation of the network.
# Here, we want do define an economic dispatch (linear generation decisions) with an ACOPF
# network representation.
# So, starting with the network, we can select from _almost_ any of the endpoints on this
# tree:
#nb TypeTree(PSI.PM.AbstractPowerModel,  init_expand = 10, scopesep="\n")

# For now, let's just choose a standard ACOPF formulation.
devices = Dict(
        :Generators => DeviceModel(ThermalStandard, ThermalDispatch),
        :Ren => DeviceModel(RenewableDispatch, RenewableFullDispatch),
        :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
        #:HydroROR => DeviceModel(HydroDispatch, HydroDispatchRunOfRiver),
        #:Hydro => DeviceModel(HydroEnergyReservoir, FixedOutput),
        #:RenFx => DeviceModel(RenewableFix, FixedOutput),
    )
ed_template = template_economic_dispatch(network = ACPPowerModel, devices = devices)

# Currently  energy budget data isn't stored in the RTS-GMLC dataset.
#ed_template.devices[:Hydro] = DeviceModel(HydroEnergyReservoir, HydroDispatchRunOfRiver)


# The ACOPF with linear dispatch decisions is infeasible for many of the 8760 time periods.
# The data and baseline commitment pattern is based on a peak load flow case, so it's worth
# selecting a peak period to analyze.

loads = get_components(PowerLoad, sys)
timerange = range(
    get_forecast_initial_timestamp(sys),
    step = get_time_series_resolution(sys),
    stop =  get_forecast_initial_timestamp(sys) + get_forecast_total_period(sys)
    )

load_ts = []
for (ix, load) in enumerate(loads)
    push!(load_ts, get_time_series_values(SingleTimeSeries, load, "max_active_power"))
end
load_ts = Matrix(hcat(load_ts...))
(peak_load, hour_id) = findmax(sum(load_ts, dims = 2))

peak_time = timerange[hour_id,1]


# Now we can build a 4-hour economic dispatch / ACOPF problem with the RTS data.
problem = OperationsProblem(
    EconomicDispatchProblem,
    ed_template,
    sys,
    horizon = 1,
    optimizer = solver,
    balance_slack_variables = false,
    initial_time = peak_time
)

# And solve it ...
solve!(problem)