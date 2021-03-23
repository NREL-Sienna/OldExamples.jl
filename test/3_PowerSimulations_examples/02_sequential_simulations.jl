using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(
    joinpath(pkgpath, "test", "3_PowerSimulations_examples", "01_operations_problems.jl"),
)

sys_RT = build_system(PSITestSystems, "modified_RTS_GMLC_RT_sys")

#set_device_model!(template_ed, GenericBattery, BookKeeping)
template_uc

template_ed = template_economic_dispatch()

problems = SimulationProblems(
    UC = OperationsProblem(template_uc, sys, optimizer = solver),
    ED = OperationsProblem(
        template_ed,
        sys_RT,
        optimizer = solver,
        balance_slack_variables = true,
    ),
)

feedforward_chronologies = Dict(("UC" => "ED") => Synchronize(periods = 24))

feedforward = Dict(
    ("ED", :devices, :ThermalStandard) => SemiContinuousFF(
        binary_source_problem = PSI.ON,
        affected_variables = [PSI.ACTIVE_POWER],
    ),
)

intervals = Dict("UC" => (Hour(24), Consecutive()), "ED" => (Minute(15), Consecutive()))

DA_RT_sequence = SimulationSequence(
    problems = problems,
    intervals = intervals,
    ini_cond_chronology = InterProblemChronology(),
    feedforward_chronologies = feedforward_chronologies,
    feedforward = feedforward,
)

sim = Simulation(
    name = "rts-test",
    steps = 1,
    problems = problems,
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
    :P__max_active_power__RenewableFix,
    initial_time = DateTime("2020-01-01T06:00:00"),
    count = 5,
)

read_realized_variables(uc_results, names = [:P__ThermalStandard, :P__RenewableDispatch])

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

