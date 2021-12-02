module LoggingProfiler
using IRTools, DataStructures, Colors, Dictionaries
include("logging.jl")
include("whiteblacklist.jl")
include("overdubbing.jl")
include("visualization.jl")
include("luxor.jl")

export @record, @recordfun whitelist!, blacklist!
end
