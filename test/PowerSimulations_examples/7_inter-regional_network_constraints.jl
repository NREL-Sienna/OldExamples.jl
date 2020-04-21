using SIIPExamples

using PowerSystems
const PSY = PowerSystems
using PowerSimulations
const PSI = PowerSimulations

using Dates

using Cbc #solver

pkgpath = dirname(dirname(pathof(SIIPExamples)))
include(joinpath(pkgpath,"test", "PowerSystems_examples", "parse_tabulardata.jl"))

regional_lines = ["AB1", "AB2", "AB3", "CA-1", "CB-1"];
for name in regional_lines
    line = get_components_by_name(ACBranch, sys, name)
    convert_component!(MonitoredLine, line[1], sys)
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

