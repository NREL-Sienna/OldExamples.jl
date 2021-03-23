using PowerSystems
using PowerSimulations
using PowerSystemCaseBuilder

using Cbc #solver
solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 1, "ratioGap" => 0.5)

sys = build_system(PSITestSystems, "test_RTS_GMLC_sys")

for line in get_components(Line, sys)
    if (get_base_voltage(get_from(get_arc(line))) >= 230.0) &&
       (get_base_voltage(get_to(get_arc(line))) >= 230.0)
        #if get_area(get_from(get_arc(line))) != get_area(get_to(get_arc(line)))
        @info "Changing $(get_name(line)) to MonitoredLine"
        convert_component!(MonitoredLine, line, sys)
    end
end

template = template_unit_commitment(transmission = PTDFPowerModel)

set_device_model!(template, MonitoredLine, StaticBranch)

set_device_model!(template, Line, StaticBranchUnbounded)

uc_prob = OperationsProblem(template, sys, horizon = 24, optimizer = solver)
build!(uc_prob, output_dir = mktempdir())

solve!(uc_prob)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

