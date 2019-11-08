
using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath,"test/PowerSystems_examples/parse_tabulardata.jl"))


using DataFrames
using PowerSimulations
using JuMP
using Cbc
Cbc_optimizer = JuMP.with_optimizer(Cbc.Optimizer, logLevel=1, ratioGap=0.1)

const PSI = PowerSimulations;
const PSY = PowerSystems;


sys_RT = System(rawsys; forecast_resolution = Dates.Minute(5))


DA_initial_times = PSY.generate_initial_times(sys, Dates.Hour(6), 12)


RT_initial_times = PSY.generate_initial_times(sys_RT, Dates.Hour(1), 24)


branches = Dict{Symbol, DeviceModel}(#:L => DeviceModel(PSY.Line, PSI.StaticLine),
                                     #:T => DeviceModel(PSY.Transformer2W, PSI.StaticTransformer),
                                     #:TT => DeviceModel(PSY.TapTransformer, PSI.StaticTransformer),
                                     #:dc_line => DeviceModel(PSY.HVDCLine, PSI.HVDCDispatch)
                                    )

services = Dict{Symbol, PSI.ServiceModel}()

devices = Dict{Symbol, DeviceModel}(:Generators => DeviceModel(PSY.ThermalStandard, PSI.ThermalBasicUnitCommitment),
                                    :Ren => DeviceModel(PSY.RenewableDispatch, PSI.RenewableFullDispatch),
                                    :Loads =>  DeviceModel(PSY.PowerLoad, PSI.StaticPowerLoad),
                                    #:ILoads =>  DeviceModel(PSY.InterruptibleLoad, PSI.StaticPowerLoad),
                                    )       


model_ref_uc= OperationsTemplate(CopperPlatePowerModel, devices, branches, services);


branches = Dict{Symbol, DeviceModel}(#:L => DeviceModel(PSY.Line, PSI.StaticLine),
                                     #:T => DeviceModel(PSY.Transformer2W, PSI.StaticTransformer),
                                     #:TT => DeviceModel(PSY.TapTransformer, PSI.StaticTransformer),
                                     #:dc_line => DeviceModel(PSY.HVDCLine, PSI.HVDCDispatch)
                                        )

services = Dict{Symbol, PSI.ServiceModel}()

devices = Dict{Symbol, DeviceModel}(:Generators => DeviceModel(PSY.ThermalStandard, PSI.ThermalDispatch, SemiContinuousFF(:P, :ON)),
                                    :Ren => DeviceModel(PSY.RenewableDispatch, PSI.RenewableFullDispatch),
                                    :Loads =>  DeviceModel(PSY.PowerLoad, PSI.StaticPowerLoad),
                                    #:ILoads =>  DeviceModel(PSY.InterruptibleLoad, PSI.DispatchablePowerLoad),
                                    )       

model_ref_ed= OperationsTemplate(CopperPlatePowerModel, devices, branches, services);


DA_stage = Stage(model_ref_uc, 
                 24, 
                 Dates.Hour(12), 
                 1, 
                 sys, 
                 Cbc_optimizer, 
                 Dict(0=> Sequential()))


chrono = Dict(1 => Synchronize(12,4), 0 => Sequential())


RT_stage = Stage(model_ref_ed, 
                3,
                Dates.Minute(15),
                48, 
                sys_RT, 
                Cbc_optimizer, 
                chrono, 
                TimeStatusChange(:ON_ThermalStandard))


stages = Dict(1 => DA_stage,
              2 => RT_stage)


sim = Simulation("test", 1, stages, "/Users/cbarrows/Downloads/"; verbose = true, system_to_file = false, horizon=1)


res = execute!(sim, verbose=true)


rt_results = load_simulation_results("stage-2",res)

