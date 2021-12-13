# Generate notebooks using literate
using Pkg
Pkg.instantiate()

using SIIPExamples
using PowerSystemCaseBuilder

PowerSystemCaseBuilder.clear_all_serialized_system()
SIIPExamples.literate_all(execute = false) # ensures that all notebooks exist
SIIPExamples.literate_all(force = true)
