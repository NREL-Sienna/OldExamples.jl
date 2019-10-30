
using Pkg
Pkg.activate("../../.")


using PowerSystems
using TimeSeries
const PSY = PowerSystems
const IS = PSY.InfrastructureSystems;


PSY.download(PSY.TestData; branch = "master")
base_dir = dirname(dirname(pathof(PowerSystems)));


sys = PSY.parse_standard_files(joinpath(base_dir, "data/matpower/RTS_GMLC.m"));

sys

