using SIIPExamples

using PowerSystems
using PowerSimulations
const PSI = PowerSimulations
using D3TypeTrees

using Dates
using DataFrames
using TimeSeries

using JuMP
using Cbc #solver

rts_dir = SIIPExamples.download("https://github.com/GridMod/RTS-GMLC")
rts_src_dir = joinpath(rts_dir, "RTS_Data", "SourceData")
rts_siip_dir = joinpath(rts_dir, "RTS_Data", "FormattedData", "SIIP");

rawsys = PowerSystems.PowerSystemTableData(
    rts_src_dir,
    100.0,
    joinpath(rts_siip_dir, "user_descriptors.yaml"),
    timeseries_metadata_file = joinpath(rts_siip_dir, "timeseries_pointers.json"),
    generator_mapping_file = joinpath(rts_siip_dir, "generator_mapping.yaml"),
);
sys = System(rawsys; time_series_resolution = Dates.Hour(1));

MultiDay = collect(
    DateTime("2020-01-01T00:00:00"):Hour(1):DateTime("2020-01-01T00:00:00") + Hour(8783),
);

for gen in get_components(ThermalGen, sys)
    varcost = get_operation_cost(gen)
    market_bid_cost = MarketBidCost(;
        variable = nothing,
        no_load = get_fixed(varcost),
        start_up = (hot = get_start_up(varcost), warm = 0.0, cold = 0.0),
        shut_down = get_shut_down(varcost),
        ancillary_services = Vector{Service}()
        )
    set_operation_cost!(gen, market_bid_cost)

    data = TimeArray(MultiDay, repeat([get_cost(get_variable(varcost))], 8784))
    _time_series = SingleTimeSeries("variable_cost", data)
    set_variable_cost!(sys, gen, _time_series)
end

horizon = 24 ;  interval = Dates.Hour(24)
transform_single_time_series!(sys, horizon, interval)

uc_template = template_unit_commitment(network = CopperPlatePowerModel)

uc_template.devices[:Generators]= DeviceModel(ThermalStandard, ThermalMultiStartUnitCommitment)


solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 1, "ratioGap" => 0.5)

problem = OperationsProblem(
    EconomicDispatchProblem,
    uc_template,
    sys,
    horizon = 4,
    optimizer = solver,
    balance_slack_variables = true,
)

solve!(problem)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

