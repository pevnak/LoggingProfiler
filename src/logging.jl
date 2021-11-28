struct Events
    stamps::Vector{Float64} # contains the time stamps
    event::Vector{Symbol}  # name of the function that is being recorded
    startstop::Vector{Symbol} # if the time stamp corresponds to start or to stop
    i::Ref{Int}
end

function Events(n::Int)
    Events(Vector{Float64}(undef, n+1), Vector{Symbol}(undef, n+1), Vector{Symbol}(undef, n+1), Ref{Int}(0))
end

function Base.show(io::IO, calls::Events)
    offset = 0
    if calls.i[] >= length(calls.stamps)
        @warn "The recording buffer was too small, consider increasing it"
    end
    for i in 1:min(calls.i[], length(calls.stamps))
        offset -= calls.startstop[i] == :stop
        foreach(_ -> print(io, " "), 1:max(offset, 0))
        rel_time = calls.stamps[i] - calls.stamps[1]
        println(io, calls.event[i], ": ", rel_time)
        offset += calls.startstop[i] == :start
    end
end

global const to = [Events(1000) for i in 1:1]

function initbuffer!(n)
    while length(to) < Threads.nthreads()
        push!(to, Events(n))
    end
    clear!()
    to
end

"""
    record_start(ev::Symbol)

    record the start of the event, the time stamp is recorded after all counters are 
    appropriately increased
"""
record_start(ev::Symbol) = record_start(to[Threads.threadid()], ev)
# function record_start(ev::Symbol) 
#     @show (Threads.threadid(), ev)
#     record_start(to[Threads.threadid()], ev)
# end
function record_start(calls, ev::Symbol)
    n = calls.i[] = calls.i[] + 1
    n > length(calls.stamps) && return 
    calls.event[n] = ev
    calls.startstop[n] = :start
    calls.stamps[n] = time_ns()
end

"""
    record_end(ev::Symbol)

    record the end of the event, the time stamp is recorded before all counters are 
    appropriately increased
"""
record_end(ev::Symbol) = record_end(to[Threads.threadid()], ev::Symbol)
function record_end(calls, ev::Symbol)
    t = time_ns()
    n = calls.i[] = calls.i[] + 1
    n > length(calls.stamps) && return 
    calls.event[n] = ev
    calls.startstop[n] = :stop
    calls.stamps[n] = t
end

clear!() = foreach(t -> t.i[] = 0, to)

function Base.resize!(calls::Events, n::Integer)
  resize!(calls.stamps, n)
  resize!(calls.event, n)
  resize!(calls.startstop, n)
end

resizebuffer!(n::Integer) = foreach(t -> resize!(t, n), to)
recorded() = maximum(t.i[] for t in to)
function adjustbuffer!()
    resizebuffer!(2*recorded())
    clear!()
end