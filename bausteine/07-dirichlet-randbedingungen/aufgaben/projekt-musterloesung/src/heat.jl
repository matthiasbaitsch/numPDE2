include("fem.jl")

function heat_ke(λ)
    function kefunc(e)
        A = area(e)
        B = grad_n(e)'
        return λ * A * B' * B
    end
    return kefunc
end

function heat_me(ρ, c)
    function mefunc(e)
        A = area(e)
        return A * ρ * c / 12 * [2 1 1; 1 2 1; 1 1 2]
    end
    return mefunc
end

function heat_re(w)
    function refunc(e)
        A = area(e)
        return w * A / 3 * ones(3)
    end
    return refunc
end

function robin_ke(h)
    function kefunc(g)
        return h * length(g) / 6 * [2 1; 1 2]
    end
    return kefunc
end

function robin_re(h, ts)
    function refunc(g)
        return h * ts * length(g) / 2 * [1; 1]
    end
    return refunc
end

