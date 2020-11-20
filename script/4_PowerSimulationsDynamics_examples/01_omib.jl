# One Machine against Infinite Bus (OMIB) simulation with [PowerSimulationsDynamics.jl](https://github.com/NREL-SIIP/PowerSimulationsDynamics.jl)

# **Originally Contributed by**: Rodrigo Henriquez and José Daniel Lara

# # Introduction

# This tutorial will introduce you to the functionality of `PowerSimulationsDynamics`
# for running power system dynamic simulations.
# Note that this tutorial is for `PowerSimulationsDynamics`. Current version already
# have a dedicated function to find an equilibrium point using a Power Flow method
# without relying in a guess of the initial condition.

# This tutorial presents a simulation of a two-bus system with an infinite bus
# (represented as a voltage source behind an impedance) at bus 1 and a classic
# machine on bus 2. The perturbation will be the trip of one of the two circuits
# (doubling its resistance and impedance) of the line that connects both buses.

# ## Step 1: Package Initialization

# The first step consists in initialize all packages that will be used to run the
# simulation. All the necessary packages are listed:

using PowerSimulationsDynamics
using PowerSystems
using Sundials
using Plots
gr()

# `PowerSystems` is used to properly define the data structure and establish an equilibrium
# point initial condition with a power flow routine, while `Sundials` is
# used to solve the problem defined in `PowerSimulationsDynamics`. We use `PSY` to
# abbreviate the `PowerSystems.jl` package.

# ## Step 2: Load the system

omib_sys = System("script/4_PowerSimulationsDynamics_examples/Data/omib_sys.json")

# ## Step 3: Build the simulation and initializing the problem

# The next step is to create the simulation structure. This will create the indexing
# of our system that will be used to formulate the differential-algebraic system of
# equations. To do so, it is required to specify the perturbation that will occur in
# the system. `PowerSimulationsDynamics` support two types of perturbations:

# - Network Switch: Change in the Y-bus values.
# - Change in Reference Parameter

# In here, he will use a Network Switch pertubation, that is modeled by modifying the
# admittance.matrix (Ybus) of the system. To do so we create a NetworkSwitch perturbation
# as follows:


#Compute the Y_bus after fault
#Collect the branch of the system as:
fault_branch = deepcopy(collect(get_components(Branch, omib_sys))[1])
#Duplicates the impedance of the reactance
fault_branch.x = fault_branch.x * 2
#Obtain the new Ybus of the faulted system
Ybus_fault = Ybus([fault_branch], get_components(Bus, omib_sys))[:, :]

#Construct the perturbation
perturbation_Ybus = NetworkSwitch(
    1.0, #change will occur at t = 1.0s
    Ybus_fault, #new Ybus
)


# With this, we are ready to create our simulation structure. To construct our simulation
# we use:

#Time span of our simulation
tspan = (0.0, 30.0)

#Define Simulation
sim = Simulation(
    pwd(),
    omib_sys, #system
    tspan, #time span
    perturbation_Ybus, #Type of perturbation
)

# This will correctly initialize the system. It essentially will run a power flow
# and update `V_ref`, `P_ref` and hence `eq_p` (the internal voltage) to match the
# solution of the power flow. It will also initialize the states in the equilibrium.


#Will print the initial states. It also give the symbols used to describe those states.
print_device_states(sim)
#Will export a dictionary with the initial condition values to explore
x0_init = get_initial_conditions(sim)


# ## Step 4: Run the Simulation

# Finally, to run the simulation we simply use:

#Solve problem
execute!(sim, #simulation structure
         IDA(), #Sundials DAE Solver
         dtmax=0.02); #Arguments: Maximum timestep allowed

# In some cases, the dynamic time step used for the simulation may fail. In such case, the
# keyword argument `dtmax` can be used to limit the maximum time step allowed for the simulation.

# ## Step 5: Exploring the solution

# After running the simulation, our simulation structure `sim` will contain the solution. For
# that `sim.solution` can be used to explore the solution structure. In this case
# `sim.solution.t` returns the vector of time, while `sim.solution.u` returns the array of
# states. In addition, `PowerSimulationsDynamics` has two functions to obtain different
# states of the solution:

# - `get_state_series(sim, ("generator-102-1", :δ))`: can be used to obtain the solution as
# a tuple of time and the required state. In this case, we are obtaining the rotor angle `:δ`
# of the generator named `"generator-102-1"`.

angle = get_state_series(sim, ("generator-102-1", :δ))
plot(angle, xlabel="time", ylabel="rotor angle [rad]", label="rotor angle")

# - `get_voltagemag_series(sim, 102)`: can be used to obtain the voltage magnitude as a
# tuple of time and voltage. In this case, we are obtaining the voltage magnitude at bus 102
# (where the generator is located).

volt = get_voltagemag_series(sim, 102)
plot(volt, xlabel="time", ylabel="Voltage [pu]", label="V_2")

# ## Optional: Small Signal Analysis

# `PowerSimulationsDynamics` uses automatic differentiation to compute the reduced Jacobian
# of the system for the differential states. This can be used to analyze the local stability
# of the linearized system. We need to re-initialize our simulation:

sim2 = Simulation(
    pwd(),
    omib_sys, #system
    tspan, #time span
    perturbation_Ybus, #Type of perturbation
)

small_sig = small_signal_analysis(sim2)

# The `small_sig` result can report the reduced jacobian for ``\delta`` and ``\omega``,

small_sig.reduced_jacobian

# and can also be used to report the eigenvalues of the reduced linearized system:

small_sig.eigenvalues
