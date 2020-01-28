# # Hydropower Simulations with [PowerSimulations.jl](https://github.com/NREL/PowerSimulations.jl)

# **Originally Contributed by**: Clayton Barrows and Sourabh Dalvi

# ## Introduction

# PowerSimulations.jl supports simulations that consist of sequential optimization problems
# where results from previous problems inform subsequent problems in a variety of ways.
# This example demonstrates a few of the options for modeling hydropower generation.

# ## Dependencies
using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))

# ### Modeling Packages
using InfrastructureSystems
const IS = InfrastructureSystems
using PowerSystems
const PSY = PowerSystems
using PowerSimulations
const PSI = PowerSimulations
using D3TypeTrees

# ### Data management packages
using Dates
using DataFrames

# ### Optimization packages
using JuMP
using Cbc # solver
Cbc_optimizer = JuMP.with_optimizer(Cbc.Optimizer, logLevel = 1, ratioGap = 0.5)

# ### Data
# There is a meaningless test dataset assembled in the
# [make_hydropower_data.jl](../../script/PowerSimulations_examples/make_hydro_data.jl) script.

include(joinpath(pkgpath, "script/PowerSimulations_examples/make_hydro_data.jl"))

# ## Two PowerSimulations features determine hydropower representation.
# There are two prinicpal ways that we can customize hydropower representation in
# PowerSimulations. First, we can play with the formulation applied to hydropower generators
# using the `DeviceModel`. We can also adjust how simulaitons are configured to represent
# different decison making processes and the information flow between those processes.

# ### Hydropower `DeviceModel`s

# First, the assignment of device formulations to particular device types gives us control
# over the representation of devices. This is accomplished by defining `DeviceModel`
# instances. For hydro power representations, we have two available generator types in
# PowerSystems:

TypeTree(PSY.HydroGen)

# And in PowerSimulations, we have several available formulations that can be applied to
# the hydropower generation devices:

TypeTree(PSI.AbstractHydroFormulation)

# Let's see what some of the different combinations create. First, let's apply the
# `HydroDispatchRunOfRiver` formulation to the `HydroDispatch` generators, and the
# `HydroFixed` formulation to `HydroFix` generators.
#  - The `HydroFixed` formulaton just acts
# like a load subtractor, forcing the system to accept it's generation.
#  - The `HydroDispatchRunOfRiver` formulation represents the the energy flowing out of
# a reservoir. The model can choose to produce power with that energy or just let it spill by.

devices = Dict{Symbol,DeviceModel}(
    :Hyd1 => DeviceModel(HydroDispatch, HydroDispatchRunOfRiver),
    :Hyd2 => DeviceModel(HydroFix, HydroFixed),
    :Load => DeviceModel(PowerLoad, StaticPowerLoad),
);

template = PSI.OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

op_problem = PSI.OperationsProblem(GenericOpProblem, template, c_sys5_hy, horizon = 2)

# Now we can see the resulting JuMP model:

op_problem.psi_container.JuMPmodel

# The first two constraints are the power balance constraints that require the generation
# from the controllable `HydroDispatch` generators to be equal to the load (flat 10.0 for all time periods)
# minus the generation from the `HydroFix` generators [1.97, 1.983, ...]. The 3rd and 4th
# constraints limit the output of the `HydroDispatch` generator to the limit defined by the
# `max_activepwoer` forecast. And the last 4 constraints are the lower and upper bounds of
# the `HydroDispatch` operating range.

#-

# Next, let's apply the `HydroDispatchReservoirFlow` formulation to the `HydroDispatch` generators.
devices = Dict{Symbol,DeviceModel}(
    :Hyd1 => DeviceModel(HydroDispatch, HydroDispatchReservoirFlow),
    :Load => DeviceModel(PowerLoad, StaticPowerLoad),
);

template = PSI.OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

op_problem = PSI.OperationsProblem(GenericOpProblem, template, c_sys5_hy, horizon = 2)

# And, the resulting JuMP model:

op_problem.psi_container.JuMPmodel

# Finally, let's apply the `HydroDispatchReservoirStorage` formulation to the `HydroDispatch` generators.

devices = Dict{Symbol,DeviceModel}(
    :Hyd1 => DeviceModel(HydroDispatch, HydroDispatchReservoirStorage),
    :Load => DeviceModel(PowerLoad, StaticPowerLoad),
);

template = PSI.OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

op_problem = PSI.OperationsProblem(GenericOpProblem, template, c_sys5_hy, horizon = 2)

#-

op_problem.psi_container.JuMPmodel

# ### Multi-Stage `SimulationSequence`
# The purpsoe of a multi-stage simulaiton is to represent scheduling decisions consistently
# with the time scales that govern different elements of power systems.


# Multi-Day to Daily Simulation:

# In the multi-day model, we'll use a really simple representation of all system devices
# so that we can maintain computational tractability while getting an estimate of system
# requirements/capabilities.

devices = Dict(
    :Generators => DeviceModel(ThermalStandard, ThermalDispatchNoMin),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :HydroDispatch => DeviceModel(HydroDispatch, HydroDispatchReservoirStorage),
)
template_md = OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

# For the daily model, we can increase the modeling detail since we'll be solving shorter
# problems.

devices = Dict(
    :Generators => DeviceModel(ThermalStandard, ThermalDispatchNoMin),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :HydroDispatch => DeviceModel(HydroDispatch, HydroDispatchReservoirFlow),
)
template_da = OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

#-

stages_definition = Dict(
    "MD" => Stage(GenericOpProblem, template_md, c_sys5_hy_wk, Cbc_optimizer),
    "DA" => Stage(GenericOpProblem, template_da, c_sys5_hy_uc, Cbc_optimizer),
)

# Thsi builds the sequence and passes the the enregy dispatch schedule for the `HydroDispatch`
# generatorfrom the "MD" stage to the "DA" stage in the form of an energy limit over the
# synchronized periods.

sequence = SimulationSequence(
    order = Dict(1 => "MD", 2 => "DA"),
    intra_stage_chronologies = Dict(("MD" => "DA") => Synchronize(periods = 2)),
    horizons = Dict("MD" => 2, "DA" => 24),
    intervals = Dict("MD" => Hour(48), "DA" => Hour(24)),
    feed_forward = Dict(
        ("DA", :devices, :HydroDispatch) =>
                IntegralLimitFF(variable_from_stage = :P, affected_variables = [:P]),
    ),
    ini_cond_chronology = Dict("MD" => Consecutive(), "DA" => Consecutive()),
)

#-

file_path = tempdir()

sim = Simulation(
    name = "hydro",
    steps = 1,
    step_resolution = Hour(48),
    stages = stages_definition,
    stages_sequence = sequence,
    simulation_folder = file_path,
    verbose = true,
)

build!(sim)

# We can look at the "MD" Model

sim.stages["MD"].internal.psi_container.JuMPmodel

# And we can look at the "DA" model

sim.stages["DA"].internal.psi_container.JuMPmodel

# And we can execute the simulation by running the following command
# ```julia
#sim_results = execute!(sim)
#```
#-

# 3-Stage Simulation:

stages_definition = Dict(
    "MD" => Stage(GenericOpProblem, template_md, c_sys5_hy_wk, Cbc_optimizer),
    "UC" => Stage(GenericOpProblem, template_da, c_sys5_hy_uc, Cbc_optimizer),
    "ED" => Stage(GenericOpProblem, template_da, c_sys5_hy_ed, Cbc_optimizer),
)

sequence = SimulationSequence(
    order = Dict(1 => "MD", 2 => "UC", 3 => "ED"),
    intra_stage_chronologies = Dict(
        ("MD" => "UC") => Synchronize(periods = 2),
        ("UC" => "ED") => Synchronize(periods = 24),
    ),
    horizons = Dict("MD" => 2, "UC" => 24, "ED" => 12),
    intervals = Dict("MD" => Hour(48), "UC" => Hour(24), "ED" => Hour(1)),
    feed_forward = Dict(
        ("UC", :devices, :HydroDispatch) => IntegralLimitFF(
            variable_from_stage = Symbol(PSI.REAL_POWER),
            affected_variables = [Symbol(PSI.REAL_POWER)],
        ),
        ("ED", :devices, :HydroDispatch) => IntegralLimitFF(
            variable_from_stage = Symbol(PSI.REAL_POWER),
            affected_variables = [Symbol(PSI.REAL_POWER)],
        ),
    ),
    ini_cond_chronology = Dict(
        "DA" => Consecutive(),
        "UC" => Consecutive(),
        "ED" => Consecutive(),
    ),
)

#-

sim = Simulation(
    name = "hydro",
    steps = 1,
    step_resolution = Hour(48),
    stages = stages_definition,
    stages_sequence = sequence,
    simulation_folder = file_path,
    verbose = true,
)

#-

build!(sim)
