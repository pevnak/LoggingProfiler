using IRTools
using IRTools: var, xcall, insert!, insertafter!, func, recurse!, @dynamo


const timable_list = WhiteBlackLists()
const recursable_list = WhiteBlackLists()
"""
    timable(ex::GlobalRef)

    decides if function will be timed or not. By default, all functions are timed. 
    But if any function is white-listed by adding function / module  to whitelists,
    the default becomes deny and only white-listed function function are allowed.

    If something is added to blacklist, that the default accept is kept and only
    blacklisted functions are not timed.
"""
function timable(ex::GlobalRef)
    iswhite(timable_list, ex) && return(true)
    isblack(timable_list, ex) && return(false)
    return(isempty(timable_list) ? true : false)
end

function timable(ex::Expr) 
    ex.head != :call && return(false)
    isempty(ex.args) && return(false)
    timable(ex.args[1])
end

timable(ex::IRTools.Inner.Variable) = true

timable(ex) = false


"""
    recursable(ex::Expr)
    recursable(ex::GlobalRef)

    decides if we should descend into the function or not. By default, we descent into all 
    functions, but with a combination of blacklists and whitelists, this can be changed.

    If something is added to blacklist, that the default accept is kept and only
"""
function recursable(ex::GlobalRef)
    ex.name ∈ (:profile_fun, :record_start, :record_end) && return(false)
    iswhite(recursable_list, ex) && return(true)
    isblack(recursable_list, ex) && return(false)
    return(isempty(recursable_list) ? true : false)
end

recursable(ex::IRTools.Inner.Variable) = true

function recursable(ex::Expr) 
    ex.head != :call && return(false)
    isempty(ex.args) && return(false)
    recursable(ex.args[1])
end

recursable(ex) = false

"""
    exportname(ex)

    name of the function call that would be logged to the profiler
"""
exportname(ex::GlobalRef) = QuoteNode(ex.name)
exportname(ex::Symbol) = QuoteNode(ex)
exportname(ex::Expr) = exportname(ex.args[1])
exportname(i::Int) = QuoteNode(Symbol("Int(",i,")"))
exportname(i::IRTools.Inner.Variable) = QuoteNode(Symbol("Id(",i.id,")"))

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
    return ir
end

macro record(ex) 
    esc(Expr(:call, :(LoggingProfiler.profile_fun), ex.args...))
end

macro recordfun(ex::Expr)
    @assert ex.head == :call 
    fname = ex.args[1]
    x = gensym(:result)
    rex = quote
        LoggingProfiler.record_start($(QuoteNode(fname)))
        $(x) = $(ex)
        LoggingProfiler.record_end($(QuoteNode(fname)))
        $(x)
    end
    esc(rex)
end
# macro record(ex)
#     ex.head != :call && error("we can profiler only function calls")
#     s = fname(ex)
#     r = gensym(:record_result)
#     b = [
#         Expr(:call, :(LoggingProfiler.record_start), s),
#         Expr(Symbol("="), r, Expr(:call, :(LoggingProfiler.profile_fun), ex.args...)),
#         Expr(:call, :(LoggingProfiler.record_end), s),
#         r,
#     ]
#     Expr(:block, b...)
# end
