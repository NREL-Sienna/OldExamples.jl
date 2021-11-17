#! format: off

using SIIPExamples #hide
using PowerSimulationsDynamics
using PowerSystems
using Sundials
using Plots
PSD = PowerSimulationsDynamics

file_dir = joinpath(
    dirname(dirname(pathof(SIIPExamples))),
    "script",
    "4_PowerSimulationsDynamics_examples",
    "Data",
)
threebus_sys = System(joinpath(file_dir, "threebus_sys.json"));

threebus_sys_dyn = deepcopy(threebus_sys);

#Make a copy of the original system
sys2 = deepcopy(threebus_sys)
#Triplicates the impedance of the line named "BUS 1-BUS 3-i_1"
fault_branches = get_components(ACBranch, sys2)
for br in fault_branches
    if get_name(br) == "BUS 1-BUS 3-i_1"
        br.r = 3 * br.r
        br.x = 3 * br.x
        b_new = (from = br.b.from / 3, to = br.b.to / 3)
        br.b = b_new
    end
end
#Obtain the new Ybus
Ybus_fault = Ybus(sys2).data
#Define Fault: Change of YBus
Ybus_change = NetworkSwitch(
    1.0, #change at t = 1.0
    Ybus_fault, #New YBus
);

#Time span of our simulation
tspan = (0.0, 30.0)

#Define Simulation
sim = Simulation(
    ResidualModel, #Type of model used
    threebus_sys, #system
    pwd(), #folder to output results
    tspan, #time span
    Ybus_change, #Type of perturbation
)

#Will print the initial states. It also give the symbols used to describe those states.
show_states_initial_value(sim)

#Will export a dictionary with the initial condition values to explore
x0_init = PSD.get_initial_conditions(sim)

#Run the simulation
execute!(
    sim, #simulation structure
    IDA(), #Sundials DAE Solver
    dtmax = 0.02, #Maximum step size
)

results = read_results(sim)
series2 = get_voltage_magnitude_series(results, 102)
zoom = [
    (series2[1][ix], series2[2][ix]) for
    (ix, s) in enumerate(series2[1]) if (s > 0.90 && s < 1.6)
];

dyn_branch = DynamicBranch(get_component(Branch, threebus_sys_dyn, "BUS 2-BUS 3-i_3"))

add_component!(threebus_sys_dyn, dyn_branch)

#Make a copy of the original system
sys3 = deepcopy(threebus_sys);
#Remove Line "BUS 2-BUS 3-i_3"
remove_component!(Line, sys3, "BUS 2-BUS 3-i_3")
#Triplicates the impedance of the line named "BUS 1-BUS 2-i_1"
fault_branches2 = get_components(Line, sys3)
for br in fault_branches2
    if get_name(br) == "BUS 1-BUS 3-i_1"
        br.r = 3 * br.r
        br.x = 3 * br.x
        b_new = (from = br.b.from / 3, to = br.b.to / 3)
        br.b = b_new
    end
end
#Obtain the new Ybus
Ybus_fault_dyn = Ybus(sys3).data
#Define Fault: Change of YBus
Ybus_change_dyn = NetworkSwitch(
    1.0, #change at t = 1.0
    Ybus_fault_dyn, #New YBus
)

sim_dyn = Simulation(
    ResidualModel, #Type of model used
    threebus_sys_dyn, #system
    pwd(), #folder to output results
    (0.0, 30.0), #time span
    Ybus_change_dyn, #Type of perturbation
)

execute!(
    sim_dyn, #simulation structure
    IDA(), #Sundials DAE Solver
    dtmax = 0.02, #Maximum step size
)

#Will print the initial states. It also give the symbols used to describe those states.
show_states_initial_value(sim_dyn)
#Will export a dictionary with the initial condition values to explore
x0_init_dyn = PSD.get_initial_conditions(sim_dyn)

results_dyn = read_results(sim_dyn)
series2_dyn = get_voltage_magnitude_series(results_dyn, 102)
zoom_dyn = [
    (series2_dyn[1][ix], series2_dyn[2][ix]) for
    (ix, s) in enumerate(series2_dyn[1]) if (s > 0.90 && s < 1.6)
];

plot(series2_dyn, label = "V_gen_dyn")
plot!(series2, label = "V_gen_st", xlabel = "Time [s]", ylabel = "Voltage [pu]")

plot(zoom_dyn, label = "V_gen_dyn")
plot!(zoom, label = "V_gen_st", xlabel = "Time [s]", ylabel = "Voltage [pu]")

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

