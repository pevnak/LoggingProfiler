module LoggingProfiler
using IRTools, DataStructures, Colors, Dictionaries
include("logging.jl")
include("whiteblacklist.jl")
include("overdubbing.jl")
include("tape2structure.jl")
include("luxor.jl")

export @record, @rrecord, @recordfun whitelist!, blacklist!
end
