module SIIPExamples

export print_struct

using Weave

repo_directory = dirname(joinpath(@__DIR__))

"""
`weave_file(folder::AbstractString, file::AbstractString)`

Checks if the file has been modified since the last Weave and updates the notebook and tests accordingly.

* `folder` = Name of the folder the tutorial is in
* `file` = Name of the tutorial file
* `force` = foce weave irrespective of file changes
"""
function weave_file(folder, file; force = false)
    
    filename = split(file, ".")[1]
    srcpath = joinpath(repo_directory, "script", folder, file)
    testpath = joinpath(repo_directory, "test", folder, file)
    notebookpath = joinpath(repo_directory, "notebook", folder)
    notebookfilepath = joinpath(notebookpath, join([filename,".ipynb"]))

    if mtime(srcpath) > mtime(testpath) || mtime(testpath)==0.0 || force
        @warn "Updating tests for $filename as it has been updated since the last weave."
        tangle(srcpath, out_path=testpath)
        
    else
        @warn "Skipping tests for $filename as it has not been updated."
    end

    if mtime(srcpath) > mtime(notebookfilepath) || mtime(notebookfilepath)==0.0 || force
        @warn "Weaving $filename to Jupyter Notebook as it has been updated since the last weave."
        convert_doc(srcpath, notebookfilepath)
    else
        @warn "Skipping Jupyter Notebook for $filename as it has not been updated."
    end
end

"""
`weave_file(folder::AbstractString)`

Checks the files present in the specified folder for modifications and updates the notebook and tests accordingly.

* `folder` = Name of the folder to check
"""
function weave_folder(folder; force=false)
    for file in readdir(joinpath(repo_directory,"script",folder))
        println("")
        println("Building $(joinpath(folder,file))")
        try
            weave_file(folder, file, force = force)
        catch
            @error "failed to build $(joinpath(folder,file))"
        end
        println("")
    end
end

"""
`weave_all()`

Checks every tutorial for modifications and updates the notebook and tests accordingly.
"""
function weave_all(;force=false)
    for folder in readdir(joinpath(repo_directory,"script"))
        weave_folder(folder; force = force)
    end
end

"""
`print_struct()`

Prints the definition of a struct.
"""
function print_struct(type)
    mutable = type.mutable ? "mutable" : ""
    println("$mutable struct $type")
    for (fn, ft) in zip(fieldnames(type),fieldtypes(type))
        println("    $fn::$ft")
    end
    println("end")
end

end
