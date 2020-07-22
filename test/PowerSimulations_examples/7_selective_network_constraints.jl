using SIIPExamples

using PowerSystems
using PowerSimulations

using Cbc #solver
solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 1, "ratioGap" => 0.5)

pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath, "test", "PowerSystems_examples", "parse_tabulardata.jl"))

for line in get_components(Line, sys)
    if (get_base_voltage(get_from(get_arc(line))) >= 230.0) &&
       (get_base_voltage(get_to(get_arc(line))) >= 230.0)
        #if get_area(get_from(get_arc(line))) != get_area(get_to(get_arc(line)))
        @info "Changing $(get_name(line)) to MonitoredLine"
        convert_component!(MonitoredLine, line, sys)
    end
end

uc_prob =
    UnitCommitmentProblem(sys, optimizer = solver, horizon = 24, network = DCPPowerModel)

set_branch_model!(uc_prob, :L, DeviceModel(Line, StaticLineUnbounded))

construct_device!(uc_prob, :ML, DeviceModel(MonitoredLine, StaticLine))

solve!(uc_prob)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

