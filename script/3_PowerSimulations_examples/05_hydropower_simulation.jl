#jl #! format: off
# # Hydropower Simulations with [PowerSimulations.jl](https://github.com/NREL-SIIP/PowerSimulations.jl)

# **Originally Contributed by**: Clayton Barrows and Sourabh Dalvi

# ## Introduction

# PowerSimulations.jl supports simulations that consist of sequential optimization problems
# where results from previous problems inform subsequent problems in a variety of ways.
# This example demonstrates a few of the options for modeling hydropower generation.

# ## Dependencies
using SIIPExamples

# ### Modeling Packages
using PowerSystems
using PowerSimulations
const PSI = PowerSimulations
using PowerSystemCaseBuilder

# ### Data management packages
using Dates
using DataFrames

# ### Optimization packages
using HiGHS # solver
solver = optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.05)
odir = mktempdir(".", cleanup = true) #tmpdir for build steps

# ### Data
# PowerSystemCaseBuilder links to some meaningless test data that is suitable for this example.
# We can load three systems of different resolution for the examples here:
c_sys5_hy_wk = build_system(SIIPExampleSystems, "5_bus_hydro_wk_sys")
c_sys5_hy_uc = build_system(SIIPExampleSystems, "5_bus_hydro_uc_sys")
c_sys5_hy_ed = build_system(SIIPExampleSystems, "5_bus_hydro_ed_sys")

c_sys5_hy_wk_targets = build_system(SIIPExampleSystems, "5_bus_hydro_wk_sys_with_targets")
c_sys5_hy_uc_targets = build_system(SIIPExampleSystems, "5_bus_hydro_uc_sys_with_targets")
c_sys5_hy_ed_targets = build_system(SIIPExampleSystems, "5_bus_hydro_ed_sys_with_targets")

# This line just overloads JuMP printing to remove double underscores added by PowerSimulations.jl
PSI.JuMP._wrap_in_math_mode(str) = "\$\$ $(replace(str, "__"=>"")) \$\$"

# ## Two PowerSimulations features determine hydropower representation.
# There are two principal ways that we can customize hydropower representation in
# PowerSimulations. First, we can play with the formulation applied to hydropower generators
# using the `DeviceModel`. We can also adjust how simulations are configured to represent
# different decision making processes and the information flow between those processes.

# ### Hydropower `DeviceModel`s

# First, the assignment of device formulations to particular device types gives us control
# over the representation of devices. This is accomplished by defining `DeviceModel`
# instances. For hydro power representations, we have two available generator types in
# PowerSystems:

print_tree(HydroGen)

# And in PowerSimulations, we have several available formulations that can be applied to
# the hydropower generation devices:

print_tree(PSI.AbstractHydroFormulation)

# Let's see what some of the different combinations create. First, let's apply the
# `HydroDispatchRunOfRiver` formulation to the `HydroEnergyReservoir` generators, and the
# `FixedOutput` formulation to `HydroDispatch` generators.
#  - The `FixedOutput` formulation just acts
# like a load subtractor, forcing the system to accept it's generation.
#  - The `HydroDispatchRunOfRiver` formulation represents the the energy flowing out of
# a reservoir. The model can choose to produce power with that energy or just let it spill by.
template = ProblemTemplate()
set_device_model!(template, HydroEnergyReservoir, HydroDispatchRunOfRiver)
set_device_model!(template, HydroDispatch, FixedOutput)
set_device_model!(template, PowerLoad, StaticPowerLoad)

prob = DecisionModel(template, c_sys5_hy_uc, horizon = 2)
build!(prob, output_dir = odir)

# Now we can see the resulting JuMP model:
PSI.get_jump_model(prob)

# The first two constraints are the power balance constraints that require the generation
# from the controllable `HydroEnergyReservoir` generators to be equal to the load (flat 10.0 for all time periods)
# minus the generation from the `HydroDispatch` generators [1.97, 1.983, ...]. The 3rd and 4th
# constraints limit the output of the `HydroEnergyReservoir` generator to the limit defined by the
# `max_activepwoer` time series. And the last 4 constraints are the lower and upper bounds of
# the `HydroEnergyReservoir` operating range.

#-

# Next, let's apply the `HydroDispatchReservoirBudget` formulation to the `HydroEnergyReservoir` generators.
template = ProblemTemplate()
set_device_model!(template, HydroEnergyReservoir, HydroDispatchReservoirBudget)
set_device_model!(template, PowerLoad, StaticPowerLoad)

prob = DecisionModel(template, c_sys5_hy_uc, horizon = 2)
build!(prob, output_dir = odir)

# And, the resulting JuMP model:
PSI.get_jump_model(prob)

# Finally, let's apply the `HydroDispatchReservoirStorage` formulation to the `HydroEnergyReservoir` generators.
template = ProblemTemplate()
set_device_model!(template, HydroEnergyReservoir, HydroDispatchReservoirStorage)
set_device_model!(template, PowerLoad, StaticPowerLoad)

prob = DecisionModel(template, c_sys5_hy_uc_targets, horizon = 24)
build!(prob, output_dir = odir)

#-
PSI.get_jump_model(prob)

# ### Multi-Stage `SimulationSequence`
# The purpose of a multi-stage simulation is to represent scheduling decisions consistently
# with the time scales that govern different elements of power systems.

# #### Multi-Day to Daily Simulation:
# In the multi-day model, we'll use a really simple representation of all system devices
# so that we can maintain computational tractability while getting an estimate of system
# requirements/capabilities.
template_md = ProblemTemplate()
set_device_model!(template_md, ThermalStandard, ThermalDispatchNoMin)
set_device_model!(template_md, PowerLoad, StaticPowerLoad)
set_device_model!(template_md, HydroEnergyReservoir, HydroDispatchReservoirStorage)

# For the daily model, we can increase the modeling detail since we'll be solving shorter
# problems.
template_da = ProblemTemplate()
set_device_model!(template_da, ThermalStandard, ThermalBasicUnitCommitment)
set_device_model!(template_da, PowerLoad, StaticPowerLoad)
set_device_model!(template_da, HydroEnergyReservoir, HydroDispatchReservoirStorage)
#-

problems = SimulationModels(
    decision_models = [
        DecisionModel(
            template_md,
            c_sys5_hy_wk_targets,
            name = "MD",
            optimizer = solver,
            system_to_file = false,
            initialize_model = false,
        ),
        DecisionModel(
            template_da,
            c_sys5_hy_uc_targets,
            name = "DA",
            optimizer = solver,
            system_to_file = false,
            initialize_model = false,
        ),
    ],
)

# This builds the sequence and passes the the energy dispatch schedule for the `HydroEnergyReservoir`
# generator from the "MD" problem to the "DA" problem in the form of an energy limit over the
# synchronized periods.

sequence = SimulationSequence(
    models = problems,
    feedforwards = Dict(
        "DA" => [
            EnergyLimitFeedforward(
                component_type = HydroEnergyReservoir,
                source = ActivePowerVariable,
                affected_values = [ActivePowerVariable],
                number_of_periods = get_forecast_horizon(c_sys5_hy_uc_targets),
            ),
        ],
    ),
    ini_cond_chronology = InterProblemChronology(),
);

#-

sim = Simulation(
    name = "hydro",
    steps = 1,
    models = problems,
    sequence = sequence,
    simulation_folder = odir,
)

build!(sim)

# We can look at the "MD" Model
PSI.get_jump_model(sim.models.decision_models[1])

# And we can look at the "DA" model
PSI.get_jump_model(sim.models.decision_models[2])

# And we can execute the simulation by running the following command
# ```julia
# execute!(sim)
# ```
#-

# #### 3-Stage Simulation:
transform_single_time_series!(c_sys5_hy_wk, 2, Hour(24)) # TODO fix PSI to enable longer intervals of stage 1

# For the real time model, we can increase the modeling detail since we'll be solving shorter
# problems.
template_ed = ProblemTemplate()
set_device_model!(template_ed, ThermalStandard, ThermalDispatchNoMin)
set_device_model!(template_ed, PowerLoad, StaticPowerLoad)
set_device_model!(template_ed, HydroEnergyReservoir, HydroDispatchReservoirStorage)

problems = SimulationModels(
    decision_models = [
        DecisionModel(
            template_md,
            c_sys5_hy_wk_targets,
            name = "MD",
            optimizer = solver,
            system_to_file = false,
            initialize_model = false,
        ),
        DecisionModel(
            template_da,
            c_sys5_hy_uc_targets,
            name = "DA",
            optimizer = solver,
            system_to_file = false,
            initialize_model = false,
        ),
        DecisionModel(
            template_ed,
            c_sys5_hy_ed_targets,
            name = "ED",
            optimizer = solver,
            system_to_file = false,
            initialize_model = false,
        ),
    ],
)

sequence = SimulationSequence(
    models = problems,
    feedforwards = Dict(
        "DA" => [
            EnergyLimitFeedforward(
                component_type = HydroEnergyReservoir,
                source = ActivePowerVariable,
                affected_values = [ActivePowerVariable],
                number_of_periods = get_forecast_horizon(c_sys5_hy_uc_targets),
            ),
        ],
        "ED" => [
            EnergyLimitFeedforward(
                component_type = HydroEnergyReservoir,
                source = ActivePowerVariable,
                affected_values = [ActivePowerVariable],
                number_of_periods = get_forecast_horizon(c_sys5_hy_ed_targets),
            ),
        ],
    ),
    ini_cond_chronology = InterProblemChronology(),
);

#-

sim = Simulation(
    name = "hydro",
    steps = 1,
    models = problems,
    sequence = sequence,
    simulation_folder = odir,
)

#-

build!(sim)

# We can look at the "MD" Model
PSI.get_jump_model(sim.models.decision_models[1])

# And we can look at the "DA" model
PSI.get_jump_model(sim.models.decision_models[2])

# And we can look at the "ED" model
PSI.get_jump_model(sim.models.decision_models[3])

# And we can execute the simulation by running the following command
# ```julia
# execute!(sim)
# ```
#-
