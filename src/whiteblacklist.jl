struct WhiteBlackLists
    whitelist_module::Indices{Module}
    whitelist_function::Indices{Symbol}
    whitelist_globalref::Indices{Core.GlobalRef}
    blacklist_module::Indices{Module}
    blacklist_function::Indices{Symbol}
    blacklist_globalref::Indices{Core.GlobalRef}
end

function WhiteBlackLists() 
    WhiteBlackLists(Indices{Module}(), Indices{Symbol}(), Indices{Core.GlobalRef}(), 
        Indices{Module}(), Indices{Symbol}(), Indices{Core.GlobalRef}())
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
    isempty(l.whitelist_module) && isempty(l.whitelist_function) && isempty(l.whitelist_function)
end


whitelist!(l::WhiteBlackLists, ex::GlobalRef) = insert!(l.whitelist_globalref, ex)
whitelist!(l::WhiteBlackLists, ex::Symbol) = insert!(l.whitelist_function, ex)
whitelist!(l::WhiteBlackLists, ex::Module) = insert!(l.whitelist_module, ex)
blacklist!(l::WhiteBlackLists, ex::GlobalRef) = insert!(l.blacklist_globalref, ex)
blacklist!(l::WhiteBlackLists, ex::Symbol) = insert!(l.blacklist_function, ex)
blacklist!(l::WhiteBlackLists, ex::Module) = insert!(l.blacklist_module, ex)
