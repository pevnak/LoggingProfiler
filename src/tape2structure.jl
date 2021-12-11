"""
    iscallalist(calls, i)

    true if the call starting at `i` is a simple call without childs. 
    In the example below, `add_float` is a call list, but `+` is not
    becaus it is `+`.
```
+: 8.73396258e8
 add_float: 8.73396817e8
 add_float: 8.73396957e8
+: 8.73396999e8
```
"""
function iscallalist(calls, i)
    calls.startstop[i] == :stop && return(false)
    calls.i[] < i + 1           && return(false)
    calls.startstop[i+1] == :start && return(false)
    calls.event[i] == calls.event[i+1]
end

function parselist(calls, i)
    new_node = Dict(
        :start => calls.stamps[i],
        :stop => calls.stamps[i+1],
        :name => calls.event[i],
        )
    new_node, i+2
end

"""
    function tape2structure(calls)

    convert flat list of logs of calls and convert it to
    structured format
"""
function tape2structure(calls::Events)
    if calls.i[] >= length(calls.stamps)
        @warn "The recording buffer was too small, consider increasing it"
    end
    root = Dict{Symbol,Any}(:children => [])
    stack = Stack{Dict}() 
    node = root;
    i = 1
    while i <= min(calls.i[], length(calls.stamps))
        if iscallalist(calls, i)
            new_node, i = parselist(calls, i)
            push!(node[:children], new_node)
            continue
        end
        if calls.startstop[i] == :start 
            push!(stack, node)
            new_node = Dict(
                :start => calls.stamps[i],
                :name => calls.event[i],
                :children => []
                )
            # println(i, " new node ", calls.event[i])
            push!(node[:children], new_node)
            node = new_node
            i += 1
            continue
        end

        if calls.startstop[i] == :stop
            # println(i, " end node ", calls.event[i], " expecting: ", node[:name])
            haskey(node, :name) && @assert node[:name] == calls.event[i]
            node[:stop] = calls.stamps[i]
            i += 1
            node = pop!(stack)
            continue
        end
    end
    root[:children]
end
tape2structure() = [tape2structure(t) for t in to];