function pile_re(n)
    function refunc(e)
        h = length(e)
        return n * h / 2 * [1; 1]
    end
    return refunc
end

function pile_ke(EA, C)
    function kefunc(e)
        h = length(e)
        k1 = EA / h * [1 -1; -1 1]
        k2 = C * h / 6 * [2 1; 1 2]
        return k1 + k2
    end
    return kefunc
end

force(F) = _ -> [F]

spring(S) = _ -> [S]
