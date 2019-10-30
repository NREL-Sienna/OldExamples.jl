
using Pkg
Pkg.status()


using SIIPExamples
using PowerSystems
using TimeSeries
const PSY = PowerSystems
const IS = PSY.InfrastructureSystems;


PSY.download(PSY.TestData; branch = "master")
base_dir = dirname(dirname(pathof(PowerSystems)));


sys = PSY.parse_standard_files(joinpath(base_dir,"data/psse_raw/RTS-GMLC.RAW"));

sys

