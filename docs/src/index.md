# SIIPExamples.jl
This repository contians examples and tutorials for Scalable Integrated Infrastructure Planning (SIIP) packages developed at the [National Renewable Energy Laboratory (NREL)](nrel.gov). This repository uses a template established by [JuMPTutorials.jl](https://github.com/JuliaOpt/JuMPTutorials.jl).

## Structure

The base file for every tutorial is a regular Julia script 
which is converted into a Jupyter Notebook using Weave.jl for ease of access.
This approach makes it easier to compare diffs and track files in Git compared to entire Jupyter notebooks. 
It also allows us to set up CI testing for the tutorials to ensure that they produce the expected output 
and don’t suffer from bit rot over time.

The base files are present in the script folder inside a subfolder of the relevant category.
Jupyter notebooks generated using Weave.jl are found in the notebook folder. 
The tests folder contains relevant code extracted from the base files for testing and 
the src folder has the Weave.jl utilities used for conversion.

## Contributors

- Clayton Barrows