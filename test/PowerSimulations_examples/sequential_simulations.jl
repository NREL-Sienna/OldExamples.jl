using SIIPExamples
pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath,"test/PowerSimulations_examples/operations_problems.jl"))

sys_RT = System(rawsys; forecast_resolution = Dates.Minute(5))

devices = Dict(:Generators => DeviceModel(ThermalStandard, ThermalDispatchNoMin),
                                    :Ren => DeviceModel(RenewableDispatch, RenewableFullDispatch),
                                    :Loads =>  DeviceModel(PowerLoad, StaticPowerLoad),
                                    :HydroROR => DeviceModel(HydroDispatch, HydroFixed),
                                    :RenFx => DeviceModel(RenewableFix, RenewableFixed),
                                    :ILoads =>  DeviceModel(InterruptibleLoad, InterruptiblePowerLoad),
                                    )

template_ed= OperationsProblemTemplate(CopperPlatePowerModel, devices, branches, Dict());

stages_definition = Dict("UC" => Stage(GenericOpProblem, template_uc, sys, Cbc_optimizer),
                            "ED" => Stage(GenericOpProblem, template_ed, sys_RT, Cbc_optimizer))

inter_stage_chronologies = Dict(("UC"=>"ED") => Synchronize(periods = 24))

ini_cond_chronology = Dict("UC" => Consecutive(), "ED" => Consecutive())

feed_forward = Dict(("ED", :devices, :Generators) => SemiContinuousFF(binary_from_stage = Symbol(PSI.ON),
                                                         affected_variables = [Symbol(PSI.ACTIVE_POWER)]))

cache = Dict("ED" => [TimeStatusChange(PSY.ThermalStandard, PSI.ON)])

order = Dict(1 => "UC", 2 => "ED")
horizons = Dict("UC" => 48, "ED" =>12)
intervals = Dict("UC" => Hour(24), "ED" => Hour(1))

DA_RT_sequence = SimulationSequence(order = order,
                                    horizons = horizons,
                                    intervals = intervals,
                                    intra_stage_chronologies = inter_stage_chronologies,
                                    ini_cond_chronology = ini_cond_chronology,
                                    feed_forward = feed_forward,
                                    cache = cache)

file_path = tempdir()
sim = Simulation(name = "rts-test",
                steps = 1, step_resolution = Hour(24),
                stages = stages_definition,
                stages_sequence = DA_RT_sequence,
                simulation_folder = file_path)

build!(sim)

sim_results = execute!(sim)

uc_results = load_simulation_results(sim_results, "UC");
ed_results = load_simulation_results(sim_results, "ED");

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

