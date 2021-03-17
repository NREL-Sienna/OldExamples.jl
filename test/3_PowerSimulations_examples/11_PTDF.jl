using SIIPExamples
using PowerSystems
using PowerSimulations
using PowerSystemCaseBuilder
using DataFrames

using Ipopt
solver = optimizer_with_attributes(Ipopt.Optimizer)

sys = build_system(PSITestSystems, "modified_RTS_GMLC_DA_sys")

print_tree(PowerSimulations.PM.AbstractPowerModel)

ed_template = template_economic_dispatch(network = StandardPTDFModel)

set_device_model!(ed_template, HydroEnergyReservoir, HydroDispatchRunOfRiver)

PTDF_matrix = PTDF(sys)

problem = OperationsProblem(
    EconomicDispatchProblem,
    ed_template,
    sys,
    horizon = 1,
    optimizer = solver,
    balance_slack_variables = true,
    constraint_duals = [:CopperPlateBalance, :network_flow__Line, :network_flow__TapTransformer],
    PTDF = PTDF_matrix,
)
build!(problem, output_dir = mktempdir())

solve!(problem)

res = OperationsProblemResults(problem)
duals = get_duals(res)
λ = convert(Array, duals[:CopperPlateBalance][:,:var])
flow_duals = outerjoin([duals[k] for k in [:network_flow__Line,:network_flow__TapTransformer]]..., on = :DateTime)
μ = Matrix(flow_duals[:,PTDF_matrix.axes[1]])

buses = get_components(Bus, sys)
congestion_lmp = Dict()
for bus in buses
    congestion_lmp[get_name(bus)] = μ * PTDF_matrix[:, get_number(bus)]
end
congestion_lmp = DataFrame(congestion_lmp)

LMP = λ .- congestion_lmp

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

