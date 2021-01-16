using SIIPExamples
using Dates

base_dir = PowerSystems.download(PowerSystems.TestData; branch = "master");
sys = System(joinpath(base_dir, "matpower", "RTS_GMLC.m"))
tsp = joinpath(base_dir, "RTS_GMLC", "timeseries_pointers.json")
add_time_series!(sys, tsp, resolution = Hour(1))

transform_single_time_series!(sys, 2, Hour(1))

using Ipopt
solver = optimizer_with_attributes(Ipopt.Optimizer)

devices = Dict(
        :Generators => DeviceModel(ThermalStandard, ThermalDispatch),
        :Ren => DeviceModel(RenewableDispatch, RenewableFullDispatch),
        :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
        #:HydroROR => DeviceModel(HydroDispatch, HydroDispatchRunOfRiver),
        #:Hydro => DeviceModel(HydroEnergyReservoir, FixedOutput),
        #:RenFx => DeviceModel(RenewableFix, FixedOutput),
    )
ed_template = template_economic_dispatch(network = ACPPowerModel, devices = devices)

#ed_template.devices[:Hydro] = DeviceModel(HydroEnergyReservoir, HydroDispatchRunOfRiver)

loads = get_components(PowerLoad, sys)
timerange = range(
    get_forecast_initial_timestamp(sys),
    step = get_time_series_resolution(sys),
    stop =  get_forecast_initial_timestamp(sys) + get_forecast_total_period(sys)
    )

load_ts = []
for (ix, load) in enumerate(loads)
    push!(load_ts, get_time_series_values(SingleTimeSeries, load, "max_active_power"))
end
load_ts = Matrix(hcat(load_ts...))
(peak_load, hour_id) = findmax(sum(load_ts, dims = 2))

peak_time = timerange[hour_id,1]

problem = OperationsProblem(
    EconomicDispatchProblem,
    ed_template,
    sys,
    horizon = 1,
    optimizer = solver,
    balance_slack_variables = false,
    initial_time = peak_time
)

solve!(problem)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

