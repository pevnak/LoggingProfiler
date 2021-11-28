struct WhiteBlackLists
    whitelist_module::Indices{Module}
    whitelist_function::Indices{Symbol}
    whitelist_globalref::Indices{Core.GlobalRef}
    blacklist_module::Indices{Module}
    blacklist_function::Indices{Symbol}
    blacklist_globalref::Indices{Core.GlobalRef}
end

function iswhite(l::WhiteBlackLists, ex::GlobalRef)
    ex.mod ∈ l.whitelist_module && return(true)
    ex ∈ l.whitelist_globalref && return(true)
    ex.name ∈ l.whitelist_function && return(true)
    return(false)
end

function isblack(l::WhiteBlackLists, ex::GlobalRef)
    ex.mod ∈ l.blacklist_module && return(true)
    ex ∈ l.blacklist_globalref && return(true)
    ex.name ∈ l.blacklist_function && return(true)
    return(false)
end

function Base.isempty(l::WhiteBlackLists)
    l.isempty(whitelist_module) && l.isempty(whitelist_function) && l.isempty(whitelist_function)
end
