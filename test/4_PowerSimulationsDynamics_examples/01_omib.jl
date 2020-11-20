using SIIPExamples
using PowerSimulationsDynamics
using PowerSystems
using Sundials
using Plots
gr()

file_dir = joinpath(
    dirname(dirname(pathof(SIIPExamples))),
    "script",
    "4_PowerSimulationsDynamics_examples",
    "Data",
)
omib_sys = System(joinpath(file_dir, "omib_sys.json"))

fault_branch = deepcopy(collect(get_components(Branch, omib_sys))[1])

fault_branch.x = fault_branch.x * 2

Ybus_fault = Ybus([fault_branch], get_components(Bus, omib_sys))[:, :]

perturbation_Ybus = NetworkSwitch(
    1.0, #change will occur at t = 1.0s
    Ybus_fault, #new Ybus
)

time_span = (0.0, 30.0)
sim = Simulation(pwd(), omib_sys, time_span, perturbation_Ybus)

print_device_states(sim)

x0_init = get_initial_conditions(sim)

execute!(
    sim, #simulation structure
    IDA(), #Sundials DAE Solver
    dtmax = 0.02,
); #Arguments: Maximum timestep allowed

sim.solution

angle = get_state_series(sim, ("generator-102-1", :δ));
Plots.plot(angle, xlabel = "time", ylabel = "rotor angle [rad]", label = "rotor angle")

volt = get_voltagemag_series(sim, 102);
Plots.plot(volt, xlabel = "time", ylabel = "Voltage [pu]", label = "V_2")

sim2 = Simulation(pwd(), omib_sys, time_span, perturbation_Ybus)

small_sig = small_signal_analysis(sim2)

small_sig.reduced_jacobian

small_sig.eigenvalues

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

