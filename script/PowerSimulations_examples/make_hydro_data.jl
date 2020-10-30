# This script is intended to be a dependency for the hydropower example.
using PowerSystems
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
c_sys5_hy_uc = System(
    rawsys,
    timeseries_metadata_file = joinpath(
        data_dir,
        "forecasts",
        "5bus_ts",
        "7day",
        "timeseries_pointers_da_7day.json",
    ),
    time_series_in_memory = true,
)
transform_single_time_series!(c_sys5_hy_uc, 24, Hour(24))

c_sys5_hy_ed = System(
    rawsys,
    timeseries_metadata_file = joinpath(
        data_dir,
        "forecasts",
        "5bus_ts",
        "7day",
        "timeseries_pointers_rt_7day.json",
    ),
    time_series_in_memory = true,
)
transform_single_time_series!(c_sys5_hy_ed, 12, Hour(1))

c_sys5_hy_wk = System(rawsys, time_series_in_memory = true)


n = 3# number of days

# And an hourly system with longer time scales
MultiDay = collect(
    get_forecast_initial_times(c_sys5_hy_uc)[1]:Hour(24):(get_forecast_initial_times(
        c_sys5_hy_uc,
    )[1]+Day(n)),
);


for load in get_components(PowerLoad, c_sys5_hy_uc)
    fc_values =Vector{Float64}()
    for t in MultiDay
        fc = get_time_series_array(
            Deterministic,
            load,
            "max_active_power";
            start_time = t,
        )
        push!(fc_values, mean(values(fc)))
    end
    wk_fc = TimeArray(MultiDay, fc_values)

    add_time_series!(
        c_sys5_hy_wk,
        get_component(PowerLoad, c_sys5_hy_wk, get_name(load)),
        SingleTimeSeries("max_active_power", wk_fc),
    )
end

for gen in get_components(HydroGen, c_sys5_hy_uc)
    fc_values =Vector{Float64}()
    for t in MultiDay
        fc = get_time_series_array(
            Deterministic,
            gen,
            "max_active_power";
            start_time = t,
        )
        push!(fc_values, mean(values(fc)))
    end

    wk_fc = TimeArray(MultiDay, fc_values)

    add_time_series!(
        c_sys5_hy_wk,
        get_component(HydroGen, c_sys5_hy_wk, get_name(gen)),
        SingleTimeSeries("max_active_power", wk_fc),
    )
end

for gen in get_components(HydroEnergyReservoir, c_sys5_hy_uc)
    for label in ["storage_capacity", "inflow", "storage_target"]
        fc_values = Vector{Float64}()
        for t in MultiDay
            fc = get_time_series_array(
                Deterministic,
                gen,
                label;
                start_time = get_forecast_initial_times(c_sys5_hy_uc)[1],
            )
            push!(fc_values, mean(values(fc)))
        end

        wk_fc = TimeArray(MultiDay, fc_values)

        add_time_series!(
            c_sys5_hy_wk,
            get_component(HydroGen, c_sys5_hy_wk, get_name(gen)),
            SingleTimeSeries(label, wk_fc),
        )
    end
end
transform_single_time_series!(c_sys5_hy_wk, 2, Hour(48))
