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

rts_dir = SIIPExamples.download("https://github.com/GridMod/RTS-GMLC")
rts_src_dir = joinpath(rts_dir, "RTS_Data", "SourceData")
rts_siip_dir = joinpath(rts_dir, "RTS_Data", "FormattedData", "SIIP")

rawsys = PSY.PowerSystemTableData(rts_src_dir,
                                  100.0,
                                  joinpath(rts_siip_dir,"user_descriptors.yaml"),
                                  timeseries_metadata_file = joinpath(rts_siip_dir,"timeseries_pointers.json"),
                                  generator_mapping_file = joinpath(rts_siip_dir,"generator_mapping.yaml"));

sys = System(rawsys; forecast_resolution = Dates.Hour(1));

branches = Dict{Symbol, DeviceModel}(:L => DeviceModel(Line, StaticLine),
                                     :T => DeviceModel(Transformer2W, StaticTransformer),
                                     :TT => DeviceModel(TapTransformer , StaticTransformer))

devices = Dict(:Generators => DeviceModel(ThermalStandard, ThermalStandardUnitCommitment),
                                    :Ren => DeviceModel(RenewableDispatch, RenewableFullDispatch),
                                    :Loads =>  DeviceModel(PowerLoad, StaticPowerLoad),
                                    :HydroROR => DeviceModel(HydroDispatch, HydroFixed),
                                    :RenFx => DeviceModel(RenewableFix, RenewableFixed),
                                    :ILoads =>  DeviceModel(InterruptibleLoad, InterruptiblePowerLoad),
                                    )

services = Dict(:ReserveUp => ServiceModel(VariableReserve{ReserveUp}, RangeReserve),
                :ReserveDown => ServiceModel(VariableReserve{ReserveDown}, RangeReserve))

template_uc= OperationsProblemTemplate(CopperPlatePowerModel, devices, branches, services);

Cbc_optimizer = JuMP.with_optimizer(Cbc.Optimizer, logLevel=1, ratioGap=0.5)

op_problem = OperationsProblem(GenericOpProblem,
                               template_uc,
                               sys;
                               optimizer = Cbc_optimizer,
                               horizon = 12)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

