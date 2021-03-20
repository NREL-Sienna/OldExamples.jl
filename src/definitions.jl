
abstract type Examples end
abstract type JuliaExamples <: Examples end
abstract type PSYExamples <: Examples end
abstract type PSIExamples <: Examples end
abstract type PSDExamples <: Examples end

const PACKAGE_DIR = dirname(dirname(pathof(SIIPExamples)))
const SCRIPT_DIR = joinpath(PACKAGE_DIR, "script")
const TEST_DIR = joinpath(PACKAGE_DIR, "test")
const NB_DIR = joinpath(PACKAGE_DIR, "notebook")

const JULIA_EX_FOLDER = "1_introduction"
const PSY_EX_FOLDER = "2_PowerSystems_examples"
const PSI_EX_FOLDER = "3_PowerSimulations_examples"
const PSD_EX_FOLDER = "4_PowerSimulationsDynamics_examples"

get_dir(::Type{JuliaExamples}) = JULIA_EX_FOLDER
get_dir(::Type{PSYExamples}) = PSY_EX_FOLDER
get_dir(::Type{PSIExamples}) = PSI_EX_FOLDER
get_dir(::Type{PSDExamples}) = PSD_EX_FOLDER
