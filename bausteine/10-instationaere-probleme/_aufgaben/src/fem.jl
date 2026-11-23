using SparseArrays
using LinearAlgebra

function dofs(nodes, Nf)
    dofs = []
    for i = nodes, j = 1:Nf
        append!(dofs, (i - 1) * Nf + j)
    end
    return dofs
end

function grad_n(e)
    A = area(e)
    x = coordinates(e)
    u = x[:, 2] - x[:, 1]
    v = x[:, 3] - x[:, 2]
    w = x[:, 1] - x[:, 3]

    return 1 / (2A) * [
        -v[2] v[1]
        -w[2] w[1]
        -u[2] u[1]
    ]
end

function nf(m)
    e1 = element(m, 1)
    ke = data(e1, :ke_func)(e1)
    return Int(size(ke, 1) / nnodes(e1))
end

function assemble_kr(m)
    Nf = nf(m)
    N = Nf * nnodes(m)
    K = zeros(N, N)
    r = zeros(N)

    for e = entities(m)
        I = dofs(nodeindices(e), Nf)
        hasdata(e, :ke_func) && (K[I, I] += data(e, :ke_func)(e))
        hasdata(e, :re_func) && (r[I] += data(e, :re_func)(e))
    end

    return sparse(K), r
    # return K, r
end

function assemble_kmr(m)
    N = nnodes(m)
    K = zeros(N, N)
    M = zeros(N, N)
    r = zeros(N)

    for e = entities(m)
        I = dofs(nodeindices(e), Nf)
        hasdata(e, :ke_func) && (K[I, I] += data(e, :ke_func)(e))
        hasdata(e, :me_func) && (M[I, I] += data(e, :me_func)(e))
        hasdata(e, :re_func) && (r[I] += data(e, :re_func)(e))
    end

    return sparse(K), sparse(M), r
end

function apply_dirichlet_bcs!(K, r, dofs, v=0)
    println(dofs)
    K[dofs, :] .= 0
    r[dofs] .= v
    K[diagind(K)[dofs]] .= 1
    nothing
end
