using SIIPExamples
using PowerSystems
using PowerSimulations
const PSI = PowerSimulations

using PowerSystemCaseBuilder
using Dates
using DataFrames
using TimeSeries

using Cbc #solver

include(joinpath(SIIPExamples.TEST_DIR, SIIPExamples.PSY_EX_FOLDER, "04_parse_tabulardata.jl"))

MultiDay = collect(
    DateTime("2020-01-01T00:00:00"):Hour(1):(DateTime("2020-01-01T00:00:00") + Hour(8783)),
);

remove_time_series!(sys, DeterministicSingleTimeSeries)

for gen in get_components(ThermalGen, sys)
    varcost = get_operation_cost(gen)
    data = TimeArray(MultiDay, repeat([get_cost(get_variable(varcost))], 8784))
    _time_series = SingleTimeSeries("variable_cost", data)
    add_time_series!(sys, gen, _time_series)
    #set_variable_cost!(sys, gen, _time_series)
end

horizon = 24;
interval = Dates.Hour(24);
transform_single_time_series!(sys, horizon, interval)

uc_template = template_unit_commitment(network = CopperPlatePowerModel)

set_device_model!(uc_template, ThermalMultiStart, ThermalMultiStartUnitCommitment)

solver = optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 1, "ratioGap" => 0.5)

problem = OperationsProblem(
    uc_template,
    sys,
    horizon = 4,
    optimizer = solver,
    balance_slack_variables = true,
)
build!(problem, output_dir = mktempdir())

solve!(problem)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

