using SIIPExamples

using PowerSystems
using PowerSimulations
const PSI = PowerSimulations
using PowerSystemCaseBuilder

using Dates
using DataFrames

using Cbc #solver

sys = build_system(PSITestSystems, "modified_RTS_GMLC_DA_sys")

template_uc = OperationsProblemTemplate()

print_tree(PSI.AbstractDeviceFormulation)

set_device_model!(template_uc, Line, StaticBranch)
set_device_model!(template_uc, Transformer2W, StaticBranch)
set_device_model!(template_uc, TapTransformer, StaticBranch)

set_device_model!(template_uc, ThermalStandard, ThermalStandardUnitCommitment)
set_device_model!(template_uc, RenewableDispatch, RenewableFullDispatch)
set_device_model!(template_uc, PowerLoad, StaticPowerLoad)
set_device_model!(template_uc, HydroDispatch, FixedOutput)
set_device_model!(template_uc, HydroEnergyReservoir, HydroDispatchRunOfRiver)
set_device_model!(template_uc, RenewableFix, FixedOutput)

set_service_model!(template_uc, VariableReserve{ReserveUp}, RangeReserve)
set_service_model!(template_uc, VariableReserve{ReserveDown}, RangeReserve)

set_transmission_model!(template_uc, CopperPlatePowerModel)

solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 1, "ratioGap" => 0.5)

op_problem = OperationsProblem(template_uc, sys; optimizer = solver, horizon = 24)

build!(op_problem, output_dir = mktempdir())

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

