module LoggingProfiler
using IRTools, DataStructures, Colors
include("logging.jl")
include("overdubbing.jl")
include("visualization.jl")

export @record
end
