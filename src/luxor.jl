using Luxor, Colors
_depth(ev::Dict) = haskey(ev, :children) ? 1 + _depth(ev[:children]) : 1
_depth(evs::Vector) = isempty(evs) ? 0 : maximum(_depth(ev) for ev in evs)

function drawevent(ev::Dict, y, offset, δ, colormap, rect_height, cols)
    c = get!(colormap, ev[:name], rand(cols))
    sethue(c)
    x₁ = δ*(ev[:start] - offset)
    x₂ = δ*(ev[:stop] - offset)    
    points = [Point(x₁, y), Point(x₂, y), Point(x₂, y + rect_height), Point(x₁, y + rect_height)]
    poly(points, :fill)
    haskey(ev, :children) && drawevent(ev[:children], y + rect_height, offset, δ, colormap, rect_height, cols)
end

function drawevent(evs::Vector, y, offset, δ, colormap, rect_height, cols) 
    !isempty(evs) && foreach(ev -> drawevent(ev, y, offset, δ, colormap, rect_height, cols), evs)
end

"""
    export2luxor(filename::String; width = 2000, height = 800)

    Export the execution profile to a figure using Luxor. 
    Return colormap mapping name of the function to colors, which
    I do not know, how to export
"""
function export2luxor(filename::String; width = 2000, height = 800)
    thev = map(LoggingProfiler.tape2structure, LoggingProfiler.to)
    start = minimum(first(e)[:start] for e in thev)
    stop = maximum(last(e)[:stop] for e in thev)
    δ =  width / (stop - start)
    colormap = Dict()
    cols = distinguishable_colors(100)
    depths = [_depth(ev) for ev in thev]
    rect_height = fld(height, sum(d + 1 for d in depths) - 1)

    hoffset = 0
    Drawing(width, height, filename)
    background("white")
    for (ev, d) in zip(thev, depths)
        drawevent(ev, hoffset, start, δ, colormap, rect_height, cols)
        hoffset += (d + 1) * rect_height
    end
    finish()
    colormap
end
