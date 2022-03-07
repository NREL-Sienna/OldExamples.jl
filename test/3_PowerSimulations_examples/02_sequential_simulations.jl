#! format: off

using SIIPExamples

using PowerSystems
using PowerSimulations
const PSI = PowerSimulations
using PowerSystemCaseBuilder
using Dates

using HiGHS #solver

solver = optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.5)

sys_DA = build_system(PSITestSystems, "modified_RTS_GMLC_DA_sys")

sys_RT = build_system(PSITestSystems, "modified_RTS_GMLC_RT_sys")

template_uc = template_unit_commitment()
set_device_model!(template_uc, ThermalStandard, ThermalStandardUnitCommitment)

template_ed = template_economic_dispatch(
    network = NetworkModel(StandardPTDFModel, PTDF = PTDF(sys_DA), use_slacks = true),#NetworkModel(CopperPlatePowerModel, use_slacks = true),
)

models = SimulationModels(
    decision_models = [
        DecisionModel(template_uc, sys_DA, optimizer = solver, name = "UC"),
        DecisionModel(template_ed, sys_RT, optimizer = solver, name = "ED"),
    ],
)

feedforward = Dict(
    "ED" => [
        SemiContinuousFeedforward(
            component_type = ThermalStandard,
            source = OnVariable,
            affected_values = [ActivePowerVariable],
        ),
    ],
)

DA_RT_sequence = SimulationSequence(
    models = models,
    ini_cond_chronology = InterProblemChronology(),
    feedforwards = feedforward,
)

sim = Simulation(
    name = "rts-test",
    steps = 2,
    models = models,
    sequence = DA_RT_sequence,
    simulation_folder = mktempdir(".", cleanup = true),
)

build!(sim)

execute!(sim, enable_progress_bar = false)

results = SimulationResults(sim);
uc_results = get_problem_results(results, "UC"); # UC stage result metadata
ed_results = get_problem_results(results, "ED"); # ED stage result metadata

list_variable_names(uc_results)

list_parameter_names(uc_results)

read_variables(
    uc_results,
    [
        "ActivePowerVariable__RenewableDispatch",
        "ActivePowerVariable__HydroDispatch",
        "StopVariable__ThermalStandard",
    ],
)

read_parameter(
    ed_results,
    "ActivePowerTimeSeriesParameter__RenewableFix",
    initial_time = DateTime("2020-01-01T06:00:00"),
    count = 5,
)

read_realized_variables(
    uc_results,
    ["ActivePowerVariable__ThermalStandard", "ActivePowerVariable__RenewableDispatch"],
)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

