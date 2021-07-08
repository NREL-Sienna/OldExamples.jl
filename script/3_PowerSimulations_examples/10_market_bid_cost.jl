#jl #! format: off
# # Time-varying bid problems with [PowerSimulations.jl](https://github.com/NREL-SIIP/PowerSimulations.jl)

# **Originally Contributed by**: Sourabh Dalvi

# ## Introduction

# PowerSimulations.jl supports the construction of Operations problems in power system
# with three part cost bids for each time step. MarketBidCost allows the user to pass a
# time-series of variable cost for energy and ancillary services jointly.
# This example shows how to build a Operations problem with MarketBidCost and how to add
# the time-series data to the devices.

# ## Dependencies
# ### Modeling Packages
using SIIPExamples
using PowerSystems
using PowerSimulations
const PSI = PowerSimulations

# ### Data management packages
using PowerSystemCaseBuilder
using Dates
using DataFrames
using TimeSeries

# ### Optimization packages
using Cbc #solver

# ### Data
# This data depends upon the [RTS-GMLC](https://github.com/gridmod/rts-gmlc) dataset that we
# assembled in the [tabular data parsing example](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/3_PowerSimulations_examples/01_operations_problems.ipynb).
include(
    joinpath(SIIPExamples.TEST_DIR, SIIPExamples.PSY_EX_FOLDER, "04_parse_tabulardata.jl"),
)

# ### Creating the Time Series data for Energy bid
MultiDay = collect(
    DateTime("2020-01-01T00:00:00"):Hour(1):(DateTime("2020-01-01T00:00:00") + Hour(8783)),
);

# ### Adding a MarketBidCost time series
# Here we add the energy bid
# time series to the system. The TimeSeriesData that holds the energy bid data can be of any
# type (i.e. `SingleTimeSeries` or `Deterministic`), but it has to be consistent with the existing
# data in the `sys`. So, we'll first remove the existing `DeterministicSingleTimeSeries`, then add
# the bid time series as `SingleTimeSeries`, then re-transform all of the time series in `sys`.

remove_time_series!(sys, DeterministicSingleTimeSeries)

for gen in get_components(ThermalGen, sys)
    varcost = get_operation_cost(gen)
    data = TimeArray(MultiDay, repeat([get_cost(get_variable(varcost))], 8784))
    _time_series = SingleTimeSeries("variable_cost", data)
    add_time_series!(sys, gen, _time_series)
    #set_variable_cost!(sys, gen, _time_series)
end

# ### Transforming SingleTimeSeries into Deterministic
horizon = 24;
interval = Dates.Hour(24);
transform_single_time_series!(sys, horizon, interval)

# In the [OperationsProblem example](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/3_PowerSimulations_examples/01_operations_problems.ipynb)
# we defined a unit-commitment problem with a copper plate representation of the network.
# Here, we want do define unit-commitment problem  with ThermalMultiStartUnitCommitment
# formulation for thermal device representation.

# For now, let's just choose a standard UC formulation.
uc_template = template_unit_commitment(network = CopperPlatePowerModel)

# And adjust the thermal generator formulation to use `ThermalMultiStartUnitCommitment`
set_device_model!(uc_template, ThermalMultiStart, ThermalMultiStartUnitCommitment)

# Now we can build a 4-hour economic dispatch problem with the RTS data.
solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 1, "ratioGap" => 0.5)

problem = OperationsProblem(
    uc_template,
    sys,
    horizon = 4,
    optimizer = solver,
    balance_slack_variables = true,
)
build!(problem, output_dir = mktempdir())

# And solve it ...
solve!(problem)
