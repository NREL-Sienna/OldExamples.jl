# # PTDF with [PowerSimulations.jl](https://github.com/NREL-SIIP/PowerSimulations.jl)

# **Originally Contributed by**: Sourabh Dalvi

# ## Introduction

# PowerSimulations.jl supports linear PTDF optimal power flow formulation. This example shows a
# single multi-period optimization of economic dispatch with a linearilzed DC-OPF representation of
# using PTDF power flow and how to extract duals values or locational marginal prices for energy.

# ## Dependencies
# We can use the same RTS data and some of the initialization as in
# [OperationsProblem example](../../notebook/3_PowerSimulations_examples/1_operations_problems.ipynb)
# by sourcing it as a dependency.
using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(
    joinpath(pkgpath, "test", "3_PowerSimulations_examples", "01_operations_problems.jl"),
);

# Since we'll be retreving duals, we need a solver that returns duals values
# here we use Ipopt.
using Ipopt
solver = optimizer_with_attributes(Ipopt.Optimizer)

# In the [OperationsProblem example](../../notebook/3_PowerSimulations_examples/1_operations_problems.ipynb)
# we defined a unit-commitment problem with a copper plate representation of the network.
# Here, we want do define an economic dispatch (linear generation decisions) with
# linear DC-OPF using PTDF network representation.
# So, starting with the network, we can select from _almost_ any of the endpoints on this
# tree:
#nb TypeTree(PSI.PM.AbstractPowerModel,  init_expand = 10, scopesep="\n")

# For now, let's just choose a standard PTDF formulation.
ed_template = template_economic_dispatch(network = StandardPTDFModel)

# Currently  energy budget data isn't stored in the RTS-GMLC dataset.
ed_template.devices[:Hydro] = DeviceModel(HydroEnergyReservoir, HydroDispatchRunOfRiver)

# Calculate the PTDF matrix.
PTDF_matrix = PTDF(sys)

# Now we can build a 4-hour economic dispatch / PTDF problem with the RTS data.
# Here, we have to pass the keyword argument `constraint_duals` to OperationsProblem
# with the name of the constraint for which duals are required for them to be returned in the results.
problem = OperationsProblem(
    EconomicDispatchProblem,
    ed_template,
    sys,
    horizon = 4,
    optimizer = solver,
    balance_slack_variables = true,
    constraint_duals = [:CopperPlateBalance, :network_flow],
    PTDF = PTDF_matrix,
)

# And solve the problem and collect the results
res = solve!(problem)

# Here we collect the dual values from the results for the `CopperPlateBalance` and `network_flow`
# constraints. In the case of PTDF network formulation we need to compute the final LMP for each bus in the system by
# subtracting the duals (μ) of `network_flow` constraint multipled by the PTDF matrix
# from the  dual (λ) of `CopperPlateBalance` constraint.
# Note:we convert the results from DataFrame to Array for ease of use.
λ = convert(Array, res.dual_values[:CopperPlateBalance])
μ = convert(Array, res.dual_values[:network_flow])

# Here we create Dict to store the calculate congestion component of the LMP which is a product of μ and the PTDF matrix.
buses = get_components(Bus, sys)
congestion_lmp = Dict()
for bus in buses
    congestion_lmp[get_name(bus)] = μ * PTDF_matrix[:, get_number(bus)]
end
congestion_lmp = DataFrame(congestion_lmp)

# Finally here we get the LMP for each node in a lossless DC-OPF using the PTDF formulation.
LMP = λ .- congestion_lmp
