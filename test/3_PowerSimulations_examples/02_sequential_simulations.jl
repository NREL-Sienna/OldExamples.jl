using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(
    joinpath(pkgpath, "test", "3_PowerSimulations_examples", "01_operations_problems.jl"),
)

sys_RT = System(rawsys; time_series_resolution = Dates.Minute(5))
transform_single_time_series!(sys_RT, 12, Hour(1))

devices = Dict(
    :Generators => DeviceModel(ThermalStandard, ThermalStandardUnitCommitment),
    :Ren => DeviceModel(RenewableDispatch, RenewableFullDispatch),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :HydroROR => DeviceModel(HydroDispatch, FixedOutput),
    :Hydro => DeviceModel(HydroEnergyReservoir, HydroDispatchRunOfRiver),
    :RenFx => DeviceModel(RenewableFix, FixedOutput),
)
template_uc = template_unit_commitment(devices = devices)

devices = Dict(
    :Generators => DeviceModel(ThermalStandard, ThermalDispatch),
    :Ren => DeviceModel(RenewableDispatch, RenewableFullDispatch),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :HydroROR => DeviceModel(HydroDispatch, FixedOutput),
    :Hydro => DeviceModel(HydroEnergyReservoir, HydroDispatchRunOfRiver),
    :RenFx => DeviceModel(RenewableFix, FixedOutput),
)
template_ed = template_economic_dispatch(devices = devices)

stages_definition = Dict(
    "UC" => Stage(GenericOpProblem, template_uc, sys, solver),
    "ED" => Stage(
        GenericOpProblem,
        template_ed,
        sys_RT,
        solver,
        balance_slack_variables = true,
    ),
)

feedforward_chronologies = Dict(("UC" => "ED") => Synchronize(periods = 24))

feedforward = Dict(
    ("ED", :devices, :Generators) => SemiContinuousFF(
        binary_source_stage = PSI.ON,
        affected_variables = [PSI.ACTIVE_POWER],
    ),
)

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
)

sim = Simulation(
    name = "rts-test",
    steps = 1,
    stages = stages_definition,
    stages_sequence = DA_RT_sequence,
    simulation_folder = rts_dir,
)

build!(sim)

execute!(sim)

results = SimulationResults(sim)
uc_results = get_stage_results(results, "UC"); # UC stage result metadata
ed_results = get_stage_results(results, "ED"); # ED stage result metadata

read_variables(uc_results, names = [:P__ThermalStandard, :P__RenewableDispatch])

read_parameter(
    ed_results,
    :P__max_active_power__RenewableFix,
    initial_time = DateTime("2020-01-01T06:00:00"),
    count = 5,
)

read_realized_variables(uc_results, names = [:P__ThermalStandard, :P__RenewableDispatch])

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

