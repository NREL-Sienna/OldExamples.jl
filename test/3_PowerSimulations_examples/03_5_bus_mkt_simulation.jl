using PowerSystems
using PowerSimulations
using PowerSystemCaseBuilder

using Dates
using DataFrames

using Cbc # mip solver
solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 1, "ratioGap" => 0.5)
using Ipopt # solver that supports duals
ipopt_solver = optimizer_with_attributes(Ipopt.Optimizer, "print_level" => 0)

sys_DA = build_system(SIIPExampleSystems, "5_bus_matpower_DA")
sys_RT = build_system(SIIPExampleSystems, "5_bus_matpower_RT")

template_uc = template_unit_commitment()
template_ed = template_economic_dispatch()

problems = SimulationProblems(
    UC = OperationsProblem(
        template_uc,
        sys_DA,
        optimizer = solver,
        balance_slack_variables = true,
    ),
    ED = OperationsProblem(
        template_ed,
        sys_RT,
        optimizer = ipopt_solver,
        constraint_duals = [:CopperPlateBalance],
    ),
)

feedforward_chronologies = Dict(("UC" => "ED") => Synchronize(periods = 24))

feedforward = Dict(
    ("ED", :devices, :ThermalStandard) => SemiContinuousFF(
        binary_source_problem = ON,
        affected_variables = [ACTIVE_POWER],
    ),
)

#cache = Dict("UC" => [TimeStatusChange(ThermalStandard, PSI.ON)])
intervals = Dict("UC" => (Hour(24), Consecutive()), "ED" => (Hour(1), Consecutive()))

DA_RT_sequence = SimulationSequence(
    problems = problems,
    intervals = intervals,
    ini_cond_chronology = InterProblemChronology(),
    feedforward_chronologies = feedforward_chronologies,
    feedforward = feedforward,
)

file_path = mkpath(joinpath(".","5-bus-simulation"))
sim = Simulation(
    name = "5bus-test",
    steps = 1,
    problems = problems,
    sequence = DA_RT_sequence,
    simulation_folder = file_path,
)

build!(sim)

execute!(sim, enable_progress_bar = false)

# Results

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

