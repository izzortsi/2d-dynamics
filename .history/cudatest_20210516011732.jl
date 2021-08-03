# %%

using CUDA
# %%
a = CUDA.fill(0, 100)
da = similar(a)
# %%

# %%
function kernel_zip!(f, out, a, b)
    i = threadIdx().x
    out[i] = f(a[i], b)
    return
  end
# %%
function f_sin!(out, a)
    i = threadIdx().x
    out[i] = CUDA.sin(a[i])
    return
  end
  # %%
  
  function f_sin!(f, out, a, b)
    i = threadIdx().x
    out[i] = f(a[i], b)
    out[i] = CUDA.sin(out[i])
    return
  end
#@cuda (1, length(xs)) kernel_zip2(+, zs, xs, ys)
# %%
#f_dot(f, a, threads) = @cuda launch=false dynamic=true kernel_zip!(f, a, a, a[i])
# %%

function kernel(a, da)
    i = threadIdx().x
    #f_dot(-, a, length(a))
    #@cuda threads=length(a) dynamic=true kernel_zip!(-, da, a, a[i])
    #sync_threads()
    #a = da
    @cuda threads=length(a) dynamic=true f_sin!(-, da, a, a[i])
    sync_threads()
    #a[i] += 1
    return nothing
end
# %%

@cuda threads=length(a) kernel(a, da)
# %%

# %%

a