using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath, "test", "3_PowerSimulations_examples", "01_operations_problems.jl"));

using Ipopt
solver = optimizer_with_attributes(Ipopt.Optimizer)

ed_template = template_economic_dispatch(network = StandardPTDFModel)

ed_template.devices[:Hydro] = DeviceModel(HydroEnergyReservoir, HydroDispatchRunOfRiver)

PTDF_matrix = PTDF(sys)

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

res = solve!(problem)

λ = convert(Array, res.dual_values[:CopperPlateBalance])
μ = convert(Array, res.dual_values[:network_flow])

buses = get_components(Bus, sys)
congestion_lmp = Dict()
for bus in buses
    congestion_lmp[get_name(bus)] = μ * PTDF_matrix[:, get_number(bus)]
end
congestion_lmp = DataFrame(congestion_lmp)

LMP = λ .- congestion_lmp

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

