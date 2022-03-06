#jl #! format: off
# # PTDF with [PowerSimulations.jl](https://github.com/NREL-SIIP/PowerSimulations.jl)

# **Originally Contributed by**: Sourabh Dalvi

# ## Introduction

# PowerSimulations.jl supports linear PTDF optimal power flow formulation. This example shows a
# single multi-period optimization of economic dispatch with a linearized DC-OPF representation of
# using PTDF power flow and how to extract duals values or locational marginal prices for energy.

# ## Dependencies
using SIIPExamples
using PowerSystems
using PowerSimulations
using PowerSystemCaseBuilder
using DataFrames

# Since we'll be retrieving duals, we need a solver that returns duals values
# here we use HiGHS.
using HiGHS # mip solver
solver = optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.05)

# We can use the same RTS data and some of the initialization as in
# [OperationsProblem example](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/3_PowerSimulations_examples/01_operations_problems.ipynb)
sys = build_system(PSITestSystems, "modified_RTS_GMLC_DA_sys")

# Here, we want do define an economic dispatch (linear generation decisions) with
# linear DC-OPF using PTDF network representation.
# So, starting with the network, we can select from _almost_ any of the endpoints on this
# tree:
print_tree(PowerSimulations.PM.AbstractPowerModel)


# Calculate the PTDF matrix.
PTDF_matrix = PTDF(sys)

# For now, let's just choose a standard PTDF formulation.
template = template_unit_commitment(network = NetworkModel(StandardPTDFModel, PTDF = PTDF_matrix, duals = [CopperPlateBalanceConstraint], use_slacks = false), use_slacks = true)
for (k,v) in template.branches
    v.duals = [NetworkFlowConstraint]
end

# Now we can build a 4-hour economic dispatch / OPF problem with the RTS data.
# Here, we have to pass the keyword argument `constraint_duals` to OperationsProblem
# with the name of the constraint for which duals are required for them to be returned in the results.
problem = DecisionModel(
    template,
    sys,
    horizon = 24,
    optimizer = solver,
)
build!(problem, output_dir = mktempdir())

# And solve the problem and collect the results
solve!(problem)

# Here we collect the dual values from the results for the `:CopperPlateBalance` and `:network_flow`
# constraints. In the case of PTDF network formulation we need to compute the final LMP for each bus in the system by
# subtracting the duals (μ) of `:network_flow` constraints multiplied by the PTDF matrix
# from the  dual (λ) of `:CopperPlateBalance` constraint.
res = ProblemResults(problem)
duals = read_duals(res, [k for k in list_dual_keys(res) if PSI.get_entry_type(k) == NetworkFlowConstraint])
λ =  read_dual(res, "CopperPlateBalanceConstraint__System")[:,2]
flow_duals = outerjoin(values(duals)..., on = :DateTime,)
μ = Matrix(flow_duals[:, PTDF_matrix.axes[1]])

# Here we calculate LMP as λ + congestion component of the LMP which is a product of μ and the PTDF matrix.
LMP = flow_duals[:,[:DateTime]]
for bus in get_components(Bus, sys)
    LMP[:,get_name(bus)] = λ .+ μ * PTDF_matrix[:, get_number(bus)]
end

# Finally here we have the LMPs
LMP
