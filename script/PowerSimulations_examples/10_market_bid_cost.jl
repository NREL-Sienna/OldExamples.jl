# # Operations problems with [PowerSimulations.jl](https://github.com/NREL-SIIP/PowerSimulations.jl)

# **Originally Contributed by**: Sourabh Dalvi

# ## Introduction

# PowerSimulations.jl supports the construction of Operations problems in power system
# with three part cost bids for each time step. MarketBidCost allows the user to pass a 
# time-series of variable cost for energy and ancillary services jointly.
# This example shows how to build a Operations problem with MarketBidCost and how to add 
# the time-series data to the devices. 

# ## Dependencies
using SIIPExamples

# ### Modeling Packages
using PowerSystems
using PowerSimulations
const PSI = PowerSimulations
using D3TypeTrees

# ### Data management packages
using Dates
using DataFrames
using TimeSeries

# ### Optimization packages
using JuMP
using Cbc #solver

# ### Data
# This data depends upon the [RTS-GMLC](https://github.com/gridmod/rts-gmlc) dataset. Let's
# download and extract the data.

rts_dir = SIIPExamples.download("https://github.com/GridMod/RTS-GMLC")
rts_src_dir = joinpath(rts_dir, "RTS_Data", "SourceData")
rts_siip_dir = joinpath(rts_dir, "RTS_Data", "FormattedData", "SIIP");

# ### Create a `System` from RTS-GMLC data just like we did in the [parsing tabular data example.](../../notebook/PowerSystems_examples/parse_tabulardata.jl)
rawsys = PowerSystems.PowerSystemTableData(
    rts_src_dir,
    100.0,
    joinpath(rts_siip_dir, "user_descriptors.yaml"),
    timeseries_metadata_file = joinpath(rts_siip_dir, "timeseries_pointers.json"),
    generator_mapping_file = joinpath(rts_siip_dir, "generator_mapping.yaml"),
);
sys = System(rawsys; time_series_resolution = Dates.Hour(1));

# ### Creating the Time Series data for Energy bid
MultiDay = collect(
    DateTime("2020-01-01T00:00:00"):Hour(1):(DateTime("2020-01-01T00:00:00") + Hour(8783)),
);

# ### Replacing existing ThreePartCost with MarketBidCost
# Here we replace the existing ThreePartCost with MarketBidCost, and add the energy bid 
# time series to the system. The TimeSeriesData that holds the energy bid data can be of any 
# type (i.e. `SingleTimeSeries` or `Deterministic`) and bid data should be of type 
# `Array{Float64}`,`Array{Tuple{Float64, Float64}}` or `Array{Array{Tuple{Float64,Float64}}`. 

for gen in get_components(ThermalGen, sys)
    varcost = get_operation_cost(gen)
    market_bid_cost = MarketBidCost(;
        variable = nothing,
        no_load = get_fixed(varcost),
        start_up = (hot = get_start_up(varcost), warm = 0.0, cold = 0.0),
        shut_down = get_shut_down(varcost),
        ancillary_services = Vector{Service}(),
    )
    set_operation_cost!(gen, market_bid_cost)

    data = TimeArray(MultiDay, repeat([get_cost(get_variable(varcost))], 8784))
    _time_series = SingleTimeSeries("variable_cost", data)
    set_variable_cost!(sys, gen, _time_series)
end

# ### Transforming SingleTimeSeries into Deterministic 
horizon = 24;
interval = Dates.Hour(24);
transform_single_time_series!(sys, horizon, interval)

# In the [OperationsProblem example](../../notebook/PowerSimulations_examples/1_operations_problems.ipynb)
# we defined a unit-commitment problem with a copper plate representation of the network.
# Here, we want do define unit-commitment problem  with ThermalMultiStartUnitCommitment
# formulation for thermal device representation.

# For now, let's just choose a standard ACOPF formulation.
uc_template = template_unit_commitment(network = CopperPlatePowerModel)

# Currently  energy budget data isn't stored in the RTS-GMLC dataset.
uc_template.devices[:Generators] =
    DeviceModel(ThermalStandard, ThermalMultiStartUnitCommitment)

solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 1, "ratioGap" => 0.5)

# Now we can build a 4-hour economic dispatch / ACOPF problem with the RTS data.
problem = OperationsProblem(
    EconomicDispatchProblem,
    uc_template,
    sys,
    horizon = 4,
    optimizer = solver,
    balance_slack_variables = true,
)

# And solve it ...
solve!(problem)
