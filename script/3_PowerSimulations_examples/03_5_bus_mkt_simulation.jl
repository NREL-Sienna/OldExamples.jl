# # 5-bus Market simulation with [PowerSimulations.jl](https://github.com/NREL-SIIP/PowerSimulations.jl)

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# PowerSimulations.jl supports simulations that consist of sequential optimization problems
# where results from previous problems inform subsequent problems in a variety of ways. This
# example demonstrates some of these capabilities to represent electricity market clearing.

# ## Dependencies and Data
# First, let's create `System`s to represent the Day-Ahead and Real-Time market clearing
# process with hourly, and 5-minute time series data, respectively.

# ### Modeling Packages
using PowerSystems
using PowerSimulations
const PSI = PowerSimulations
IS = PowerSystems.IS

# ### Data management packages
using Dates
using DataFrames

# ### Optimization packages
using Cbc # mip solver
solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 1, "ratioGap" => 0.5)
using Ipopt # solver that supports duals
ipopt_solver = optimizer_with_attributes(Ipopt.Optimizer)

# ### 5-bus Data
# The five bus system data here includes hourly day-ahead data, 5-minute real-time market
# data, and 6-second actual data. We'll only use the hourly and 5-minute data for the
# example simulations below, but the 6-second data is included for future development.
base_dir = PowerSystems.download(PowerSystems.TestData; branch = "master");
pm_data = PowerSystems.PowerModelsData(joinpath(base_dir, "matpower", "case5_re_uc.m"))

FORECASTS_DIR = joinpath(base_dir, "forecasts", "5bus_ts", "7day")

tsp_da = IS.read_time_series_file_metadata(
    joinpath(FORECASTS_DIR, "timeseries_pointers_da_7day.json"),
)
tsp_rt = IS.read_time_series_file_metadata(
    joinpath(FORECASTS_DIR, "timeseries_pointers_rt_7day.json"),
)
tsp_agc = IS.read_time_series_file_metadata(
    joinpath(FORECASTS_DIR, "timeseries_pointers_agc_7day.json"),
)

sys_DA = System(pm_data)
reserves = [
    VariableReserve{ReserveUp}("REG1", true, 5.0, 0.1),
    VariableReserve{ReserveUp}("REG2", true, 5.0, 0.06),
    VariableReserve{ReserveUp}("REG3", true, 5.0, 0.03),
    VariableReserve{ReserveUp}("REG4", true, 5.0, 0.02),
]
contributing_devices = get_components(Generator, sys_DA)
for r in reserves
    add_service!(sys_DA, r, contributing_devices)
end

add_time_series!(sys_DA, tsp_da)
transform_single_time_series!(sys_DA, 48, Hour(24))

sys_RT = System(pm_data)
add_time_series!(sys_RT, tsp_rt)
transform_single_time_series!(sys_RT, 12, Hour(1))

sys_AGC = System(pm_data)
add_time_series!(sys_AGC, tsp_agc)

# ## `OperationsProblemTemplate`s

template_uc = template_unit_commitment()
devices = Dict(
    :Generators => DeviceModel(ThermalStandard, ThermalDispatch),
    :Ren => DeviceModel(RenewableDispatch, RenewableFullDispatch),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :HydroROR => DeviceModel(HydroDispatch, HydroDispatchRunOfRiver),
    :RenFx => DeviceModel(RenewableFix, FixedOutput),
)
template_ed = template_economic_dispatch(devices = devices)

# ### Define the Simulation Sequence

stages_definition = Dict(
    "UC" => Stage(
        GenericOpProblem,
        template_uc,
        sys_DA,
        solver,
        balance_slack_variables = true,
    ),
    "ED" => Stage(
        GenericOpProblem,
        template_ed,
        sys_RT,
        ipopt_solver,
        constraint_duals = [:CopperPlateBalance],
    ),
)

feedforward_chronologies = Dict(("UC" => "ED") => Synchronize(periods = 24))

feedforward = Dict(
    ("ED", :devices, :Generators) => SemiContinuousFF(
        binary_source_stage = PSI.ON,
        affected_variables = [PSI.ACTIVE_POWER],
    ),
)

cache = Dict("UC" => [TimeStatusChange(ThermalStandard, PSI.ON)])

order = Dict(1 => "UC", 2 => "ED")
horizons = Dict("UC" => 48, "ED" => 12)
intervals = Dict("UC" => (Hour(24), Consecutive()), "ED" => (Hour(1), Consecutive()))

DA_RT_sequence = SimulationSequence(
    step_resolution = Hour(24),
    order = order,
    horizons = horizons,
    intervals = intervals,
    ini_cond_chronology = InterStageChronology(),
    feedforward_chronologies = feedforward_chronologies,
    feedforward = feedforward,
)

# ## `Simulation`
file_path = mkpath(joinpath(".","5-bus-simulation"))
sim = Simulation(
    name = "5bus-test",
    steps = 1,
    stages = stages_definition,
    stages_sequence = DA_RT_sequence,
    simulation_folder = file_path,
)

# ### Build simulation

build!(sim)

# ### Execute simulation

execute!(sim)

# ## Results
# First we can load the result metadata
results = SimulationResults(sim)
uc_results = get_stage_results(results, "UC")
ed_results = get_stage_results(results, "ED");

# Then we can read and examine the results of interest

prices = read_dual(ed_results, :CopperPlateBalance)

# or if we want to look at the realized values

read_realized_duals(ed_results)[:CopperPlateBalance]

# *note that in this simulation the prices are all equal to the balance slack
# penalty value of $100000/MWh because there is unserved energy in the result*
