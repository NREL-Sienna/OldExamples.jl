# This script is intended to be a dependency for the hydropower example.
using InfrastructureSystems
const IS = InfrastructureSystems
using PowerSystems
const PSY = PowerSystems
using PowerSimulations
const PSI = PowerSimulations
using Statistics

# We can use some of the simple data that's been assembled for testing PowerSimulations.
include(joinpath(pathof(PSI), "..", "..", "test", "test_utils", "get_test_data.jl"))

# Additionally, let's add two hydro generators. One of each type supported by PowerSystems.
hydro_generators5(nodes5) = [
    HydroDispatch(
        "HydroDispatch",
        true,
        nodes5[2],
        0.0,
        0.0,
        TechHydro(
            2.0,
            PSY.PrimeMovers.HY,
            (min = 0.5, max = 2.0),
            (min = -2.0, max = 2.0),
            nothing,
            nothing,
        ),
    ),
    HydroEnergyReservoir(
        "HydroEnergyReservoir",
        true,
        nodes5[3],
        0.0,
        0.0,
        TechHydro(
            18.1,
            PSY.PrimeMovers.HY,
            (min = 3.0, max = 18.1),
            (min = -18.1, max = 18.1),
            (up = 5.0, down = 5.0),
            nothing,
        ),
        TwoPartCost(15.0, 0.0),
        10.0,
        2.0,
        5.0,
    ),
];

# We can add some random time series information too.

hydro_timeseries_DA = [
    [TimeArray(DayAhead, wind_ts_DA)],
    [TimeArray(DayAhead + Day(1), wind_ts_DA)],
];


hydro_timeseries_RT = [
    [TimeArray(RealTime, repeat(wind_ts_DA, inner = 12))],
    [TimeArray(RealTime + Day(1), repeat(wind_ts_DA, inner = 12))],
];

hydro_load_timeseries_DA = [
    repeat([TimeArray(DayAhead, ones(length(DayAhead)))],
        length(get_components(PowerLoad,c_sys5_hy))),
    repeat([TimeArray(DayAhead + Day(1), ones(length(DayAhead)))],
        length(get_components(PowerLoad,c_sys5_hy)))
];

# Now we can create a system with hourly resolution and add forecast data to it.

c_sys5_hy = System(
    nodes,
    vcat(
        thermal_generators5_uc_testing(nodes),
        hydro_generators5(nodes),
        renewable_generators5(nodes),
    ),
    loads5(nodes),
    branches5(nodes),
    nothing,
    100.0,
    nothing,
    nothing,
)

for t = 1:2
    for (ix, l) in enumerate(get_components(PowerLoad, c_sys5_hy))
        add_forecast!(
            c_sys5_hy,
            l,
            Deterministic("get_maxactivepower", hydro_load_timeseries_DA[t][ix]),
        )
    end
    for (ix, h) in enumerate(get_components(HydroEnergyReservoir, c_sys5_hy))
        add_forecast!(
            c_sys5_hy,
            h,
            Deterministic("get_rating", hydro_timeseries_DA[t][ix]),
        )
    end
    for (ix, h) in enumerate(get_components(HydroEnergyReservoir, c_sys5_hy))
        add_forecast!(
            c_sys5_hy,
            h,
            Deterministic("get_storage_capacity", 2.0 .* hydro_timeseries_DA[t][ix]),
        )
    end
    for (ix, h) in enumerate(get_components(HydroEnergyReservoir, c_sys5_hy))
        add_forecast!(
            c_sys5_hy,
            h,
            Deterministic("get_inflow", hydro_timeseries_DA[t][ix]),
        )
    end
    for (ix, h) in enumerate(get_components(HydroDispatch, c_sys5_hy))
        add_forecast!(c_sys5_hy, h, Deterministic("get_rating", hydro_timeseries_DA[t][ix]))
    end
    for (ix, r) in enumerate(get_components(RenewableGen, c_sys5_hy))
        add_forecast!(c_sys5_hy, r, Deterministic("get_rating", ren_timeseries_DA[t][ix]))
    end
    for (ix, i) in enumerate(get_components(InterruptibleLoad, c_sys5_hy))
        add_forecast!(
            c_sys5_hy,
            i,
            Deterministic("get_maxactivepower", Iload_timeseries_DA[t][ix]),
        )
    end
end

c_sys5_hy_uc = System(
    nodes,
    vcat(
        thermal_generators5_uc_testing(nodes),
        hydro_generators5(nodes),
        renewable_generators5(nodes),
    ),
    loads5(nodes),
    branches5(nodes),
    nothing,
    100.0,
    nothing,
    nothing,
)

for t = 1:2
    for (ix, l) in enumerate(get_components(PowerLoad, c_sys5_hy_uc))
        add_forecast!(
        c_sys5_hy_uc,
            l,
            Deterministic("get_maxactivepower", load_timeseries_DA[t][ix]),
        )
    end
    for (ix, h) in enumerate(get_components(HydroEnergyReservoir, c_sys5_hy_uc))
        add_forecast!(
        c_sys5_hy_uc,
            h,
            Deterministic("get_rating", hydro_timeseries_DA[t][ix]),
        )
    end
    for (ix, h) in enumerate(get_components(HydroEnergyReservoir, c_sys5_hy_uc))
        add_forecast!(
        c_sys5_hy_uc,
            h,
            Deterministic("get_storage_capacity", 2.0 .* hydro_timeseries_DA[t][ix]),
        )
    end
    for (ix, h) in enumerate(get_components(HydroEnergyReservoir, c_sys5_hy_uc))
        add_forecast!(
        c_sys5_hy_uc,
            h,
            Deterministic("get_inflow", hydro_timeseries_DA[t][ix]),
        )
    end
    for (ix, h) in enumerate(get_components(HydroDispatch, c_sys5_hy_uc))
        add_forecast!(c_sys5_hy_uc, h, Deterministic("get_rating", hydro_timeseries_DA[t][ix]))
    end
    for (ix, r) in enumerate(get_components(RenewableGen, c_sys5_hy_uc))
        add_forecast!(c_sys5_hy_uc, r, Deterministic("get_rating", ren_timeseries_DA[t][ix]))
    end
    for (ix, i) in enumerate(get_components(InterruptibleLoad, c_sys5_hy_uc))
        add_forecast!(
        c_sys5_hy_uc,
            i,
            Deterministic("get_maxactivepower", Iload_timeseries_DA[t][ix]),
        )
    end
end

# And we can make system with 5-minute resolution

c_sys5_hy_ed = System(
    nodes,
    vcat(
        thermal_generators5_uc_testing(nodes),
        hydro_generators5(nodes),
        renewable_generators5(nodes),
    ),
    vcat(loads5(nodes), interruptible(nodes)),
    branches5(nodes),
    nothing,
    100.0,
    nothing,
    nothing,
)
for t = 1:2
    for (ix, l) in enumerate(get_components(PowerLoad, c_sys5_hy_ed))
        ta = load_timeseries_DA[t][ix]
        for i = 1:length(ta) # loop over hours
            ini_time = timestamp(ta[i]) # get the hour
            data = when(load_timeseries_RT[t][ix], hour, hour(ini_time[1])) # get the subset ts for that hour
            add_forecast!(c_sys5_hy_ed, l, Deterministic("get_maxactivepower", data))
        end
    end
    for (ix, l) in enumerate(get_components(HydroEnergyReservoir, c_sys5_hy_ed))
        ta = hydro_timeseries_DA[t][ix]
        for i = 1:length(ta) # loop over hours
            ini_time = timestamp(ta[i]) # get the hour
            data = when(hydro_timeseries_RT[t][ix], hour, hour(ini_time[1])) # get the subset ts for that hour
            add_forecast!(c_sys5_hy_ed, l, Deterministic("get_rating", data))
        end
    end
    for (ix, l) in enumerate(get_components(RenewableGen, c_sys5_hy_ed))
        ta = load_timeseries_DA[t][ix]
        for i = 1:length(ta) # loop over hours
            ini_time = timestamp(ta[i]) # get the hour
            data = when(load_timeseries_RT[t][ix], hour, hour(ini_time[1])) # get the subset ts for that hour
            add_forecast!(c_sys5_hy_ed, l, Deterministic("get_rating", data))
        end
    end
    for (ix, l) in enumerate(get_components(HydroEnergyReservoir, c_sys5_hy_ed))
        ta = 2.0 .* hydro_timeseries_DA[t][ix]
        for i = 1:length(ta) # loop over hours
            ini_time = timestamp(ta[i]) # get the hour
            data = when(hydro_timeseries_RT[t][ix], hour, hour(ini_time[1])) # get the subset ts for that hour
            add_forecast!(c_sys5_hy_ed, l, Deterministic("get_storage_capacity", data))
        end
    end
    for (ix, l) in enumerate(get_components(InterruptibleLoad, c_sys5_hy_ed))
        ta = load_timeseries_DA[t][ix]
        for i = 1:length(ta) # loop over hours
            ini_time = timestamp(ta[i]) # get the hour
            data = when(load_timeseries_RT[t][ix], hour, hour(ini_time[1])) # get the subset ts for that hour
            add_forecast!(c_sys5_hy_ed, l, Deterministic("get_maxactivepower", data))
        end
    end
    for (ix, l) in enumerate(get_components(HydroDispatch, c_sys5_hy_ed))
        ta = hydro_timeseries_DA[t][ix]
        for i = 1:length(ta) # loop over hours
            ini_time = timestamp(ta[i]) # get the hour
            data = when(hydro_timeseries_RT[t][ix], hour, hour(ini_time[1])) # get the subset ts for that hour
            add_forecast!(c_sys5_hy_ed, l, Deterministic("get_rating", data))
        end
    end
end

# And an hourly system with longer time scales
MultiDay = collect(
    DateTime("1/1/2024  0:00:00", "d/m/y  H:M:S"):Hour(24):DateTime(
        "3/1/2024  00:00:00",
        "d/m/y  H:M:S",
    ),
);

n = 3# number of days
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

c_sys5_hy_wk = System(
    nodes,
    vcat(
        thermal_generators5_uc_testing(nodes),
        hydro_generators5(nodes),
        renewable_generators5(nodes),
    ),
    loads5(nodes),
    branches5(nodes),
    nothing,
    100.0,
    nothing,
    nothing,
)
for t = 1:1
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
            Deterministic("get_storage_capacity", 2.0 .* hydro_dispatch_timeseries_WK[t][1]),
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
