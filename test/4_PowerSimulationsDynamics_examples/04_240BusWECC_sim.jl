#! format: off
#[PSSE 240 Bus Case system with Renewables](https://www.nrel.gov/grid/test-case-repository.html)

using PowerSimulationsDynamics
using PowerSystemCaseBuilder
using PowerSystems
using Sundials
using Plots
using OrdinaryDiffEq

sys = build_system(PSSETestSystems, "psse_240_case_renewable_sys")

using Logging
sim_ida = Simulation(
    ResidualModel,
    sys, #system
    pwd(),
    (0.0, 20.0), #time span
    BranchTrip(1.0, Line, "CORONADO    -1101-PALOVRDE    -1401-i_10");
    console_level = Logging.Info,
)

execute!(sim_ida, IDA(), dtmax = 0.01)

res_ida = read_results(sim_ida)
v1101_ida = get_voltage_magnitude_series(res_ida, 1101);
plot(v1101_ida)

sim_rodas = Simulation(
    MassMatrixModel,
    sys, #system
    pwd(),
    (0.0, 20.0), #time span
    BranchTrip(1.0, Line, "CORONADO    -1101-PALOVRDE    -1401-i_10");
    console_level = Logging.Info,
)

execute!(
    sim_rodas,
    Rodas4(),
    saveat = 0.01,
    atol = 1e-10,
    rtol = 1e-10,
    initializealg = NoInit(),
)

res_rodas = read_results(sim_rodas)

v1101 = get_voltage_magnitude_series(res_rodas, 1101);
plot(v1101, label = "RODAS4")
plot!(v1101_ida, label = "IDA")

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
