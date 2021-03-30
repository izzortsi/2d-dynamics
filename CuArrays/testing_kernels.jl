##
using CUDA
using LinearAlgebra
using Plots
using Dates
using Images, TestImages, Colors
using OffsetArrays
##
CUDA.allowscalar(false)
##
function convolution(n, A, filter, outs, kdim)

    indx = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    stridex = blockDim().x * gridDim().x

    indy = (blockIdx().y - 1) * blockDim().y + threadIdx().y
    stridey = blockDim().y * gridDim().y

    for i in indx:stridex:n, j in indy:stridey:n
        ran = kdim ÷ 2
        # indices for the neighbors
        j_minus = mod1(j - ran, n)
        j_plus = mod1(j + ran, n)
        i_minus =  mod1(i - ran, n)
        i_plus = mod1(i + ran, n)

        for s in j_minus:j_plus, t in i_minus:i_plus
            s1 = s - j + (ran + 1)
            t1 = t - i + (ran + 1)
            outs[i, j] += (A[s, t] * filter[s1, t1])
        end

    end

    return nothing
end
##
5 ÷ 2
##
function loop_filter(niter, A, filter, kdim)
    for i in 1:niter
        outs = CUDA.zeros(n, n)
        @cuda blocks = (numblocks, numblocks) threads = (threads, threads) convolution(n, A, filter, outs, kdim)
        A = outs
    end
    return A
end

##

img = testimage("mandril");
img = Gray.(img);
img = imrotate(imresize(img, ratio=2 / 3), π);
##
img = OffsetArray(img, 1:344, 1:344)
img = convert(Array{Float64}, img);
A = cu(img)
##
n, = size(img)

##
dev = CuDevice(0)

max_threads = attribute(dev, CUDA.DEVICE_ATTRIBUTE_MAX_THREADS_PER_BLOCK)
max_threads_per_dim = sqrt(max_threads) / 2 |> Int

numblocks = ceil(Int, n / max_threads_per_dim)
threads = n ÷ numblocks
##
# heatmap(A)
##
outs = CUDA.zeros(n, n)
filter = cu([0.5 0.5 0.5 0.5 0.5;
             0.5 1. 1 1 0.5; 
             1 1 1 1 1; 
             0.5 1 1 1 0.5; 
             0.5 0.5 0.5 0.5 0.5] ./ 18)

kdim, = size(filter)
##
# filter=CuDeviceArray((3, 3), [1. 1 1; 1 1 1; 1 1 1] ./ 9)
##

##
conv(n, A, filter, outs, kdim) = @cuda blocks = (numblocks, numblocks) threads = (threads, threads) convolution(n, A, filter, outs, kdim)
##
##
output = loop_filter(10, A, filter, kdim)

##
hostouts = Array(output)
##
heatmap(hostouts, clims=(0, 1))
##
output = loop_filter(100, output, filter)
##
heatmap(output, clims=(0, 1))
##