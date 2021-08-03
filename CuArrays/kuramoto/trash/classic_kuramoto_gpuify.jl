# %%
using Random
#using DifferentialEquations
#using GLMakie
#using Plots
using KernelAbstractions, CUDA, CUDAKernels

# %%
CUDA.allowscalar(false)
# %%

Random.seed!(0)
# %%

# %%


n = 16
N = n ^ 2
#K = 2
#ω = rand(n, n) * 2 * π |> cu
dθ = rand(N) * 2 * π |> cu
# %%

# %%
dyn_sin = CUDA.dynamic_cufunction(x -> map(sin, x))
# %%

@kernel function kuramoto_kernel1!(θ)
    I = @index(Global)
    diff = dyn_sin(θ)
    θ[I] = sum(θ)
end
# %%
kernel = kuramoto_kernel1!(CUDADevice(), 16)
# %%
event = kernel(dθ, ndrange=N)
# %%

# %%
wait(event)
# %%

kuramoto_kernel!(dθ, nothing, nothing)

# %%

function kuramoto!(dθ, p, t)
    kura_gpu!(dθ, p, t)
    dθ
end
# %%

# %%
# %%

kuramoto!(dθ, ω, 1)
# %%

tspan = (0.0,5.0)

prob = ODEProblem(kuramoto!, dθ, tspan)
# %%

sol = solve(prob);   

# %%
# for (i, u) in enumerate(sol.u[end-50:end])
#     if i > 1
#         println(sum(u[i]-u[i-1]))
#     end
# end

n_frames = length(sol.t)

# %%

# %%

# %%

for i in 1:n_frames
    fig = heatmap(sol.u[i], clims=(0, 2π))    
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