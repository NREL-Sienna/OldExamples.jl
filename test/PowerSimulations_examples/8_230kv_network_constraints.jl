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
rts_siip_dir = joinpath(rts_dir, "RTS_Data", "FormattedData", "SIIP");

rawsys = PSY.PowerSystemTableData(rts_src_dir,
                                  100.0,
                                  joinpath(rts_siip_dir,"user_descriptors.yaml"),
                                  timeseries_metadata_file = joinpath(rts_siip_dir,"timeseries_pointers.json"),
                                  generator_mapping_file = joinpath(rts_siip_dir,"generator_mapping.yaml"));

sys = System(rawsys; forecast_resolution = Dates.Hour(1));

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

