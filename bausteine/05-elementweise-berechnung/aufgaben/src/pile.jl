function pile_ke(EA, C)
    function kefunc(e)
        h = length(e)
        return EA / h * [1 -1; -1 1] + C * h / 6 * [2 1; 1 2]
    end
    return kefunc
end

function pile_re(n)
    function refunc(e)
        h = length(e)
        return n * h / 2 * [1, 1]
    end
    return refunc
end

function spring(S)
    function kefunc(n)
        return [S]
    end
    return kefunc
end

function force(F)
    function refunc(n)
        return [F]
    end
    return refunc
end
