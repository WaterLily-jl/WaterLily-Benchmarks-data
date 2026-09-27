# TGV at Re=1600 for one WaterLily version, as in WaterLily.jl_CPC_2024/jl/validation/tgv.jl
# (same case, Float64, CuArray, t_max=20, same kinetic energy and dissipation definitions).
# Usage: julia +1.11.5 --project=<environment with WaterLily, CUDA and JLD2> tgv_run.jl <label> <p>
using WaterLily, CUDA, JLD2, Printf

function tgv(p, backend; Re=1600, T=Float32)
    L = 2^p; U = 1; κ=π/L; ν = 1/(κ*Re)
    function uλ(i,xyz)
        x,y,z = @. (xyz-0.0)/L*π
        i==1 && return -U*sin(x)*cos(y)*cos(z)
        i==2 && return  U*cos(x)*sin(y)*cos(z)
        return 0.
    end
    ic = pkgversion(WaterLily) < v"1.8" ? (; uλ) : (; u0=uλ) # the keyword is `u0` from WaterLily 1.8
    Simulation((L, L, L), (0, 0, 0), 1/κ; U=U, ν=ν, T=T, mem=backend, ic...)
end

function EZ!(σ, u, ν, L)
    Ω = prod(size(inside(σ)))
    @inside σ[I] = WaterLily.ke(I, u)
    KE = mapreduce(identity,+,@inbounds(σ[inside(σ)]))
    @inside σ[I] = WaterLily.ω_mag(I, u)
    Z = mapreduce(abs2,+,@inbounds(σ[inside(σ)]))
    return KE/Ω, Z*ν*L/Ω
end

function main(p, backend; Re=1600, T=Float32, t_max=20.0)
    sim = tgv(p, backend; Re=Re, T=T)
    E0, Z0 = EZ!(sim.flow.σ, sim.flow.u, sim.flow.ν, sim.L)
    E, Z, t = T[E0], T[Z0], T[0.0]
    while WaterLily.time(sim.flow)*(sim.U/sim.L) < t_max
        sim_step!(sim; remeasure=false)
        Ei, Zi = EZ!(sim.flow.σ, sim.flow.u, sim.flow.ν, sim.L)
        push!(E, Ei); push!(Z, Zi); push!(t, WaterLily.time(sim.flow)*(sim.U/sim.L))
        length(t) % 200 == 0 && @printf("  step %5d  tU/L=%7.3f  Δt=%.3f\n", length(t)-1, t[end], sim.flow.Δt[end])
    end
    return E, Z, t
end

label, p = ARGS[1], parse(Int, ARGS[2])
commit = strip(read(`git -C $(pkgdir(WaterLily)) rev-parse --short HEAD`, String))
println("WaterLily $label ($(pkgversion(WaterLily)), $commit) from $(pkgdir(WaterLily)), p=$p, Julia $VERSION, ", CUDA.name(CUDA.device()))
walltime = @elapsed E, Z, t = main(p, CuArray; Re=1600, T=Float64, t_max=20.0)
@printf("done: %d steps in %.1f s\n", length(t)-1, walltime)
jldsave(joinpath(@__DIR__, "data", "tgv_p$(p)_$(label).jld2"); E, Z, t, p, label, commit, version=string(pkgversion(WaterLily)), walltime)
