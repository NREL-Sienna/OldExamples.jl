using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath, "test", "PowerSimulations_examples", "1_operations_problems.jl"))

sys_RT = System(rawsys; forecast_resolution = Dates.Minute(5))

get_component(VariableReserve{ReserveUp}, sys, "Flex_Up").requirement = 5.0

devices = Dict(
    :Generators => DeviceModel(ThermalStandard, ThermalStandardUnitCommitment),
    :Ren => DeviceModel(RenewableDispatch, RenewableFullDispatch),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :HydroROR => DeviceModel(HydroDispatch, HydroDispatchRunOfRiver),
    :RenFx => DeviceModel(RenewableFix, RenewableFixed),
)
template_uc = template_unit_commitment(devices = devices)

devices = Dict(
    :Generators => DeviceModel(ThermalStandard, ThermalDispatch),
    :Ren => DeviceModel(RenewableDispatch, RenewableFullDispatch),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :HydroROR => DeviceModel(HydroDispatch, HydroDispatchRunOfRiver),
    :RenFx => DeviceModel(RenewableFix, RenewableFixed),
)
template_ed = template_economic_dispatch(devices = devices)

stages_definition = Dict(
    "UC" => Stage(GenericOpProblem, template_uc, sys, solver),
    "ED" => Stage(GenericOpProblem, template_ed, sys_RT, solver),
)

feedforward_chronologies = Dict(("UC" => "ED") => Synchronize(periods = 24))

feedforward = Dict(
    ("ED", :devices, :Generators) => SemiContinuousFF(
        binary_from_stage = PSI.ON,
        affected_variables = [PSI.ACTIVE_POWER],
    ),
)

cache = Dict(("UC",) => TimeStatusChange(PSY.ThermalStandard, PSI.ON))

order = Dict(1 => "UC", 2 => "ED")
horizons = Dict("UC" => 24, "ED" => 12)
intervals = Dict("UC" => (Hour(24), Consecutive()), "ED" => (Hour(1), Consecutive()))

DA_RT_sequence = SimulationSequence(
    step_resolution = Hour(24),
    order = order,
    horizons = horizons,
    intervals = intervals,
    ini_cond_chronology = InterStageChronology(),
    feedforward_chronologies = feedforward_chronologies,
    feedforward = feedforward,
    cache = cache,
)

sim = Simulation(
    name = "rts-test",
    steps = 1,
    stages = stages_definition,
    stages_sequence = DA_RT_sequence,
    simulation_folder = rts_dir,
)

build!(sim)

sim_results = execute!(sim)

uc_results = load_simulation_results(sim_results, "UC");
ed_results = load_simulation_results(sim_results, "ED");

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
