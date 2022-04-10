#! format: off

using SIIPExamples
using PowerSystems
using PowerSimulations
const PSI = PowerSimulations

using PowerSystemCaseBuilder
using Dates
using DataFrames
using TimeSeries

using HiGHS #solver

sys = build_system(PSITestSystems, "modified_RTS_GMLC_DA_sys")

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

transform_single_time_series!(sys, 24, Dates.Hour(24))

uc_template = template_unit_commitment()

set_device_model!(uc_template, ThermalMultiStart, ThermalMultiStartUnitCommitment)

solver = optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.5)

problem = DecisionModel(uc_template, sys, horizon = 4, optimizer = solver)
build!(problem, output_dir = mktempdir())

solve!(problem)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
