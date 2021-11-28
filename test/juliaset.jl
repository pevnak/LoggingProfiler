using LoggingProfiler
function juliaset_pixel(z₀, c)
    z = z₀
    for i in 1:255
        abs2(z)> 4.0 && return (i - 1)%UInt8
        z = z*z + c
    end
    return UInt8(255)
end

function juliaset_column!(img, c, n, j)
    x = -2.0 + (j-1)*4.0/(n-1)
    for i in 1:n
        y = -2.0 + (i-1)*4.0/(n-1)
        @inbounds img[i,j] = juliaset_pixel(x+im*y, c)
    end
    nothing
end

function juliaset_single!(img, c, n)
    for j in 1:n
        juliaset_column!(img, c, n, j)
    end
    nothing
end

function juliaset_static!(img, c, n)
    Threads.@threads for j in 1:n
        @record juliaset_column!(img, c, n, j)
    end
    nothing
end

function juliaset(x, y, n=1000, method = juliaset_single!, extra...)
    c = x + y*im
    img = Array{UInt8,2}(undef,n,n)
    method(img, c, n, extra...)
    return img
end

# @record juliaset(-0.79, 0.15, 10)
# without any filter this makes 
# LoggingProfiler.recorded()
# 144

# blacklist!(LoggingProfiler.timable_list, Core)
# blacklist!(LoggingProfiler.timable_list, Base)
# whitelist!(LoggingProfiler.recursable_list, :juliaset_column!)
# whitelist!(LoggingProfiler.recursable_list, :juliaset_single!!)
LoggingProfiler.initbuffer!(1000)
juliaset(-0.79, 0.15, 10, juliaset_static!)
LoggingProfiler.recorded()
LoggingProfiler.adjustbuffer!()
juliaset(-0.79, 0.15, 10, juliaset_static!)
# 53828
thev = map(LoggingProfiler.tape2structure, LoggingProfiler.to)

using Luxor, Colors
_depth(ev::Dict) = haskey(ev, :children) ? 1 + _depth(ev[:children]) : 1
_depth(evs::Vector) = isempty(evs) ? 0 : maximum(_depth(ev) for ev in evs)

function drawevent(ev::Dict, y, offset, δ, colormap, rectangle_height)
    c = get!(colormap, ev[:name], rand(cols))
    sethue(c)
    x₁ = (ev[:start] - offset) * δ
    x₂ = (ev[:stop] - offset) * δ    
    points = [Point(x₁, y), Point(x₂, y), Point(x₂, y + rectangle_height), Point(x₁, y + rectangle_height)]
    poly(points, :fill)
    haskey(ev, :children) && drawevent(ev[:children], y + rectangle_height, offset, δ, colormap, rectangle_height)
end

function drawevent(evs::Vector, y, offset, δ, colormap, rectangle_height) 
    !isempty(evs) && foreach(ev -> drawevent(ev, y, offset, δ, colormap, rectangle_height), evs)
end

start = minimum(first(e)[:start] for e in thev)
stop = maximum(last(e)[:stop] for e in thev)
width = 2000
height = 800
δ =  width / (stop - start)
colormap = Dict()
cols = distinguishable_colors(100)
depths = [_depth(ev) for ev in thev]
rectangle_height = fld(height, sum(d + 1 for d in depths))


hoffset = 0 
Drawing(height, width, "/tmp/profiler.svg")
for (ev, d) in zip(thev, depths)
    drawevent(ev, hoffset, start, δ, colormap)
    hoffset += (d + 1)*rectangle_height
end
finish()


# for (i, t) in enumerate(LoggingProfiler.to)
#     events = LoggingProfiler.tape2structure(t)
#     LoggingProfiler._visualize("/tmp/test_$(i).html", events)
# end

# LoggingProfiler.clear!()
# juliaset(-0.79, 0.15, 10, juliaset_static!)
# LoggingProfiler.recorded()
# 157368