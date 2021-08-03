# %%
using Random
using DifferentialEquations
#using GLMakie
using Plots
# %%
using CUDA
CUDA.allowscalar(false)
# %%

# %%

#Random.seed!(0)
# %%
# %%


n = 2^6
const N = n ^ 2
const K = 2
ω = CUDA.randn(n, n) #* 2π
θ = CUDA.randn(n, n) #* 2π

# %%

function setup_kernel(n::Int64)
    dev = CuDevice(0)
    
    max_threads = attribute(dev, CUDA.DEVICE_ATTRIBUTE_MAX_THREADS_PER_BLOCK)
    max_threads_per_dim = sqrt(max_threads) / 2 |> Int
    
    numblocks = ceil(Int, n / max_threads_per_dim)
    threads = n ÷ numblocks
    
    return numblocks, threads
end
# %%

nblocks, nthreads = setup_kernel(n)

# %%

const N_BLOCKS = nblocks
const N_THREADS = nthreads

# %%
function f_sin!(f, out, a, b)
    i = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    j = (blockIdx().y - 1) * blockDim().y + threadIdx().y
    out[i, j] = f(a[i, j], b)
    sync_threads()
    out[i, j] = CUDA.sin(out[i, j])
    return
  end

function kernel(a, o, da)
    i = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    j = (blockIdx().y - 1) * blockDim().y + threadIdx().y
    @cuda blocks = (N_BLOCKS, N_BLOCKS) threads = (N_THREADS, N_THREADS) dynamic=true f_sin!(-, da, a, a[i, j])
    sync_threads()
    da[i, j] = o[i, j] + (K/N)*sum(da)
    #sync_threads()
    #a[i, j] = da[i, j]
    return nothing
end
# %%

# %%
#a = CUDA.rand(100)
#o = CUDA.rand(100)
#da = similar(a)
# %%


# %%


kura_gpu!(θ, ω, dθ) = @cuda blocks = (N_BLOCKS, N_BLOCKS) threads = (N_THREADS, N_THREADS) kernel(θ, ω, dθ)
# %%
#@cuda blocks = (N_BLOCKS, N_BLOCKS) threads = (N_THREADS, N_THREADS) kernel(θ, ω, dθ)
# %%

#kura_gpu!(θ, ω, dθ)
# %%

function kuramoto!(dθ, θ, p, t)
    kura_gpu!(θ, ω, dθ)
    #dθ
end
# %%
# %%
# %%

#kuramoto!(dθ, nothing, 1)
# %%

tspan = (0.0,2.0)

#prob = ODEProblem(kuramoto!, dθ, tspan)
prob = ODEProblem(kuramoto!, θ, tspan, scale_by_time=false)
# %%

sol = solve(prob, adaptive=false, dt=0.1);   

# %%
# for (i, u) in enumerate(sol.u[end-50:end])
#     if i > 1
#         println(sum(u[i]-u[i-1]))
#     end
# end
sol.t
##
sols = sol.u .|> Array
# %%
sols

# %%

sol.t
##
n_frames = length(sol.t)

# %%

# %%

# %%

for i in 1:n_frames
    fig = heatmap(sols[i], clims=(0, 2π))    
    savefig(fig, "frame$(i).png")
end
# %%


# %%
# fig, ax, hm = heatmap(sol.u[1])
# n_frames = length(sol.t)
# framerate = n_frames ÷ 7
# ax[1]
# %%


# record(fig, "test.mp4", framerate=framerate) do io
#     for i = 1:n_frames
#         heatmap!(sol.u[i])    
#         recordframe!(io)  # record a new frame
#     end
# end

# if i != 1
#     println(sum(sol.u[i] - sol.u[i-1]))
# end
# %%
# for i in 1:n_frames
#     fig, ax, hm = heatmap(sol.u[i])    
#     save("frame$(i).png", fig)
# end
# heatmap(sol.u[20])