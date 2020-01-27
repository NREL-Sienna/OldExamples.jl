# This script is intended to be a dependency for the hydropower example. #src
using InfrastructureSystems #src
const IS = InfrastructureSystems #src
using PowerSystems #src
const PSY = PowerSystems #src
using PowerSimulations #src
const PSI = PowerSimulations #src
using Statistics #src
#src
# We can use some of the simple data that's been assembled for testing PowerSimulations. #src
include(joinpath(pathof(PSI), "../../test/test_utils/get_test_data.jl")) #src
#src
# Additionally, let's add two hydro generators. One of each type supported by PowerSystems. #src
hydro_generators5(nodes5) = [ #src
    HydroFix( #src
        "HydroFix", #src
        true, #src
        nodes5[2], #src
        0.0, #src
        0.0, #src
        TechHydro( #src
            2.0, #src
            PowerSystems.HY, #src
            (min = 0.5, max = 2.0), #src
            (min = -2.0, max = 2.0), #src
            nothing, #src
            nothing, #src
        ), #src
    ), #src
    HydroDispatch( #src
        "HydroDispatch", #src
        true, #src
        nodes5[3], #src
        0.0, #src
        0.0, #src
        TechHydro( #src
            10.1, #src
            PowerSystems.HY, #src
            (min = 3.0, max = 15.1), #src
            (min = -10.1, max = 15.1), #src
            (up = 5.0, down = 5.0), #src
            nothing, #src
        ), #src
        TwoPartCost(15.0, 0.0), #src
        10.0, #src
        2.0, #src
        5.0, #src
    ), #src
]; #src
#src
# We can add some random time series information too. #src
#src
hydro_timeseries_DA = [ #src
    [TimeArray(DayAhead, wind_ts_DA)], #src
    [TimeArray(DayAhead + Day(1), wind_ts_DA)], #src
]; #src
#src
#src
hydro_timeseries_RT = [ #src
    [TimeArray(RealTime, repeat(wind_ts_DA, inner = 12))], #src
    [TimeArray(RealTime + Day(1), repeat(wind_ts_DA, inner = 12))], #src
]; #src
#src
hydro_load_timeseries_DA = [ #src
    repeat([TimeArray(DayAhead, ones(length(DayAhead)))], #src
        length(get_components(PowerLoad,c_sys5_hy))), #src
    repeat([TimeArray(DayAhead + Day(1), ones(length(DayAhead)))], #src
        length(get_components(PowerLoad,c_sys5_hy))) #src
]; #src
#src
# Now we can create a system with hourly resolution and add forecast data to it. #src
#src
c_sys5_hy = System( #src
    nodes, #src
    vcat( #src
        thermal_generators5_uc_testing(nodes), #src
        hydro_generators5(nodes), #src
        renewable_generators5(nodes), #src
    ), #src
    loads5(nodes), #src
    branches5(nodes), #src
    nothing, #src
    100.0, #src
    nothing, #src
    nothing, #src
) #src
#src
for t = 1:2 #src
    for (ix, l) in enumerate(get_components(PowerLoad, c_sys5_hy)) #src
        add_forecast!( #src
            c_sys5_hy, #src
            l, #src
            Deterministic("get_maxactivepower", hydro_load_timeseries_DA[t][ix]), #src
        ) #src
    end #src
    for (ix, h) in enumerate(get_components(HydroDispatch, c_sys5_hy)) #src
        add_forecast!( #src
            c_sys5_hy, #src
            h, #src
            Deterministic("get_rating", hydro_timeseries_DA[t][ix]), #src
        ) #src
    end #src
    for (ix, h) in enumerate(get_components(HydroDispatch, c_sys5_hy)) #src
        add_forecast!( #src
            c_sys5_hy, #src
            h, #src
            Deterministic("get_storage_capacity", hydro_timeseries_DA[t][ix]), #src
        ) #src
    end #src
    for (ix, h) in enumerate(get_components(HydroDispatch, c_sys5_hy)) #src
        add_forecast!( #src
            c_sys5_hy, #src
            h, #src
            Deterministic("get_inflow", hydro_timeseries_DA[t][ix]), #src
        ) #src
    end #src
    for (ix, h) in enumerate(get_components(HydroFix, c_sys5_hy)) #src
        add_forecast!(c_sys5_hy, h, Deterministic("get_rating", hydro_timeseries_DA[t][ix])) #src
    end #src
    for (ix, r) in enumerate(get_components(RenewableGen, c_sys5_hy)) #src
        add_forecast!(c_sys5_hy, r, Deterministic("get_rating", ren_timeseries_DA[t][ix])) #src
    end #src
    for (ix, i) in enumerate(get_components(InterruptibleLoad, c_sys5_hy)) #src
        add_forecast!( #src
            c_sys5_hy, #src
            i, #src
            Deterministic("get_maxactivepower", Iload_timeseries_DA[t][ix]), #src
        ) #src
    end #src
end #src
#src
c_sys5_hy_uc = System( #src
    nodes, #src
    vcat( #src
        thermal_generators5_uc_testing(nodes), #src
        hydro_generators5(nodes), #src
        renewable_generators5(nodes), #src
    ), #src
    loads5(nodes), #src
    branches5(nodes), #src
    nothing, #src
    100.0, #src
    nothing, #src
    nothing, #src
) #src
#src
for t = 1:2 #src
    for (ix, l) in enumerate(get_components(PowerLoad, c_sys5_hy_uc)) #src
        add_forecast!( #src
        c_sys5_hy_uc, #src
            l, #src
            Deterministic("get_maxactivepower", load_timeseries_DA[t][ix]), #src
        ) #src
    end #src
    for (ix, h) in enumerate(get_components(HydroDispatch, c_sys5_hy_uc)) #src
        add_forecast!( #src
        c_sys5_hy_uc, #src
            h, #src
            Deterministic("get_rating", hydro_timeseries_DA[t][ix]), #src
        ) #src
    end #src
    for (ix, h) in enumerate(get_components(HydroDispatch, c_sys5_hy_uc)) #src
        add_forecast!( #src
        c_sys5_hy_uc, #src
            h, #src
            Deterministic("get_storage_capacity", hydro_timeseries_DA[t][ix]), #src
        ) #src
    end #src
    for (ix, h) in enumerate(get_components(HydroDispatch, c_sys5_hy_uc)) #src
        add_forecast!( #src
        c_sys5_hy_uc, #src
            h, #src
            Deterministic("get_inflow", hydro_timeseries_DA[t][ix]), #src
        ) #src
    end #src
    for (ix, h) in enumerate(get_components(HydroFix, c_sys5_hy_uc)) #src
        add_forecast!(c_sys5_hy_uc, h, Deterministic("get_rating", hydro_timeseries_DA[t][ix])) #src
    end #src
    for (ix, r) in enumerate(get_components(RenewableGen, c_sys5_hy_uc)) #src
        add_forecast!(c_sys5_hy_uc, r, Deterministic("get_rating", ren_timeseries_DA[t][ix])) #src
    end #src
    for (ix, i) in enumerate(get_components(InterruptibleLoad, c_sys5_hy_uc)) #src
        add_forecast!( #src
        c_sys5_hy_uc, #src
            i, #src
            Deterministic("get_maxactivepower", Iload_timeseries_DA[t][ix]), #src
        ) #src
    end #src
end #src
#src
# And we can make system with 5-minute resolution #src
#src
c_sys5_hy_ed = System( #src
    nodes, #src
    vcat( #src
        thermal_generators5_uc_testing(nodes), #src
        hydro_generators5(nodes), #src
        renewable_generators5(nodes), #src
    ), #src
    vcat(loads5(nodes), interruptible(nodes)), #src
    branches5(nodes), #src
    nothing, #src
    100.0, #src
    nothing, #src
    nothing, #src
) #src
for t = 1:2 #src
    for (ix, l) in enumerate(get_components(PowerLoad, c_sys5_hy_ed)) #src
        ta = load_timeseries_DA[t][ix] #src
        for i = 1:length(ta) # loop over hours #src
            ini_time = timestamp(ta[i]) # get the hour #src
            data = when(load_timeseries_RT[t][ix], hour, hour(ini_time[1])) # get the subset ts for that hour #src
            add_forecast!(c_sys5_hy_ed, l, Deterministic("get_maxactivepower", data)) #src
        end #src
    end #src
    for (ix, l) in enumerate(get_components(HydroDispatch, c_sys5_hy_ed)) #src
        ta = hydro_timeseries_DA[t][ix] #src
        for i = 1:length(ta) # loop over hours #src
            ini_time = timestamp(ta[i]) # get the hour #src
            data = when(hydro_timeseries_RT[t][ix], hour, hour(ini_time[1])) # get the subset ts for that hour #src
            add_forecast!(c_sys5_hy_ed, l, Deterministic("get_rating", data)) #src
        end #src
    end #src
    for (ix, l) in enumerate(get_components(RenewableGen, c_sys5_hy_ed)) #src
        ta = load_timeseries_DA[t][ix] #src
        for i = 1:length(ta) # loop over hours #src
            ini_time = timestamp(ta[i]) # get the hour #src
            data = when(load_timeseries_RT[t][ix], hour, hour(ini_time[1])) # get the subset ts for that hour #src
            add_forecast!(c_sys5_hy_ed, l, Deterministic("get_rating", data)) #src
        end #src
    end #src
    for (ix, l) in enumerate(get_components(HydroDispatch, c_sys5_hy_ed)) #src
        ta = hydro_timeseries_DA[t][ix] #src
        for i = 1:length(ta) # loop over hours #src
            ini_time = timestamp(ta[i]) # get the hour #src
            data = when(hydro_timeseries_RT[t][ix], hour, hour(ini_time[1])) # get the subset ts for that hour #src
            add_forecast!(c_sys5_hy_ed, l, Deterministic("get_storage_capacity", data)) #src
        end #src
    end #src
    for (ix, l) in enumerate(get_components(InterruptibleLoad, c_sys5_hy_ed)) #src
        ta = load_timeseries_DA[t][ix] #src
        for i = 1:length(ta) # loop over hours #src
            ini_time = timestamp(ta[i]) # get the hour #src
            data = when(load_timeseries_RT[t][ix], hour, hour(ini_time[1])) # get the subset ts for that hour #src
            add_forecast!(c_sys5_hy_ed, l, Deterministic("get_maxactivepower", data)) #src
        end #src
    end #src
    for (ix, l) in enumerate(get_components(HydroFix, c_sys5_hy_ed)) #src
        ta = hydro_timeseries_DA[t][ix] #src
        for i = 1:length(ta) # loop over hours #src
            ini_time = timestamp(ta[i]) # get the hour #src
            data = when(hydro_timeseries_RT[t][ix], hour, hour(ini_time[1])) # get the subset ts for that hour #src
            add_forecast!(c_sys5_hy_ed, l, Deterministic("get_rating", data)) #src
        end #src
    end #src
end #src
#src
# And an hourly system with longer time scales  #src
MultiDay = collect( #src
    DateTime("1/1/2024  0:00:00", "d/m/y  H:M:S"):Hour(24):DateTime( #src
        "3/1/2024  00:00:00", #src
        "d/m/y  H:M:S", #src
    ), #src
); #src
 #src
n = 3# number of days  #src
load_timeseries_WK = [ #src
    [ #src
        TimeArray( #src
            MultiDay, #src
            repeat([mean(loadbus2_ts_DA[1:24])], inner = n) + rand(n) * 0.1, #src
        ), #src
        TimeArray( #src
            MultiDay, #src
            repeat([mean(loadbus3_ts_DA[1:24])], inner = n) + rand(n) * 0.1, #src
        ), #src
        TimeArray( #src
            MultiDay, #src
            repeat([mean(loadbus4_ts_DA[1:24])], inner = n) + rand(n) * 0.1, #src
        ), #src
    ], #src
    [ #src
        TimeArray( #src
            MultiDay + Day(n), #src
            repeat([mean(loadbus2_ts_DA[1:24])], inner = n) + rand(n) * 0.1, #src
        ), #src
        TimeArray( #src
            MultiDay + Day(n), #src
            repeat([mean(loadbus3_ts_DA[1:24])], inner = n) + rand(n) * 0.1, #src
        ), #src
        TimeArray( #src
            MultiDay + Day(n), #src
            repeat([mean(loadbus4_ts_DA[1:24])], inner = n) + rand(n) * 0.1, #src
        ), #src
    ], #src
] #src
 #src
 #src
hydro_dispatch_timeseries_WK = [ #src
    [TimeArray(MultiDay, repeat([mean(wind_ts_DA[1:24])], inner = n) + rand(n) * 0.1)], #src
    [TimeArray( #src
        MultiDay + Day(n), #src
        repeat([mean(wind_ts_DA[1:24])], inner = n) + rand(n) * 0.1, #src
    )], #src
] #src
 #src
c_sys5_hy_wk = System( #src
    nodes, #src
    vcat( #src
        thermal_generators5_uc_testing(nodes), #src
        hydro_generators5(nodes), #src
        renewable_generators5(nodes), #src
    ), #src
    loads5(nodes), #src
    branches5(nodes), #src
    nothing, #src
    100.0, #src
    nothing, #src
    nothing, #src
) #src
for t = 1:1 #src
    for (ix, l) in enumerate(get_components(PowerLoad, c_sys5_hy_wk)) #src
        add_forecast!( #src
            c_sys5_hy_wk, #src
            l, #src
            Deterministic("get_maxactivepower", load_timeseries_WK[t][ix]), #src
        ) #src
    end #src
    for h in get_components(HydroDispatch, c_sys5_hy_wk) #src
        add_forecast!( #src
            c_sys5_hy_wk, #src
            h, #src
            Deterministic("get_rating", hydro_dispatch_timeseries_WK[t][1]), #src
        ) #src
    end #src
    for h in get_components(HydroDispatch, c_sys5_hy_wk) #src
        add_forecast!( #src
            c_sys5_hy_wk, #src
            h, #src
            Deterministic("get_storage_capacity", hydro_dispatch_timeseries_WK[t][1]), #src
        ) #src
    end #src
    for h in get_components(HydroDispatch, c_sys5_hy_wk) #src
        add_forecast!( #src
            c_sys5_hy_wk, #src
            h, #src
            Deterministic("get_infow", hydro_dispatch_timeseries_WK[t][1] .* 0.8), #src
        ) #src
    end #src
end #src
 #src