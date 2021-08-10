##
using CUDA
using LinearAlgebra
using Dates
using Images, TestImages, Colors
using OffsetArrays
using GLMakie
using NNlibCUDA
##
include("aux_funs.jl")
using .Aux
##
CUDA.allowscalar(false)
##
function frames(
    state, niter; 
    ckern=cu([1. 1 1; 1 0 1; 1 1 1]), 
    bin=Float32(0.93), 
    e=Float32(0.66), 
    r=Float32(1.3), 
    k=Float32(0.0)
        )
    state_seq = [state]
    for i = 1:niter
        state = state_seq[end]
        S = (state .>= bin) .* state # the spiking neurons
        nS = (state .< bin) .* state # the complimentary matrix
        spike = nS .+ (r .* S)
        #println(typeof(spike))
        convolved = NNlibCUDA.conv(spike, ckern, pad = 1) ./ Float32(8)
        #conv(n, spike, ckern, convolved, kdim) # the spiking neuron have a 1.3fold greater influence over its neighbors
        state = e .* (nS .+ (k .* S)) .+ (Float32(1) - e) .* convolved  # (nS + k*S) is the initial state but with the spiking neurons' states updated; (1-e)*conv is the influence the neighbors had over the neuron
        #e*(nS + k*S) + (1-e)*conv
        # state = e * (( r * nS) + (k * S)) + (1 - e) * convolved # (nS + k*S) is the initial state but with the spiking neurons' states updated; (1-e)*conv is the influence the neighbors had over the neuron
        push!(state_seq, deepcopy(state))
    end
    return state_seq
end
##
const n = 250
##


bin=0.93
e=0.66
b=1.01

r=1.3
k=0.0
a=0.909

niter = 700
##

##

ckern_expr = :([b * a b b * a; b e * b b; b * a b b * a])
ckern = eval(ckern_expr)


#%%
ckern = cu(reshape(ckern[:], (3, 3, 1, 1)))
#%%
#ckern ./= (sum(ckern) / ρ)
##
init_state = CUDA.rand(n, n, 1, 1)
#%%
#rkern = CUDA.rand( 5, 5, 1, 1)
# #%%
# NNlibCUDA.conv(init_state, ckern, pad = 1)
# #%%
# S = (init_state .>= bin) .* init_state
# #%%
# nS = (init_state .< bin) .* init_state # th
# #%%
# spike = nS + (Float32(r) * S)

# #%%
# NNlibCUDA.conv(spike, ckern, pad = 1)
#%%





##
@elapsed flist = frames(init_state, niter, ckern=ckern)
#%%
#flist
#%%


@elapsed host_outs = Array.(flist)
##
host_outs
#%%
host_outs[1][:,:]
#%%
h_outs = [frame[:,:] for frame in host_outs]
#%%


params = Dict()
push!(params, "a" => a)
push!(params, "b" => b)
push!(params, "kerpattern" => string(ckern_expr))
#%%


field = Node(h_outs[10])
fig, hm = GLMakie.heatmap(field, colorrange=(0,1))
#%%
fig
#%%

makie_record(fig, field, h_outs, params, niter, "spiking")