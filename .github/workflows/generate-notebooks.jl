# Generate notebooks using literate
using Pkg
Pkg.instantiate()

using SIIPExamples
using Literate

SIIPExamples.literate_all(force = true)
