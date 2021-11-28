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

blacklist!(LoggingProfiler.timable_list, Core)
blacklist!(LoggingProfiler.timable_list, Base)
whitelist!(LoggingProfiler.recursable_list, :juliaset_column!)
whitelist!(LoggingProfiler.recursable_list, :juliaset_single!!)
LoggingProfiler.initbuffer!(1000)
juliaset(-0.79, 0.15, 10, juliaset_static!)
LoggingProfiler.recorded()
LoggingProfiler.adjustbuffer!()
juliaset(-0.79, 0.15, 10, juliaset_static!)
# 53828
LoggingProfiler.export2luxor("/tmp/profile.png")