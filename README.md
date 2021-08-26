# Creating Ipynb Reports:
There is a CreateNotebook.yml, located at ~/GitHub/SIIPExamples.jl/.github/workflows/. It performs on Git Actions as follows:
- Start the virtual machine with files from GitHub's *master* branch
- Create gen_notebook.jl
- Run Julia command on gen_notebook.jl
  - covert each *.jl file to *.ipynb in the ~/GitHub/SIIPExamples.jl/script/
- Commit and push those files into GitHub's *notebook* branch (nothing on *master*)


