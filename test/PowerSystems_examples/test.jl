m = Module(gensym())

include_string(m, "using Pkg")
include_string(m, "Pkg.status()")
include_string(m, "using SIIPExamples")
include_string(m, "using PowerSystems")
include_string(m, "using TimeSeries")
include_string(m, "using Dates")
include_string(m, "using Logging")
include_string(m, "const PSY = PowerSystems")
include_string(m, "const IS = PSY.InfrastructureSystems;")
include_string(m, """PSY.download(PSY.TestData; branch = "master", force=true)""")
include_string(m, "base_dir = dirname(dirname(pathof(PowerSystems)));")
include_string(m, """RTS_GMLC_DIR = joinpath(base_dir,"data/RTS_GMLC");""")
include_string(
    m,
    """rawsys = PSY.PowerSystemTableData(RTS_GMLC_DIR,100.0, joinpath(RTS_GMLC_DIR,"user_descriptors.yaml"))""",
)
include_string(m, "sys = System(rawsys; forecast_resolution = Dates.Hour(1))")

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
