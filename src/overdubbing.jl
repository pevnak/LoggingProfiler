using IRTools
using Dictionaries
using IRTools: var, xcall, insert!, insertafter!, func, recurse!, @dynamo


function timable(ex::Expr) 
    ex.head != :call && return(false)
    isempty(ex.args) && return(false)
    timable(ex.args[1])
end
timable(ex) = false

"""
    timable(ex::GlobalRef)

    decides if function will be timed or not. By default, all functions are timed. 
    But if any function is white-listed by adding function / module  to whitelists,
    the default becomes deny and only white-listed function function are allowed.

    If something is added to blacklist, that the default accept is kept and only
    blacklisted functions are not timed.
"""
function timable(ex::GlobalRef)
    ex.mod ∈ whitelist_module && return(true)
    ex ∈ whitelist_globalref && return(true)
    ex.name ∈ whitelist_function && return(true)
    ex.mod ∈ blacklist_module && return(false)
    ex ∈ blacklist_globalref && return(false)
    ex.name ∈ blacklist_function && return(false)
    isempty(whitelist_module) && isempty(whitelist_function) && isempty(whitelist_function) && return(true)
    return(false)
end


recursable(gr::GlobalRef) = gr.name ∉ [:profile_fun, :record_start, :record_end]
recursable(ex::Expr) = ex.head == :call && recursable(ex.args[1])
recursable(ex) = false

exportname(ex::GlobalRef) = QuoteNode(ex.name)
exportname(ex::Symbol) = QuoteNode(ex)
exportname(ex::Expr) = exportname(ex.args[1])
exportname(i::Int) = QuoteNode(Symbol("Int(",i,")"))

profile_fun(f::Core.IntrinsicFunction, args...) = f(args...)
profile_fun(f::Core.Builtin, args...) = f(args...)

@dynamo function profile_fun(f, args...)
    ir = IRTools.Inner.IR(f, args...)
    for (v, ex) in ir
        if timable(ex.expr)
            fname = exportname(ex.expr)
            insert!(ir, v, xcall(LoggingProfiler, :record_start, fname))
            insertafter!(ir, v, xcall(LoggingProfiler, :record_end, fname))
        end
    end
    for (x, st) in ir
        recursable(st.expr) || continue
        ir[x] = xcall(profile_fun, st.expr.args...)
    end
    # recurse!(ir)
    return ir
end

macro record(ex)
    esc(Expr(:call, :(LoggingProfiler.profile_fun), ex.args...))
end