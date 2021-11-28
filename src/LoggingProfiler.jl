module LoggingProfiler
using IRTools, DataStructures, Colors
include("logging.jl")
include("whiteblacklist.jl")
include("overdubbing.jl")
include("visualization.jl")

export @record
end
