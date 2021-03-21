# # ACOPF with [PowerSimulations.jl](https://github.com/NREL-SIIP/PowerSimulations.jl) using [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl)

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# PowerSimulations.jl supports non-linear AC optimal power flow through a deep integration
# with [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl). This example shows a
# single multi-period optimization of economic dispatch with a full representation of
# AC optimal power flow.

# ## Dependencies
using SIIPExamples
using PowerSystems
using PowerSimulations
using PowerSystemCaseBuilder

# We can use the a [TAMU synthetic ERCOT dataset](https://electricgrids.engr.tamu.edu/electric-grid-test-cases/).
# The TAMU data format relies on a folder containing `.m` or `.raw` files and `.csv`
# files for the time series data. We have provided a parser for the TAMU data format with
# the `TamuSystem()` function. A version of the system with only one week of time series
# is included in PowerSystemCaseBuilder.jl, we can use that version here:
sys = build_system(PSYTestSystems, "tamu_ACTIVSg2000_sys")
transform_single_time_series!(sys, 2, Hour(1))

# Since we'll be doing non-linear optimization, we need a solver that supports non-linear
# problems. Ipopt is quite good.
using Ipopt
solver = optimizer_with_attributes(Ipopt.Optimizer)

# In the [OperationsProblem example](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/3_PowerSimulations_examples/01_operations_problems.ipynb)
# we defined a unit-commitment problem with a copper plate representation of the network.
# Here, we want do define an economic dispatch (linear generation decisions) with an ACOPF
# network representation.
# So, starting with the network, we can select from _almost_ any of the endpoints on this
# tree:
print_tree(PowerSimulations.PM.AbstractPowerModel)

# For now, let's just choose a standard ACOPF formulation.
ed_template = OperationsProblemTemplate(QCLSPowerModel)
set_device_model!(ed_template, ThermalStandard, ThermalDispatch)
set_device_model!(ed_template, PowerLoad, StaticPowerLoad)
#set_device_model!(ed_template, FixedAdmittance, StaticPowerLoad) #TODO add constructor for shunts in PSI

# Now we can build a 4-hour economic dispatch / ACOPF problem with the TAMU data.
problem = OperationsProblem(
    ed_template,
    sys,
    horizon = 1,
    optimizer = solver,
    balance_slack_variables = true,
)
build!(problem, output_dir = mktempdir())

# And solve it ... (it's infeasible)
solve!(problem)
