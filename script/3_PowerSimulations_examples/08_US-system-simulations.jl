
#jl #! format: off
# # Large Scale Production Cost Modeling with [PowerSimulations.jl](https://github.com/NREL-SIIP/PowerSimulations.jl)

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# This example shows a basic PCM simulation using the system data assembled in the
# [US-System example](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/2_PowerSystems_examples/08_US_system.ipynb).

# ### Dependencies
using SIIPExamples
using PowerSystems
using PowerSimulations
using PowerGraphics
using Logging
using Dates

pkgpath = pkgdir(SIIPExamples)
PSI = PowerSimulations
plotlyjs()

# ### Optimization packages
# You can use the free solvers as in one of the other PowerSimulations.jl examples, but on
# large problems it's useful to have a solver with better performance. I'll use the Xpress
# solver since I have a license, but others such as Gurobi or CPLEX work well too.
using Xpress
solver = optimizer_with_attributes(Xpress.Optimizer, "MIPRELSTOP" => 0.1, "OUTPUTLOG" => 1)

# ### Load the US `System`.
# If you have run the
# [US-System example](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/2_PowerSystems_examples/08_US-System.ipynb), the data will
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
template = ProblemTemplate(DCPPowerModel)
set_device_model!(template, Line, StaticBranchUnbounded)
set_device_model!(template, TapTransformer, StaticBranchUnbounded)
set_device_model!(template, MonitoredLine, StaticBranch)
set_device_model!(template, ThermalStandard, ThermalStandardUnitCommitment)
set_device_model!(template, RenewableDispatch, RenewableFullDispatch)
set_device_model!(template, PowerLoad, StaticPowerLoad)
set_device_model!(template, HydroDispatch, FixedOutput)

# ### Build and execute single step problem
op_problem = DecisionModel(template, sys; optimizer = solver, horizon = 24)

build!(op_problem, output_dir = mktempdir(), console_level = Logging.Info)

solve!(op_problem)

# ### Analyze results
res = ProblemResults(op_problem)
plot_fuel(res)

# ## Sequential Simulation
# In addition to defining the formulation template, sequential simulations require
# definitions for how information flows between problems.
sim_folder = mkpath(joinpath(pkgpath, "Texas-sim"))
models = SimulationModels(
    decision_models = [
        DecisionModel(
            template,
            sys,
            name = "UC",
            optimizer = solver,
            system_to_file = false,
        ),
    ],
)
DA_sequence =
    SimulationSequence(models = models, ini_cond_chronology = IntraProblemChronology())

# ### Define and build a simulation
sim = Simulation(
    name = "Texas-test",
    steps = 3,
    models = models,
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
#nb uc_results = get_decision_problem_results(results, "UC");

#nb plot_fuel(uc_results)
