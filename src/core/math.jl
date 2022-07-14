Base.abs(x::GF2) = x
Base.isless(x::GF2, y::GF2) = isless(x.n, y.n)
Base.conj(x::GF2) = x