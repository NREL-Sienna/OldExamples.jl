
# # Large Scale Production Cost Modeling with [PowerSimulations.jl](https://github.com/NREL-SIIP/PowerSimulations.jl)

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# This example shows a basic PCM simulation using the system data assembled in the
# [US-System example](../../notebook/2_PowerSystems_examples/08_US_system.ipynb).

# ### Dependencies
using SIIPExamples
using PowerSystems
using PowerSimulations
using PowerGraphics
using Logging
using Dates

pkgpath = dirname(dirname(pathof(SIIPExamples)))
PSI = PowerSimulations
plotlyjs()

# ### Optimization packages
# You can use the cbc solver as in one of the other PowerSimulations.jl examples, but on
# large problems it's useful to have a solver with better performance. I'll use the Xpress
# solver since I have a license, but others such as Gurobi or CPLEX work well too.
using Xpress
solver = optimizer_with_attributes(Xpress.Optimizer, "MIPRELSTOP" => 0.1, "OUTPUTLOG" => 1)

# ### Load the US `System`.
# If you have run the
# [US-System example](../../notebook/2_PowerSystems_examples/US-System.ipynb), the data will
# be serialized in the json and H5 format, so we can efficiently deserialize it:

sys = System(joinpath(pkgpath, "US-System", "SIIP", "sys.json"))
horizon = 24;
interval = Dates.Hour(24);
transform_single_time_series!(sys, horizon, interval);

# ### Selecting flow limited lines
# Since PowerSimulations will apply constraints by component type (e.g. Line), we need to
# change the component type of the lines on which we want to enforce flow limits. So, let's
# change the device type of certain branches from Line to MonitoredLine differentiate
# treatment when we build the model. Here, we can select inter-regional lines, or lines
# above a voltage threshold.

for line in get_components(Line, sys)
    if (get_base_voltage(get_from(get_arc(line))) >= 230.0) &&
       (get_base_voltage(get_to(get_arc(line))) >= 230.0)
        #if get_area(get_from(get_arc(line))) != get_area(get_to(get_arc(line)))
        @info "Changing $(get_name(line)) to MonitoredLine"
        convert_component!(MonitoredLine, line, sys)
    end
end

# ### Create a `template`
# Now we can create a `template` that applies an unbounded formulation to `Line`s and the standard
# flow limited formulation to `MonitoredLine`s.
template = OperationsProblemTemplate(PTDFPowerModel)
set_device_model!(template, Line, StaticBranchUnbounded)
set_device_model!(template, TapTransformer, StaticBranchUnbounded)
set_device_model!(template, MonitoredLine, StaticBranch)
set_device_model!(template, ThermalStandard, ThermalStandardUnitCommitment)
set_device_model!(template, RenewableDispatch, RenewableFullDispatch)
set_device_model!(template, PowerLoad, StaticPowerLoad)
set_device_model!(template, HydroDispatch, FixedOutput)

# ### Build and execute single step problem
op_problem = OperationsProblem(
    template,
    sys;
    optimizer = solver,
    horizon = 24,
    balance_slack_variables = false,
    use_parameters = true,
)

build!(op_problem, output_dir = mktempdir())

solve!(op_problem)

# ### Analyze results
fuel_plot(op_problem, sys, load = true)

# ## Sequential Simulation
# In addition to defining the formulation template, sequential simulations require
# definitions for how information flows between problems.
sim_folder = mkpath(joinpath(pkgpath, "Texas-sim"))
problems = SimulationProblems(
    UC = OperationsProblem(
        template,
        sys,
        optimizer = solver,
        balance_slack_variables = true,
    ),
)
intervals = Dict("UC" => (Hour(24), Consecutive()))
DA_sequence = SimulationSequence(
    intervals = intervals,
    ini_cond_chronology = IntraProblemChronology(),
)

# ### Define and build a simulation
sim = Simulation(
    name = "Texas-test",
    steps = 3,
    problems = problems,
    sequence = DA_sequence,
    simulation_folder = "Texas-sim",
)

build!(
    sim,
    console_level = Logging.Info,
    file_level = Logging.Debug,
    recorders = [:simulation],
)

# ### Execute the simulation
#nb execute!(sim)

# ### Load and analyze results
#nb results = SimulationResults(sim);
#nb uc_results = get_problem_results(results, "UC");

#nb fuel_plot(uc_results, load = true, curtailment = true, stack = true)
