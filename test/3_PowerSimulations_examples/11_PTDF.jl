#! format: off

using SIIPExamples
using PowerSystems
using PowerSimulations
const PSI = PowerSimulations
using PowerSystemCaseBuilder
using DataFrames

using HiGHS # mip solver
solver = optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.05)

sys = build_system(PSITestSystems, "modified_RTS_GMLC_DA_sys")

print_tree(PowerSimulations.PM.AbstractPowerModel)

PTDF_matrix = PTDF(sys)

template = template_unit_commitment(
    network = NetworkModel(
        StandardPTDFModel,
        PTDF = PTDF_matrix,
        duals = [CopperPlateBalanceConstraint],
        use_slacks = false,
    ),
    use_slacks = true,
)
for (k, v) in template.branches
    v.duals = [NetworkFlowConstraint]
end

problem = DecisionModel(template, sys, horizon = 24, optimizer = solver)
build!(problem, output_dir = mktempdir())

solve!(problem)

res = ProblemResults(problem)
duals = read_duals(
    res,
    [k for k in list_dual_keys(res) if PSI.get_entry_type(k) == NetworkFlowConstraint],
)
λ = read_dual(res, "CopperPlateBalanceConstraint__System")[:, 2]
flow_duals = outerjoin(values(duals)..., on = :DateTime)
μ = Matrix(flow_duals[:, PTDF_matrix.axes[1]])

LMP = flow_duals[:, [:DateTime]]
for bus in get_components(Bus, sys)
    LMP[:, get_name(bus)] = λ .+ μ * PTDF_matrix[:, get_number(bus)]
end

LMP

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

