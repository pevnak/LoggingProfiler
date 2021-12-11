# this design is poor for cache locality
struct Events
    stamps::Vector{UInt64} # contains the time stamps
    taskid::Vector{UInt64}  # contains the id of task being executed, such that we can deal with task migration
    event::Vector{Symbol}   # name of the function that is being recorded
    startstop::Vector{Symbol} # if the time stamp corresponds to start or to stop
    i::Vector{UInt64}
end

function Events(n::Int)
    Events(Vector{UInt64}(undef, n+1), 
        Vector{UInt64}(undef, n+1), 
        Vector{Symbol}(undef, n+1), 
        Vector{Symbol}(undef, n+1), 
        UInt64[0])
end

function Base.show(io::IO, calls::Events)
    offset = 0
    if calls.i[1] >= length(calls.stamps)
        @warn "The recording buffer was too small, consider increasing it"
    end
    for i in 1:min(calls.i[1], length(calls.stamps))
        offset -= calls.startstop[i] == :stop
        foreach(_ -> print(io, " "), 1:max(offset, 0))
        rel_time = calls.stamps[i] - calls.stamps[1]
        println(io, calls.taskid[i], "  ",calls.event[i], ": ", rel_time)
        offset += calls.startstop[i] == :start
    end
end

global const to = [Events(1000) for i in 1:1]

function initbuffer!(n)
    while length(to) < Threads.nthreads()
        push!(to, Events(n))
    end
    clear!()
    nothing
end

"""
    record_start(ev::Symbol)

    record the start of the event, the time stamp is recorded after all counters are 
    appropriately increased
"""
record_start(ev::Symbol) = record_start(to[Threads.threadid()], ev)
function record_start(calls, ev::Symbol)
    @inbounds n = calls.i[1] = calls.i[1] + 1          # this is about 20ns
    n > length(calls.stamps) && return 
    @inbounds calls.event[n] = ev
    @inbounds calls.taskid[n] = objectid(current_task()) #this is negligible
    @inbounds calls.startstop[n] = :start
    @inbounds calls.stamps[n] = time_ns()  #this is abount 38 ns
    nothing
end

"""
    record_end(ev::Symbol)

    record the end of the event, the time stamp is recorded before all counters are 
    appropriately increased
"""
record_end(ev::Symbol) = record_end(to[Threads.threadid()], ev::Symbol)
function record_end(calls, ev::Symbol)
    @inbounds n = calls.i[1] = calls.i[1] + 1
    n > length(calls.stamps) && return 
    @inbounds calls.stamps[n] = time_ns()
    @inbounds calls.event[n] = ev
    @inbounds calls.taskid[n] = objectid(current_task())
    @inbounds calls.startstop[n] = :stop
    nothing
end

clear!() = foreach(t -> t.i[1] = 0, to)

function Base.resize!(calls::Events, n::Integer)
  resize!(calls.stamps, n)
  resize!(calls.taskid, n)
  resize!(calls.event, n)
  resize!(calls.startstop, n)
end

resizebuffer!(n::Integer) = foreach(t -> resize!(t, n), to)
recorded() = maximum(t.i[1] for t in to)
function adjustbuffer!()
    resizebuffer!(2*recorded())
    clear!()
end