using SIIPExamples

using PowerSystems
using PowerSimulations
const PSI = PowerSimulations
using D3TypeTrees

using Dates
using DataFrames

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

branches = Dict{Symbol, DeviceModel}(
    :L => DeviceModel(Line, StaticLine),
    :T => DeviceModel(Transformer2W, StaticTransformer),
    :TT => DeviceModel(TapTransformer, StaticTransformer),
)

devices = Dict(
    :Generators => DeviceModel(ThermalStandard, ThermalStandardUnitCommitment),
    :Ren => DeviceModel(RenewableDispatch, RenewableFullDispatch),
    :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    :HydroROR => DeviceModel(HydroDispatch, FixedOutput),
    :Hydro => DeviceModel(HydroEnergyReservoir, HydroDispatchRunOfRiver),
    :RenFx => DeviceModel(RenewableFix, FixedOutput),
    :ILoads => DeviceModel(InterruptibleLoad, InterruptiblePowerLoad),
)

services = Dict(
    :ReserveUp => ServiceModel(VariableReserve{ReserveUp}, RangeReserve),
    :ReserveDown => ServiceModel(VariableReserve{ReserveDown}, RangeReserve),
)

template_uc = OperationsProblemTemplate(CopperPlatePowerModel, devices, branches, services);

solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 1, "ratioGap" => 0.5)

horizon = 24;
interval = Dates.Hour(24);
transform_single_time_series!(sys, horizon, interval)

op_problem = OperationsProblem(
    GenericOpProblem,
    template_uc,
    sys;
    optimizer = solver,
    horizon = horizon,
)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
