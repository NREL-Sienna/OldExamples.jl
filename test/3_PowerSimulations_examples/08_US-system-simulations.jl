using SIIPExamples
using PowerSystems
using PowerSimulations
using PowerGraphics
using Logging
using Dates

pkgpath = dirname(dirname(pathof(SIIPExamples)))
PSI = PowerSimulations
plotlyjs()

using Xpress
solver = optimizer_with_attributes(Xpress.Optimizer, "MIPRELSTOP" => 0.1, "OUTPUTLOG" => 1)

sys = System(joinpath(pkgpath, "US-System", "SIIP", "sys.json"))
horizon = 24;
interval = Dates.Hour(24);
transform_single_time_series!(sys, horizon, interval);

for line in get_components(Line, sys)
    if (get_base_voltage(get_from(get_arc(line))) >= 230.0) &&
       (get_base_voltage(get_to(get_arc(line))) >= 230.0)
        #if get_area(get_from(get_arc(line))) != get_area(get_to(get_arc(line)))
        @info "Changing $(get_name(line)) to MonitoredLine"
        convert_component!(MonitoredLine, line, sys)
    end
end

branches = Dict{Symbol, DeviceModel}(
    :L => DeviceModel(Line, StaticLineUnbounded),
    :TT => DeviceModel(TapTransformer, StaticTransformer),
    :ML => DeviceModel(MonitoredLine, StaticLine),
)

devices = Dict(
    :Generators => DeviceModel(ThermalStandard, ThermalStandardUnitCommitment),
    :Ren => DeviceModel(RenewableDispatch, RenewableFullDispatch),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :HydroROR => DeviceModel(HydroDispatch, FixedOutput),
)

template = OperationsProblemTemplate(DCPPowerModel, devices, branches, Dict());

op_problem = OperationsProblem(
    GenericOpProblem,
    template,
    sys;
    optimizer = solver,
    horizon = 24,
    balance_slack_variables = false,
    use_parameters = true,
)

res = solve!(op_problem)

fuel_plot(res, sys, load = true)

sim_folder = mkpath(joinpath(pkgpath, "Texas-sim"),)
stages_definition = Dict(
    "UC" =>
        Stage(GenericOpProblem, template, sys, solver; balance_slack_variables = true),
)
order = Dict(1 => "UC")
horizons = Dict("UC" => 24)
intervals = Dict("UC" => (Hour(24), Consecutive()))
DA_sequence = SimulationSequence(
    step_resolution = Hour(24),
    order = order,
    horizons = horizons,
    intervals = intervals,
    ini_cond_chronology = IntraStageChronology(),
)

sim = Simulation(
    name = "Texas-test",
    steps = 3,
    stages = stages_definition,
    stages_sequence = DA_sequence,
    simulation_folder = "Texas-sim",
)

build!(
    sim,
    console_level = Logging.Info,
    file_level = Logging.Debug,
    recorders = [:simulation],
)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

