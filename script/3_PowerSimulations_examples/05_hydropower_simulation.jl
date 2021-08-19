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
using Cbc # solver
solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 1, "ratioGap" => 0.05)
odir = mktempdir() #tmpdir for build steps

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
template = OperationsProblemTemplate()
set_device_model!(template, HydroEnergyReservoir, HydroDispatchRunOfRiver)
set_device_model!(template, HydroDispatch, FixedOutput)
set_device_model!(template, PowerLoad, StaticPowerLoad)

op_problem = OperationsProblem(template, c_sys5_hy_uc, horizon = 2)
build!(op_problem, output_dir = odir)

# Now we can see the resulting JuMP model:

op_problem.internal.optimization_container.JuMPmodel

# The first two constraints are the power balance constraints that require the generation
# from the controllable `HydroEnergyReservoir` generators to be equal to the load (flat 10.0 for all time periods)
# minus the generation from the `HydroDispatch` generators [1.97, 1.983, ...]. The 3rd and 4th
# constraints limit the output of the `HydroEnergyReservoir` generator to the limit defined by the
# `max_activepwoer` time series. And the last 4 constraints are the lower and upper bounds of
# the `HydroEnergyReservoir` operating range.

#-

# Next, let's apply the `HydroDispatchReservoirBudget` formulation to the `HydroEnergyReservoir` generators.
template = OperationsProblemTemplate()
set_device_model!(template, HydroEnergyReservoir, HydroDispatchReservoirBudget)
set_device_model!(template, PowerLoad, StaticPowerLoad)

op_problem = PSI.OperationsProblem(template, c_sys5_hy_uc, horizon = 2)
build!(op_problem, output_dir = odir)

# And, the resulting JuMP model:

op_problem.internal.optimization_container.JuMPmodel

# Finally, let's apply the `HydroDispatchReservoirStorage` formulation to the `HydroEnergyReservoir` generators.
template = OperationsProblemTemplate()
set_device_model!(template, HydroEnergyReservoir, HydroDispatchReservoirStorage)
set_device_model!(template, PowerLoad, StaticPowerLoad)

op_problem = PSI.OperationsProblem(template, c_sys5_hy_uc_targets, horizon = 24)
build!(op_problem, output_dir = odir)

#-

op_problem.internal.optimization_container.JuMPmodel

# ### Multi-Stage `SimulationSequence`
# The purpose of a multi-stage simulation is to represent scheduling decisions consistently
# with the time scales that govern different elements of power systems.

# #### Multi-Day to Daily Simulation:
# In the multi-day model, we'll use a really simple representation of all system devices
# so that we can maintain computational tractability while getting an estimate of system
# requirements/capabilities.
template_md = OperationsProblemTemplate()
set_device_model!(template_md, ThermalStandard, ThermalDispatch)
set_device_model!(template_md, PowerLoad, StaticPowerLoad)
set_device_model!(template_md, HydroEnergyReservoir, HydroDispatchReservoirStorage)

# For the daily model, we can increase the modeling detail since we'll be solving shorter
# problems.
template_da = OperationsProblemTemplate()
set_device_model!(template_da, ThermalStandard, ThermalDispatch)
set_device_model!(template_da, PowerLoad, StaticPowerLoad)
set_device_model!(template_da, HydroEnergyReservoir, HydroDispatchReservoirStorage)
#-

problems = SimulationProblems(
    MD = OperationsProblem(
        template_md,
        c_sys5_hy_wk_targets,
        optimizer = solver,
        system_to_file = false,
    ),
    DA = OperationsProblem(
        template_da,
        c_sys5_hy_uc_targets,
        optimizer = solver,
        system_to_file = false,
    ),
)

# This builds the sequence and passes the the energy dispatch schedule for the `HydroEnergyReservoir`
# generator from the "MD" problem to the "DA" problem in the form of an energy limit over the
# synchronized periods.

sequence = SimulationSequence(
    problems = problems,
    feedforward_chronologies = Dict(("MD" => "DA") => Synchronize(periods = 2)),
    intervals = Dict("MD" => (Hour(48), Consecutive()), "DA" => (Hour(24), Consecutive())),
    feedforward = Dict(
        ("DA", :devices, :HydroEnergyReservoir) => IntegralLimitFF(
            variable_source_problem = PSI.ACTIVE_POWER,
            affected_variables = [PSI.ACTIVE_POWER],
        ),
    ),
    cache = Dict(("MD", "DA") => StoredEnergy(HydroEnergyReservoir, PSI.ENERGY)),
    ini_cond_chronology = IntraProblemChronology(),
);

#-

sim = Simulation(
    name = "hydro",
    steps = 1,
    problems = problems,
    sequence = sequence,
    simulation_folder = odir,
)

build!(sim)

# We can look at the "MD" Model

sim.problems["MD"].internal.optimization_container.JuMPmodel

# And we can look at the "DA" model

sim.problems["DA"].internal.optimization_container.JuMPmodel

# And we can execute the simulation by running the following command
# ```julia
# execute!(sim)
# ```
#-

# #### 3-Stage Simulation:
transform_single_time_series!(c_sys5_hy_wk, 2, Hour(24)) # TODO fix PSI to enable longer intervals of stage 1

problems = SimulationProblems(
    MD = OperationsProblem(
        template_md,
        c_sys5_hy_wk_targets,
        optimizer = solver,
        system_to_file = false,
    ),
    DA = OperationsProblem(
        template_da,
        c_sys5_hy_uc_targets,
        optimizer = solver,
        system_to_file = false,
    ),
    ED = OperationsProblem(
        template_da,
        c_sys5_hy_ed,
        optimizer = solver,
        system_to_file = false,
    ),
)

sequence = SimulationSequence(
    problems = problems,
    feedforward_chronologies = Dict(
        ("MD" => "DA") => Synchronize(periods = 2),
        ("DA" => "ED") => Synchronize(periods = 24),
    ),
    intervals = Dict(
        "MD" => (Hour(24), Consecutive()),
        "DA" => (Hour(24), Consecutive()),
        "ED" => (Hour(1), Consecutive()),
    ),
    feedforward = Dict(
        ("DA", :devices, :HydroEnergyReservoir) => IntegralLimitFF(
            variable_source_problem = PSI.ACTIVE_POWER,
            affected_variables = [PSI.ACTIVE_POWER],
        ),
        ("ED", :devices, :HydroEnergyReservoir) => IntegralLimitFF(
            variable_source_problem = PSI.ACTIVE_POWER,
            affected_variables = [PSI.ACTIVE_POWER],
        ),
    ),
    cache = Dict(("MD", "DA") => StoredEnergy(HydroEnergyReservoir, PSI.ENERGY)),
    ini_cond_chronology = IntraProblemChronology(),
);

#-

sim = Simulation(
    name = "hydro",
    steps = 1,
    problems = problems,
    sequence = sequence,
    simulation_folder = odir,
)

#-

build!(sim)

# We can look at the "MD" Model

sim.problems["MD"].internal.optimization_container.JuMPmodel

# And we can look at the "DA" model

sim.problems["DA"].internal.optimization_container.JuMPmodel

# And we can look at the "ED" model

sim.problems["ED"].internal.optimization_container.JuMPmodel

# And we can execute the simulation by running the following command
# ```julia
# execute!(sim)
# ```
#-
