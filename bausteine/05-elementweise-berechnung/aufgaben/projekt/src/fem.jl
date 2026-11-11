using SparseArrays
using LinearAlgebra

function assemble_kr(m)
    N = nnodes(m)
    K = zeros(N, N)
    r = zeros(N)

    for e = entities(m)
        I = nodeindices(e)
        if hasdata(e, :ke_func) 
            kef = data(e, :ke_func)
            K[I, I] += kef(e)
        end
        if hasdata(e, :re_func) 
            ref = data(e, :re_func)
            r[I] += ref(e)
        end
    end

    return K, r
end
