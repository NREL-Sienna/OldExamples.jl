# This script is intended to be a dependency for the hydropower example.
using PowerSystems
using PowerSimulations
const PSI = PowerSimulations
using Statistics
using Dates
using TimeSeries

# We can use some of the simple data that's been assembled for testing PowerSimulations.
PowerSystems.download(PowerSystems.TestData; branch = "master") # *note* add `force=true` to get a fresh copy
data_dir = joinpath(dirname(dirname(pathof(PowerSystems))), "data");

rawsys = PowerSystems.PowerSystemTableData(
    joinpath(data_dir, "5-bus-hydro"),
    100.0,
    joinpath(data_dir, "5-bus-hydro", "user_descriptors.yaml");
    generator_mapping_file = joinpath(data_dir, "5-bus-hydro", "generator_mapping.yaml"),
)
c_sys5_hy_uc = System(rawsys, timeseries_metadata_file = joinpath(data_dir, "forecasts", "5bus_ts", "7day", "timeseries_pointers_da_7day.json"), time_series_in_memory = true)
c_sys5_hy_ed = System(rawsys, timeseries_metadata_file = joinpath(data_dir, "forecasts", "5bus_ts", "7day", "timeseries_pointers_rt_7day.json"), time_series_in_memory = true)
c_sys5_hy_wk = System(rawsys, time_series_in_memory = true)


n = 3# number of days

# And an hourly system with longer time scales
MultiDay = collect(
    get_forecast_initial_times(c_sys5_hy_uc)[1]:Hour(24):(get_forecast_initial_times(c_sys5_hy_uc)[1] + Day(n))
);


for load in get_components(PowerLoad, c_sys5_hy_uc)
    fc = get_forecast_values(Deterministic, load, get_forecast_initial_times(c_sys5_hy_uc)[1], "get_max_active_power")
    fc_values = []
    for (ix, t) in enumerate(MultiDay)
        push!(fc_values, mean(values(fc[Date.(timestamp(fc)) .== t])))
    end
    wk_fc = TimeArray(MultiDay, fc_values)

    add_forecast!(
        c_sys5_hy_wk,
        get_component(PowerLoad, c_sys5_hy_wk, get_name(load)),
        Deterministic("get_max_active_power", wk_fc),
    )
end

for gen in get_components(HydroGen, c_sys5_hy_uc)
    fc = get_forecast_values(Deterministic, gen, get_forecast_initial_times(c_sys5_hy_uc)[1], "get_max_active_power")
    fc_values = []
    for (ix, t) in enumerate(MultiDay)
        push!(fc_values, mean(values(fc[Date.(timestamp(fc)) .== t])))
    end
    wk_fc = TimeArray(MultiDay, fc_values)

    add_forecast!(
        c_sys5_hy_wk,
        get_component(HydroGen, c_sys5_hy_wk, get_name(gen)),
        Deterministic("get_max_active_power", wk_fc),
    )
end

for gen in get_components(HydroEnergyReservoir, c_sys5_hy_uc)
    for label in ["get_storage_capacity", "get_inflow"]
        fc = get_forecast_values(Deterministic, gen, get_forecast_initial_times(c_sys5_hy_uc)[1], label)
        fc_values = []
        for (ix, t) in enumerate(MultiDay)
            push!(fc_values, mean(values(fc[Date.(timestamp(fc)) .== t])))
        end
        wk_fc = TimeArray(MultiDay, fc_values)

        add_forecast!(
            c_sys5_hy_wk,
            get_component(HydroGen, c_sys5_hy_wk, get_name(gen)),
            Deterministic(label, wk_fc),
        )
    end
end

#=
load_timeseries_WK = [
    [
        TimeArray(
            MultiDay,
            repeat([mean(loadbus2_ts_DA[1:24])], inner = n) + rand(n) * 0.1,
        ),
        TimeArray(
            MultiDay,
            repeat([mean(loadbus3_ts_DA[1:24])], inner = n) + rand(n) * 0.1,
        ),
        TimeArray(
            MultiDay,
            repeat([mean(loadbus4_ts_DA[1:24])], inner = n) + rand(n) * 0.1,
        ),
    ],
    [
        TimeArray(
            MultiDay + Day(n),
            repeat([mean(loadbus2_ts_DA[1:24])], inner = n) + rand(n) * 0.1,
        ),
        TimeArray(
            MultiDay + Day(n),
            repeat([mean(loadbus3_ts_DA[1:24])], inner = n) + rand(n) * 0.1,
        ),
        TimeArray(
            MultiDay + Day(n),
            repeat([mean(loadbus4_ts_DA[1:24])], inner = n) + rand(n) * 0.1,
        ),
    ],
]

hydro_dispatch_timeseries_WK = [
    [TimeArray(MultiDay, repeat([mean(wind_ts_DA[1:24])], inner = n) + rand(n) * 0.1)],
    [TimeArray(
        MultiDay + Day(n),
        repeat([mean(wind_ts_DA[1:24])], inner = n) + rand(n) * 0.1,
    )],
]

c_sys5_hy_wk = TEST_SYSTEMS["c_sys5_hy_uc"].build()
clear_forecasts!(c_sys5_hy_wk)

for t in 1:1
    for (ix, l) in enumerate(get_components(PowerLoad, c_sys5_hy_wk))
        add_forecast!(
            c_sys5_hy_wk,
            l,
            Deterministic("get_maxactivepower", load_timeseries_WK[t][ix]),
        )
    end
    for h in get_components(HydroEnergyReservoir, c_sys5_hy_wk)
        add_forecast!(
            c_sys5_hy_wk,
            h,
            Deterministic("get_rating", hydro_dispatch_timeseries_WK[t][1]),
        )
    end
    for h in get_components(HydroEnergyReservoir, c_sys5_hy_wk)
        add_forecast!(
            c_sys5_hy_wk,
            h,
            Deterministic(
                "get_storage_capacity",
                2.0 .* hydro_dispatch_timeseries_WK[t][1],
            ),
        )
    end
    for h in get_components(HydroEnergyReservoir, c_sys5_hy_wk)
        add_forecast!(
            c_sys5_hy_wk,
            h,
            Deterministic("get_inflow", hydro_dispatch_timeseries_WK[t][1] .* 100.0),
        )
    end
end
=#