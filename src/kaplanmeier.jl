"""
    KaplanMeier

An immutable type containing survivor function estimates computed
using the Kaplan-Meier method.
The type has the following fields:

* `times`: Distinct event times
* `nevents`: Number of observed events at each time
* `ncensor`: Number of right censored events at each time
* `natrisk`: Size of the risk set at each time
* `survival`: Estimate of the survival probability at each time
* `stderr`: Standard error of the log survivor function at each time

Use `fit(KaplanMeier, ...)` to compute the estimates and construct
this type.
"""
struct KaplanMeier{T<:Real} <: NonparametricEstimator
    times::Vector{T}
    nevents::Vector{Int}
    ncensor::Vector{Int}
    natrisk::Vector{Int}
    survival::Vector{Float64}
    stderr::Vector{Float64}
end

estimator_start(::Type{KaplanMeier}) = 1.0  # Estimator starting point
stderr_start(::Type{KaplanMeier}) = 0.0 # StdErr starting point

estimator_update(::Type{KaplanMeier}, es, dᵢ, nᵢ) = es * (1 - dᵢ / nᵢ) # Estimator update rule
stderr_update(::Type{KaplanMeier}, gw, dᵢ, nᵢ) = gw + dᵢ / (nᵢ * (nᵢ - dᵢ)) # StdErr update rule

"""
    confint(km::KaplanMeier, α=0.05)

Compute the pointwise log-log transformed confidence intervals for the survivor
function as a vector of tuples.
"""
function StatsBase.confint(km::KaplanMeier, α::Float64=0.05)
    q = quantile(Normal(), 1 - α/2)
    return map(km.survival, km.stderr) do srv, se
        l = log(-log(srv))
        a = q * se / log(srv)
        exp(-exp(l - a)), exp(-exp(l + a))
    end
end

"""
    fit(KaplanMeier, times, status) -> KaplanMeier

Given a vector of times to events and a corresponding vector of indicators that
dictate whether each time is an observed event or is right censored, compute the
Kaplan-Meier estimate of the survivor function.
"""
StatsBase.fit(::Type{KaplanMeier}, times, status)
