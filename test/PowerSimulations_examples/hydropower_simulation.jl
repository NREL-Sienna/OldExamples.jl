using SIIPExamples

using InfrastructureSystems
const IS = InfrastructureSystems
using PowerSystems
const PSY = PowerSystems
using PowerSimulations
const PSI = PowerSimulations
using D3TypeTrees

using Dates
using DataFrames

using JuMP
using Cbc #solver
Cbc_optimizer = JuMP.with_optimizer(Cbc.Optimizer, logLevel=1, ratioGap=0.5)

using Logging
logger = IS.configure_logging(console_level = Logging.Info,
                              file_level = Logging.Info,
                              filename = "op_problem_log.txt")

pkgpath = dirname(dirname(pathof(SIIPExamples)))

include(joinpath(pathof(PSI), "../../test/test_utils/get_test_data.jl"))

hydro_generators5(nodes5) = [
                    HydroFix("HydroFix", true, nodes5[2], 0.0, 0.0,
                        TechHydro(0.600, PowerSystems.HY, (min = 0.0, max = 60.0), (min = 0.0, max = 60.0), nothing, nothing)
                    ),
                    HydroDispatch("HydroDispatch", true, nodes5[3], 0.0, 0.0,
                        TechHydro(0.600, PowerSystems.HY, (min = 0.0, max = 60.0), (min = 0.0, max = 60.0), (up = 10.0, down = 10.0), nothing),
                        TwoPartCost(15.0, 0.0), 10.0, 2.0, 5.0
                    )
                    ];

hydro_dispatch_timeseries_DA = [[TimeSeries.TimeArray(DayAhead,wind_ts_DA)],
                        [TimeSeries.TimeArray(DayAhead + Day(1),  wind_ts_DA)]];

hydro_timeseries_DA = [[TimeSeries.TimeArray(DayAhead,wind_ts_DA)],
                        [TimeSeries.TimeArray(DayAhead + Day(1),  wind_ts_DA)]];


hydro_timeseries_RT = [[TimeArray(RealTime,repeat(wind_ts_DA,inner=12))],
                     [TimeArray(RealTime + Day(1), repeat(wind_ts_DA,inner=12))]];

hydro_dispatch_timeseries_RT = [[TimeArray(RealTime,repeat(wind_ts_DA,inner=12))],
                     [TimeArray(RealTime + Day(1),  repeat(wind_ts_DA,inner=12))]];


c_sys5_hy = System(nodes, vcat(thermal_generators5_uc_testing(nodes), hydro_generators5(nodes), renewable_generators5(nodes)), loads5(nodes), branches5(nodes), nothing, 100.0, nothing, nothing)
for t in 1:2
   for (ix, l) in enumerate(get_components(PowerLoad, c_sys5_hy))
       add_forecast!(c_sys5_hy, l, Deterministic("get_maxactivepower", load_timeseries_DA[t][ix]))
   end
   for (ix, h) in enumerate(get_components(HydroDispatch, c_sys5_hy))
       add_forecast!(c_sys5_hy, h, Deterministic("get_rating", hydro_dispatch_timeseries_DA[t][ix]))
   end
   for (ix, h) in enumerate(get_components(HydroDispatch, c_sys5_hy))
       add_forecast!(c_sys5_hy, h, Deterministic("get_storage_capacity", hydro_dispatch_timeseries_DA[t][ix]))
   end
   for (ix, h) in enumerate(get_components(HydroFix, c_sys5_hy))
       add_forecast!(c_sys5_hy, h, Deterministic("get_rating", hydro_timeseries_DA[t][ix]))
   end
    for (ix, r) in enumerate(get_components(RenewableGen, c_sys5_hy))
        add_forecast!(c_sys5_hy, r, Deterministic("get_rating", ren_timeseries_DA[t][ix]))
    end
    for (ix, i) in enumerate(get_components(InterruptibleLoad, c_sys5_hy))
        add_forecast!(c_sys5_hy, i, Deterministic("get_maxactivepower", Iload_timeseries_DA[t][ix]))
    end
end

TypeTree(PSY.HydroGen)

TypeTree(PSI.AbstractHydroFormulation)

devices = Dict{Symbol, DeviceModel}(:Hyd1 => DeviceModel(HydroDispatch, HydroDispatchRunOfRiver),
                                    :Hyd2 =>DeviceModel(HydroFix, HydroFixed));

template = PSI.OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

op_problem = PSI.OperationsProblem(GenericOpProblem, template, c_sys5_hy, horizon = 2)

op_problem.psi_container.JuMPmodel

devices = Dict{Symbol, DeviceModel}(:Hyd1 => DeviceModel(HydroDispatch, HydroDispatchReservoirFlow),
                                    :Hyd2 =>DeviceModel(HydroFix, HydroDispatchRunOfRiver));

template = PSI.OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

op_problem = PSI.OperationsProblem(GenericOpProblem, template, c_sys5_hy, horizon = 2)

op_problem.psi_container.JuMPmodel

devices = Dict{Symbol, DeviceModel}(:Hyd1 => DeviceModel(HydroDispatch, HydroDispatchReservoirStorage),
                                    :Hyd2 =>DeviceModel(HydroFix, HydroDispatchRunOfRiver));

template = PSI.OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

op_problem = PSI.OperationsProblem(GenericOpProblem, template, c_sys5_hy, horizon = 2)

op_problem.psi_container.JuMPmodel

devices = Dict{Symbol, DeviceModel}(:Hyd1 => DeviceModel(HydroDispatch, HydroCommitmentReservoirStorage),
                                    :Hyd2 =>DeviceModel(HydroFix, HydroDispatchRunOfRiver));

template = PSI.OperationsProblemTemplate(CopperPlatePowerModel, devices, Dict(), Dict());

op_problem = PSI.OperationsProblem(GenericOpProblem, template, c_sys5_hy, horizon = 2)

op_problem.psi_container.JuMPmodel

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

