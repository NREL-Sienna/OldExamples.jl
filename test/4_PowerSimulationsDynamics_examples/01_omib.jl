#! format: off

using SIIPExamples #hide
using PowerSimulationsDynamics
using PowerSystems
using Sundials
using Plots
gr()
PSD = PowerSimulationsDynamics

file_dir = joinpath(
    pkgdir(SIIPExamples),
    "script",
    "4_PowerSimulationsDynamics_examples",
    "Data",
)
omib_sys = System(joinpath(file_dir, "omib_sys.json"))

time_span = (0.0, 30.0)
perturbation_trip = BranchTrip(1.0, Line, "BUS 1-BUS 2-i_1")
sim = PSD.Simulation(ResidualModel, omib_sys, pwd(), time_span, perturbation_trip)

show_states_initial_value(sim)

x0_init = PSD.get_initial_conditions(sim)

PSD.execute!(
    sim, #simulation structure
    IDA(), #Sundials DAE Solver
    dtmax = 0.02,
); #Arguments: Maximum timestep allowed

results = read_results(sim)

angle = get_state_series(results, ("generator-102-1", :δ));
plot(angle, xlabel = "time", ylabel = "rotor angle [rad]", label = "rotor angle")

volt = get_voltage_magnitude_series(results, 102);
plot(volt, xlabel = "time", ylabel = "Voltage [pu]", label = "V_2")

sim2 = PSD.Simulation(ResidualModel, omib_sys, pwd(), time_span)

small_sig = small_signal_analysis(sim2)

small_sig.reduced_jacobian

small_sig.eigenvalues

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
