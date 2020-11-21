using SIIPExamples # Only needed for the tutorial
import DisplayAs # Only needed for the tutorial
using PowerSimulationsDynamics
using PowerSystems
using Logging
using Sundials
using Plots
gr()

file_dir = joinpath(#hide
    dirname(dirname(pathof(SIIPExamples))),#hide
    "script",#hide
    "4_PowerSimulationsDynamics_examples",#hide
    "Data",#hide
)#hide

sys = System(joinpath(file_dir, "14bus.raw"), joinpath(file_dir, "dyn_data.dyr"))

sim = Simulation(
	file_dir ,       #path for the simulation output
	sys,         #system
	(0.0, 20.0), #time span
	BranchTrip(1.0, "BUS 02-BUS 04-i_4");
    console_level = Logging.Info
)

print_device_states(sim)

execute!(sim, IDA(); abstol = 1e-8)

p = plot()
for b in get_components(Bus, sys)
    voltage_series = get_voltagemag_series(sim, get_number(b))
    plot!(p, voltage_series; xlabel = "Time",
                             ylabel = "Voltage Magnitude [pu]",
                             label = "Bus - $(get_name(b))")
end
img = DisplayAs.PNG(p) # This line is only needed because of literate

p2 = plot()
for g in get_components(ThermalStandard, sys)
    state_series = get_state_series(sim, (get_name(g), :ω));
    plot!(p2, state_series; xlabel = "Time",
                            ylabel = "Speed [pu]",
                            label = "$(get_name(g)) - ω")
end
img = DisplayAs.PNG(p2) # This line is only needed because of literate

res = small_signal_analysis(sim; reset_simulation = true)

scatter(res.eigenvalues; legend = false)

sys = System(joinpath(file_dir, "14bus.raw"), joinpath(file_dir, "dyn_data.dyr"))

thermal_gen = get_component(ThermalStandard, sys, "generator-6-1")
remove_component!(sys, get_dynamic_injector(thermal_gen))
remove_component!(sys, thermal_gen)

storage = GenericBattery(name = "Battery",
                         bus = get_component(Bus, sys, "BUS 06"),
                         available = true,
                         prime_mover = PrimeMovers.BA,
                         active_power = 0.6,
                         reactive_power = 0.16,
                         rating = 1.1,
                         base_power = 25.0,
                         initial_energy = 50.0,
                         state_of_charge_limits = (min = 5.0, max = 100.0),
                         input_active_power_limits = (min = 0.0, max = 1.0),
                         output_active_power_limits = (min = 0.0, max = 1.0),
                         reactive_power_limits = (min = -1.0, max = 1.0),
                         efficiency = (in = 0.80, out = 0.90),
                         )

add_component!(sys, storage)

res = solve_powerflow(sys)
res["bus_results"]

inverter = DynamicInverter(
        name = get_name(storage),
        ω_ref = 1.0, # ω_ref,
        converter = AverageConverter(rated_voltage = 138.0, rated_current = 100.0),
        outer_control = OuterControl(
                            VirtualInertia(Ta = 2.0, kd = 400.0, kω = 20.0),
                            ReactivePowerDroop(kq = 0.2, ωf = 1000.0)
                    ),
        inner_control =  CurrentControl(
                            kpv = 0.59,     #Voltage controller proportional gain
                            kiv = 736.0,    #Voltage controller integral gain
                            kffv = 0.0,     #Binary variable enabling the voltage feed-forward in output of current controllers
                            rv = 0.0,       #Virtual resistance in pu
                            lv = 0.2,       #Virtual inductance in pu
                            kpc = 1.27,     #Current controller proportional gain
                            kic = 14.3,     #Current controller integral gain
                            kffi = 0.0,     #Binary variable enabling the current feed-forward in output of current controllers
                            ωad = 50.0,     #Active damping low pass filter cut-off frequency
                            kad = 0.2,
                        ),
        dc_source = FixedDCSource(voltage = 600.0),
        freq_estimator = KauraPLL(
                        ω_lp = 500.0, #Cut-off frequency for LowPass filter of PLL filter.
                        kp_pll = 0.084,  #PLL proportional gain
                        ki_pll = 4.69,   #PLL integral gain
                            ),
        filter = LCLFilter(lf = 0.08, rf = 0.003, cf = 0.074, lg = 0.2, rg = 0.01)
    )
add_component!(sys, inverter, storage)

sys

sim = Simulation(
	file_dir ,       #path for the simulation output
	sys,         #system
	(0.0, 20.0), #time span
	BranchTrip(1.0, "BUS 02-BUS 04-i_4");
    console_level = Logging.Info
)

res = small_signal_analysis(sim);

scatter(res.eigenvalues)

execute!(sim, IDA())

p = plot()
for b in get_components(Bus, sys)
    voltage_series = get_voltagemag_series(sim, get_number(b))
    plot!(p, voltage_series; xlabel = "Time",
                             ylabel = "Voltage Magnitude [pu]",
                             label = "Bus - $(get_name(b))")
end
img = DisplayAs.PNG(p) # This line is only needed because of literate

p2 = plot()
for g in get_components(ThermalStandard, sys)
    state_series = get_state_series(sim, (get_name(g), :ω));
    plot!(p2, state_series; xlabel = "Time",
                            ylabel = "Speed [pu]",
                            label = "$(get_name(g)) - ω")
end
state_series = get_state_series(sim, ("Battery", :ω_oc));
plot!(p2, state_series; xlabel = "Time",
                        ylabel = "Speed [pu]",
                        label = "Battery - ω")
img = DisplayAs.PNG(p2) # This line is only needed because of literate

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

