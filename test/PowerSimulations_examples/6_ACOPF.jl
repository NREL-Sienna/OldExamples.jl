using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath, "test", "PowerSimulations_examples", "1_operations_problems.jl"));

using Ipopt
solver = optimizer_with_attributes(Ipopt.Optimizer)

ed_template = template_economic_dispatch(network = ACPPowerModel)

ed_template.devices[:HydroROR]= DeviceModel(HydroDispatch, HydroDispatchRunOfRiver)

problem = OperationsProblem(
    EconomicDispatchProblem,
    ed_template,
    sys,
    horizon = 4,
    optimizer = solver,
    balance_slack_variables = true,
)

solve!(problem)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

