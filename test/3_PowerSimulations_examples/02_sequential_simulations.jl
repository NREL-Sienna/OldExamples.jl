#! format: off

using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(
    joinpath(pkgpath, "test", "3_PowerSimulations_examples", "01_operations_problems.jl"),
)

sys_RT = build_system(PSITestSystems, "modified_RTS_GMLC_RT_sys")

#set_device_model!(template_ed, GenericBattery, BookKeeping)
template_uc

template_ed = template_economic_dispatch()

models = SimulationModels(
    decision_models = [
        DecisionModel(template_uc, sys, optimizer = solver, name = "UC"),
        DecisionModel(template_ed, sys_RT, optimizer = solver, name = "ED"),
    ]
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
    steps = 1,
    models = models,
    sequence = DA_RT_sequence,
    simulation_folder = dirname(dirname(pathof(SIIPExamples))),
)

build!(sim)

execute!(sim, enable_progress_bar = false)

results = SimulationResults(sim);
uc_results = get_problem_results(results, "UC"); # UC stage result metadata
ed_results = get_problem_results(results, "ED"); # ED stage result metadata

read_variables(uc_results, names = [:P__ThermalStandard, :P__RenewableDispatch])

read_parameter(
    ed_results,
    :P__max_active_power__RenewableFix_max_active_power,
    initial_time = DateTime("2020-01-01T06:00:00"),
    count = 5,
)

read_realized_variables(uc_results, names = [:P__ThermalStandard, :P__RenewableDispatch])

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

