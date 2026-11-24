using SparseArrays
using LinearAlgebra

function assemble_kr(m)
    N = nnodes(m)
    K = zeros(N, N)
    r = zeros(N)

    for e = entities(m)
        I = nodeindices(e)
        if hasdata(e, :kefunc)
            kef = data(e, :kefunc)
            K[I, I] += kef(e)
        end
        if hasdata(e, :refunc)
            ref = data(e, :refunc)
            r[I] += ref(e)
        end
    end

    return K, r
end
