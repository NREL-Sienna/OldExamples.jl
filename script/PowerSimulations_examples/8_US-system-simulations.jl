
# # Large Scale Production Cost Modeling with [PowerSimulations.jl](https://github.com/NREL-SIIP/PowerSimulations.jl)

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# This example shows a basic PCM simulation using the system data assembled in the
# [US-System example](../../notebook/PowerSystems_examples/US_system.ipynb).

# ### Dependencies
using SIIPExamples
using PowerSystems
using PowerSimulations
using PowerGraphics
using Logging
pkgpath = dirname(dirname(pathof(SIIPExamples)))
PSY = PowerSystems
PSI = PowerSimulations
plotlyjs()

# ### Optimization packages
# For this simple example, we can use the Cbc solver with a relatively relaxed tolerance.
using Cbc #solver
solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 1, "ratioGap" => 0.1)

using Xpress
solver = optimizer_with_attributes(Xpress.Optimizer, "MIPRELSTOP" => 0.1, "OUTPUTLOG" => 1)

# ### Create a `System` from US data.
# If you have run the
# [US-System example.](../../notebook/PowerSystems_examples/US-System.ipynb), the data will
# be serialized in the json and H5 format, so we can efficiently deserialize it:

sys = System(joinpath(pkgpath,"US-System", "SIIP", "sys.json"))

# ### Selecting flow limited lines
# Since PowerSimulations will apply constraints by component type (e.g. Line), we need to
# change the component type of the lines on which we want to enforce flow limits. So, let's
# change the device type of certain branches from Line to MonitoredLine differentiate
# treatment when we build the model. Here, we can select inter-regional lines, or lines
# above a voltage threshold.

for line in get_components(Line, sys)
    if (get_basevoltage(get_from(get_arc(line))) >= 230.0) &&
       (get_basevoltage(get_to(get_arc(line))) >= 230.0)
        #if get_area(get_from(get_arc(line))) != get_area(get_to(get_arc(line)))
        @info "Changing $(get_name(line)) to MonitoredLine"
        convert_component!(MonitoredLine, line, sys)
    end
end

branches = Dict{Symbol, DeviceModel}(
    :L => DeviceModel(Line, StaticLineUnbounded),
    :T => DeviceModel(Transformer2W, StaticTransformer),
    :TT => DeviceModel(TapTransformer, StaticTransformer),
    :ML => DeviceModel(MonitoredLine, StaticLine),
    :DC => DeviceModel(HVDCLine, HVDCDispatch),
)

devices = Dict(
    :Generators => DeviceModel(ThermalStandard, ThermalStandardUnitCommitment),
    :Ren => DeviceModel(RenewableDispatch, RenewableFullDispatch),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :HydroROR => DeviceModel(HydroDispatch, FixedOutput),
    :RenFx => DeviceModel(RenewableFix, FixedOutput),
    :ILoads => DeviceModel(InterruptibleLoad, InterruptiblePowerLoad),
)

template = OperationsProblemTemplate(DCPPowerModel, devices, branches, Dict());

# ### Build and execute single step problem
op_problem =
    OperationsProblem(GenericOpProblem, template, sys; optimizer = solver, horizon = 24, slack_variables = false, use_parameters = true)

res =solve!(op_problem)

# ### Analyze results
fuel_plot(res, sys, load = true)

# ## Sequential Simulation
# In addition to defining the formulation template, sequential simulations require
# definitions for how information flows between problems.
sim_folder = mkpath(joinpath(pkgpath, "Texas-sim"), )
stages_definition = Dict(
    "UC" => Stage(GenericOpProblem, template, sys, solver; slack_variables = true)
)
order = Dict(1 => "UC")
horizons = Dict("UC" => 24)
intervals = Dict("UC" => (Hour(24), Consecutive()))
cache = Dict(("UC",) => TimeStatusChange(PSY.ThermalStandard, PSI.ON))
DA_sequence = SimulationSequence(
    step_resolution = Hour(24),
    order = order,
    horizons = horizons,
    intervals = intervals,
    ini_cond_chronology = InterStageChronology(),
    cache = cache, #needed for ThermalStandardUC not for Basic
)
# ### Define and build a simulation
sim = Simulation(
    name = "Texas-test",
    steps = 10,
    stages = stages_definition,
    stages_sequence = DA_sequence,
    simulation_folder = "Texas-sim"
)
build!(sim, console_level = Logging.Info, file_level = Logging.Debug)

# ### Execute the simulation
sim_results = execute!(sim)

# ### Load and analyze results
uc_results = load_simulation_results(sim_results, "UC");

fuel_plot(uc_results, sys, load = true)