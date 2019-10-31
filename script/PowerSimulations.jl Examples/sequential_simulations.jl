#' ---
#' title: Sequential Simulations with [PowerSimulations.jl](https://github.com/NREL/PowerSimulations.jl)
#' ---

#' **Originally Contributed by**: Clayton Barrows

#' ## Introduction

#' PowerSimulations.jl supports simulations that consist of sequential optimization problems 
#' where results from previous problems inform subsequent problems in a variety of ways this 
#' notebook demonstrates some of these capabilities to represent electricitty market clearing.

#' ### Dependencies
#' Let's use the basic RTS-GMLC dataset from one of the parsing examples
using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath,"test/PowerSystems.jl Examples/parse_tabulardata.jl"))

#' ### Modeling Packages
using DataFrames
using PowerSimulations
using JuMP
using Cbc
Cbc_optimizer = JuMP.with_optimizer(Cbc.Optimizer, logLevel=1, ratioGap=0.1)

const PSI = PowerSimulations;
const PSY = PowerSystems;

# path to "reformat-DC" branch of RTS-GMLC repo: https://github.com/GridMod/RTS-GMLC/
# RTSDIR = "../RTS-GMLC/RTS_Data/SourceData/."

# only do this if you want the full annual data (currently breaks models and simulations below)
#rawsys = PSY.PowerSystemTableData(RTSDIR, 100.0,joinpath(RTSDIR,"../FormattedData/SIIP/user_descriptors.yaml"))

#' ### Make a system from the 5-minute data
sys_RT = System(rawsys; forecast_resolution = Dates.Minute(5))

#' ### Define inittial times for simulatiton
#' We can create a vector of initial times for a system by defining the step length and the 
#' horizon. For example, we can create a set of initial times that represent 12hr steps every
#' 6hrs from the hourly `system`.
DA_initial_times = PSY.generate_initial_times(sys, Dates.Hour(6), 12)

#' Similarly, we can create a set of initial times corresponding to 2hr (24x5min) steps every
#' 1hr from the 5-minute `system`.
RT_initial_times = PSY.generate_initial_times(sys_RT, Dates.Hour(1), 24)

#' ### Define the reference model for the unit commitment
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


model_ref_uc= ModelReference(CopperPlatePowerModel, devices, branches, services);


#' ### Define the reference model for the economic dispatch 
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

model_ref_ed= ModelReference(CopperPlatePowerModel, devices, branches, services);

#' ## Define the stages
#' Stages define a model. The actual problem will change as the stage gets updated to represent
#' different time periods, but the formulations applied to the components is constant within a stage.

#' ### Day-Ahead UC stage
#' The UC stage is defined with:
#'  - formulation = `model_ref_uc`
#'  - `System` = `sys`
#'  - Optimized with the 'Cbc_optimizer'
#'  - Synchronized with ??
#'  - Run once?
DA_stage = Stage(model_ref_uc, 1, sys, Cbc_optimizer,  Dict(0 => Sequential()))

#' ### Real-Time ED stage
#' The ED stage is defined with:
#'  - formulation = `model_ref_ed`
#'  - `System` = `sys_RT`
#'  - Optimized with the 'Cbc_optimizer'
#'  - Synchronized with ??
#'  - Run 6x
RT_stage = Stage(model_ref_ed, 
                6, 
                sys_RT, 
                Cbc_optimizer, 
                Dict(1 => Synchronize(12,4), 
                     0 => Sequential()), 
                TimeStatusChange(:ON_ThermalStandard))

#' Put the stages in a dict
stages = Dict(1 => DA_stage,
              2 => RT_stage)

#' ### Build the simulation
sim = Simulation("test", 1, stages, "/Users/cbarrows/Downloads/"; verbose = true, system_to_file = false, horizon=1)



res = run_sim_model!(sim)


