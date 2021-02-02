# # ACOPF with [PowerSimulations.jl](https://github.com/NREL-SIIP/PowerSimulations.jl) using [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl)

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# PowerSimulations.jl supports non-linear AC optimal power flow through a deep integration
# with [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl). This example shows a
# single multi-period optimization of economic dispatch with a full representation of
# AC optimal power flow.

# ## Dependencies
# We can use the a TAMU synthetic ERCOT dataset that is included in the PowerSystemsTestData.
using SIIPExamples
using PowerSystems
using PowerSimulations
using Dates

pkgpath = pkgdir(SIIPExamples)
PowerSystems.download(PowerSystems.TestData; branch = "master") # *note* add `force=true` to get a fresh copy
base_dir = pkgdir(PowerSystems);

# The TAMU data format relies on a folder containing `.m` or `.raw` files and `.csv`
# files for the time series data. We have provided a parser for the TAMU data format with
# the `TamuSystem()` function.

TAMU_DIR = joinpath(base_dir, "data", "ACTIVSg2000");
sys = TamuSystem(TAMU_DIR)
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
        :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
        :QLoads => DeviceModel(FixedAdmittance, StaticPowerLoad)
    )
ed_template = template_economic_dispatch(network = ACPPowerModel, devices = devices)

# Now we can build a 4-hour economic dispatch / ACOPF problem with the TAMU data.
problem = OperationsProblem(
    EconomicDispatchProblem,
    ed_template,
    sys,
    horizon = 1,
    optimizer = solver,
    balance_slack_variables = true,
)

# And solve it ...
solve!(problem)