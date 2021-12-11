using Luxor, Colors, ProfileSVG
using ProfileSVG: FGConfig, bgcolor, fontcolor, 
    write_svgheader, write_svgfooter, write_svgflamerect

_depth(ev::Dict) = haskey(ev, :children) ? 1 + _depth(ev[:children]) : 1
_depth(evs::Vector) = isempty(evs) ? 0 : maximum(_depth(ev) for ev in evs)

function drawevent(ev::Dict, y, offset, δ, colormap, ystep, cols)
    c = get!(colormap, ev[:name], rand(cols))
    sethue(c)
    x₁ = δ*(ev[:start] - offset)
    x₂ = δ*(ev[:stop] - offset)    
    points = [Point(x₁, y), Point(x₂, y), Point(x₂, y + ystep), Point(x₁, y + ystep)]
    poly(points, :fill)
    haskey(ev, :children) && drawevent(ev[:children], y + ystep, offset, δ, colormap, ystep, cols)
end

function drawevent(evs::Vector, y, offset, δ, colormap, ystep, cols) 
    !isempty(evs) && foreach(ev -> drawevent(ev, y, offset, δ, colormap, ystep, cols), evs)
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
    ystep = fld(height, sum(d + 1 for d in depths) - 1)

    yoffset = 0
    Drawing(width, height, filename)
    background("white")
    for (ev, d) in zip(thev, depths)
        drawevent(ev, yoffset, start, δ, colormap, ystep, cols)
        yoffset += (d + 1) * ystep
    end
    finish()
    colormap
end

function drawevent_svg(io::IO, ev::Dict, y, offset, δ, colormap, ystep, cols)
    color = get!(colormap, ev[:name], rand(cols))
    x = δ*(ev[:start] - offset)
    w =  δ*(ev[:stop]  - ev[:start])    
    shortinfo = "$(ev[:name])"
    dirinfo = "$(ev[:start]) - $(ev[:stop]) ($(w))"
    roundradius = 2
    write_svgflamerect(io, x, y, w, ystep, roundradius, shortinfo, dirinfo, color, true)
    haskey(ev, :children) && drawevent_svg(io, ev[:children], y + ystep, offset, δ, colormap, ystep, cols)
end

function drawevent_svg(io::IO, evs::Vector, y, offset, δ, colormap, ystep, cols) 
    !isempty(evs) && foreach(ev -> drawevent_svg(io, ev, y, offset, δ, colormap, ystep, cols), evs)
end


"""
    export2svg(filename::String; width = 2000, height = 800)

    Export the execution profile to an SVG hijacking the ProfileSVG
    infrastructure.
"""
function export2svg(filename::String; width = 2000, height = 800, fontsize = 12)
    fg = ProfileSVG.FGConfig()
    thev = map(LoggingProfiler.tape2structure, LoggingProfiler.to)
    start = minimum(first(e)[:start] for e in thev)
    stop = maximum(last(e)[:stop] for e in thev)
    δ =  width / (stop - start)
    colormap = Dict()
    cols = distinguishable_colors(100)
    depths = [_depth(ev) for ev in thev]
    ystep = fld(height, sum(d + 1 for d in depths) - 1)
    fig_id = "profilerview"
    open(filename, "w") do io 
        write_svgheader(io, fig_id, width, height,
                bgcolor(fg), fontcolor(fg), fg.frameopacity,
                fg.font, fg.fontsize, fg.notext, δ, fg.timeunit, fg.delay)

        yoffset = 0
        for (ev, d) in zip(thev, depths)
            drawevent_svg(io, ev, yoffset, start, δ, colormap, ystep, cols)
            yoffset += (d + 1) * ystep
        end
        write_svgfooter(io, fig_id)
    end
end



