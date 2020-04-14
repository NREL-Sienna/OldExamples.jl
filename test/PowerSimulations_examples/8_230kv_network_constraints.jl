using SIIPExamples

using PowerSystems
const PSY = PowerSystems
using PowerSimulations
const PSI = PowerSimulations

using Dates

using Cbc #solver

pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath,"test", "PowerSystems_examples", "parse_tabulardata.jl"))

for line in get_components(Line, sys)
    if (get_basevoltage(get_from(get_arc(line))) >= 230.0) && (get_basevoltage(get_to(get_arc(line))) >= 230.0)
        convert_component!(MonitoredLine, line, sys)
    end
end

uc_template = template_unit_commitment(network = DCPPowerModel)

solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 1, "ratioGap" => 0.5)

op_problem = OperationsProblem(GenericOpProblem,
                               uc_template,
                               sys;
                               optimizer = solver,
                               horizon = 12,
                               slack_variables=true
)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

