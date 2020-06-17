# This script is intended to be a dependency for the hydropower example.
using PowerSystems
using PowerSimulations
const PSI = PowerSimulations
using Statistics

# We can use some of the simple data that's been assembled for testing PowerSimulations.
include(joinpath(pathof(PSI), "..", "..", "test", "test_utils", "get_test_data.jl"))

c_sys5_hy_uc = TEST_SYSTEMS["c_sys5_hy_uc"].build()
c_sys5_hy_ed = TEST_SYSTEMS["c_sys5_hy_ed"].build()

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
