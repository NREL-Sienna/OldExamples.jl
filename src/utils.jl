
# lightweight type tree printing
AbstractTrees.children(x::Type) = subtypes(x)

"""
`print_struct()`

Prints the definition of a struct.
"""
function print_struct(type)
    mutable = type.mutable ? "mutable" : ""
    println("$mutable struct $type")
    for (fn, ft) in zip(fieldnames(type), fieldtypes(type))
        println("    $fn::$ft")
    end
    println("end")
end

function read_json(filename)
    return open(filename) do io
        JSON3.read(io, Dict)
    end
end

abstract type AbstractOS end
abstract type Unix <: AbstractOS end
abstract type BSD <: Unix end

abstract type Windows <: AbstractOS end
abstract type MacOS <: BSD end
abstract type Linux <: BSD end

if Sys.iswindows()
    const os = Windows
elseif Sys.isapple()
    const os = MacOS
else
    const os = Linux
end

"""
Download Data from `branch="master"` name into a "data" folder in given argument path.
Skip the actual download if the folder already exists and force=false.
Defaults to the root of the PowerSystems package.

Returns the downloaded folder name.
"""
function download(
    repo::AbstractString,
    folder::AbstractString = abspath(joinpath(@__DIR__, "..")),
    branch::String = "master",
    force::Bool = false,
)
    if Sys.iswindows()
        DATA_URL = "$repo/archive/$branch.zip"
    else
        DATA_URL = "$repo/archive/$branch.tar.gz"
    end
    directory = abspath(normpath(folder))
    reponame = splitpath(repo)[end]
    data = joinpath(directory, "$reponame-$branch")
    if !isdir(data) || force
        @info "Downloading $DATA_URL"
        tempfilename = Base.download(DATA_URL)
        mkpath(directory)
        @info "Extracting data to $data"
        unzip(os, tempfilename, directory)
        # mv(joinpath(directory, "$reponame-$branch"), data, force = true)
    end

    return data
end

function unzip(::Type{<:BSD}, filename, directory)
    @assert success(`tar -xvf $filename -C $directory`) "Unable to extract $filename to $directory"
end

function unzip(::Type{Windows}, filename, directory)
    path_7z = if Base.VERSION < v"0.7-"
        "$JULIA_HOME/7z"
    else
        sep = Sys.iswindows() ? ";" : ":"
        withenv(
            "PATH" => string(
                joinpath(Sys.BINDIR, "..", "libexec"),
                sep,
                Sys.BINDIR,
                sep,
                ENV["PATH"],
            ),
        ) do
            Sys.which("7z")
        end
    end
    @assert success(`$path_7z x $filename -y -o$directory`) "Unable to extract $filename to $directory"
end
