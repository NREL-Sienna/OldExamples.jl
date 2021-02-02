using SIIPExamples
using PowerSystems
using PowerSimulations
using Dates

pkgpath = pkgdir(SIIPExamples)
PowerSystems.download(PowerSystems.TestData; branch = "master") # *note* add `force=true` to get a fresh copy
base_dir = pkgdir(PowerSystems);

TAMU_DIR = joinpath(base_dir, "data", "ACTIVSg2000");
sys = TamuSystem(TAMU_DIR)
transform_single_time_series!(sys, 2, Hour(1))

using Ipopt
solver = optimizer_with_attributes(Ipopt.Optimizer)

devices = Dict(
        :Generators => DeviceModel(ThermalStandard, ThermalDispatch),
        :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
        :QLoads => DeviceModel(FixedAdmittance, StaticPowerLoad)
    )
ed_template = template_economic_dispatch(network = ACPPowerModel, devices = devices)

problem = OperationsProblem(
    EconomicDispatchProblem,
    ed_template,
    sys,
    horizon = 1,
    optimizer = solver,
    balance_slack_variables = true,
)

solve!(problem)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

