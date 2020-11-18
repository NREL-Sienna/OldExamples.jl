# # ACOPF with [PowerSimulations.jl](https://github.com/NREL-SIIP/PowerSimulations.jl) using [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl)

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# PowerSimulations.jl supports non-linear AC optimal power flow through a deep integration
# with [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl). This example shows a
# single multi-period optimization of economic dispatch with a full representation of
# AC optimal power flow.

# ## Dependencies
# We can use the same RTS data and some of the initialization as in
# [OperationsProblem example](../../notebook/PowerSimulations_examples/1_operations_problems.ipynb)
# by sourcing it as a dependency.
using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath, "test", "PowerSimulations_examples", "1_operations_problems.jl"));

# Since we'll be doing non-linear optimization, we need a solver that supports non-linear
# problems. Ipopt is quite good.
using Ipopt
solver = optimizer_with_attributes(Ipopt.Optimizer)

# In the [OperationsProblem example](../../notebook/PowerSimulations_examples/1_operations_problems.ipynb)
# we defined a unit-commitment problem with a copper plate representation of the network.
# Here, we want do define an economic dispatch (linear generation decisions) with an ACOPF
# network representation.
# So, starting with the network, we can select from _almost_ any of the endpoints on this
# tree:
#nb TypeTree(PSI.PM.AbstractPowerModel,  init_expand = 10, scopesep="\n")

# For now, let's just choose a standard ACOPF formulation.
ed_template = template_economic_dispatch(network = ACPPowerModel)

# Currently  energy budget data isn't stored in the RTS-GMLC dataset. 
ed_template.devices[:Hydro] = DeviceModel(HydroEnergyReservoir, HydroDispatchRunOfRiver)

# Now we can build a 4-hour economic dispatch / ACOPF problem with the RTS data.
problem = OperationsProblem(
    EconomicDispatchProblem,
    ed_template,
    sys,
    horizon = 4,
    optimizer = solver,
    balance_slack_variables = true,
)

# And solve it ...
solve!(problem)
