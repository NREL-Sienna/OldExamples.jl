#! format: off

using SIIPExamples

using PowerSystems
using PowerSimulations
const PSI = PowerSimulations
using PowerSystemCaseBuilder

using HiGHS # solver

sys = build_system(PSITestSystems, "modified_RTS_GMLC_DA_sys")

template_uc = ProblemTemplate()

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

set_network_model!(template_uc, NetworkModel(CopperPlatePowerModel))

solver = optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.5)

problem = DecisionModel(template_uc, sys; optimizer = solver, horizon = 24)

build!(problem, output_dir = mktempdir())

print_struct(typeof(PSI.get_optimization_container(problem)))

solve!(problem)

print_struct(PSI.ProblemResults)

res = ProblemResults(problem);

get_optimizer_stats(res)

get_objective_value(res)

read_variables(res)

list_parameter_names(res)
read_parameter(res, "ActivePowerTimeSeriesParameter__RenewableDispatch")

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
