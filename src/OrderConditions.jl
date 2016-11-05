module OrderConditions

using Giac
using Combinatorics



# package code goes here

function gen_exp_tBt_derivatives_coeffs(N::Integer)
    A = [Dict{Array{Int64,1},Int64}([0]=>1)]
    for n = 2:N
        a0 = A[n-1]
        # a1 = a0*C:
        a1 = [vcat(key, 0)=>val for (key,val) in a0]
        # a1 = a1 + (d/dt)a0:
        for (p,c) in a0
            for j = 1:length(p)
                q = copy(p)
                q[j] += 1
                d = get(a1, q, 0)
                a1[q] = d+c
            end            
        end                
        push!(A, a1)
    end
    A
end


function gen_C_derivatives_at_0(N::Integer)
    A = Array{Dict{Array{Int64,1},Int64},1}[[Dict(vcat(zeros(Int64,k),1)=>1)] for k=1:N-1]
    for k = 1:N-1        
        for l = 1:N-k-1
            a0 = A[k][l]
            a1 = Dict{Array{Int64,1},Int64}()
            for (p,c) in a0
                for j=1:length(p)
                    q = copy(p)
                    q[j] += 1
                    if q[end] != q[end-1]
                        d = get(a1, q, 0)
                        a1[q] = d+c
                    end    
                end            
            end                           
            push!(A[k], a1)
        end
    end
    C = [Dict{Array{Int64,1},Rational{Int64}}([l]=>(l==0?1:2)) for l=0:N]
    for n = 2:N
        fac = 1
        a1 = C[n+1]
        for k=1:n-1
            fac *= (k+1)
            a0 = A[k][n-k-1+1]
            for (p,c) in a0
                d = get(a1, p, 0//1)
                a1[p] = d+c//fac
            end                                   
        end        
        C[n+1] = a1
    end    
    #A,C
    C
end


function gen_C_derivatives_at_0_in_terms_of_A(N::Integer, a::Array{giac,1}, c::Array{giac,1})
    C_derivatives_at_0=gen_C_derivatives_at_0(N)
    C1 = [Dict{Array{Int64,1},giac}() for n=0:N]
    for n = 0:N
        a0 = C_derivatives_at_0[n+1]
        a1 = C1[n+1]
        for (p,coeff) in a0
            c1 = giac(coeff)
            for j =1:length(p)
                c1 = c1*sum([a[l]*c[l]^p[j] for l=1:length(c)])                
            end
            C1[n+1][p] = c1
        end
    end
    C1
end


function mult(x::Dict{Array{Array{Int64,1},1},Giac.giac}, y::Dict{Array{Int64,1},Giac.giac})
    r = Dict{Array{Array{Int64,1},1},Giac.giac}()
    for (p,c) in x
        for (q, d) in y
            pq = copy(p)
            push!(pq, q)
            r[pq] = c*d
        end
    end     
    r
end


function mult(x::Dict{Array{Array{Int64,1},1},Giac.giac}, y::Dict{Array{Array{Int64,1},1},Giac.giac})
    r = Dict{Array{Array{Int64,1},1},Giac.giac}()
    for (p,c) in x
        for (q, d) in y
            pq = vcat(p,q)
            r[pq] = c*d
        end
    end     
    r
end


function add(x::Dict{Array{Array{Int64,1},1},Giac.giac}, y::Dict{Array{Array{Int64,1},1},Giac.giac})
    r = copy(x)
    for (p,c) in y
        d = get(r, p, 0)
        r[p] = c+d
    end
    r
end


function gen_exp_tBt_derivatives_at_0_in_terms_of_A(N::Integer, a::Array{giac,1}, c::Array{giac,1}) 
    C_derivatives_at_0_in_terms_of_A=gen_C_derivatives_at_0_in_terms_of_A(N-1, a, c)
    exp_tBt_derivatives_coeffs=gen_exp_tBt_derivatives_coeffs(N)
    r = Dict{Array{Array{Int64,1},1},Giac.giac}[]
    for n = 1:N
        y = Dict{Array{Array{Int64,1},1},Giac.giac}()
        for (p,d) in exp_tBt_derivatives_coeffs[n]
            x = Dict{Array{Array{Int64,1},1},Giac.giac}(
            [Array[p1]=>d*d1 for (p1,d1) in C_derivatives_at_0_in_terms_of_A[p[1]+1]])
            for i = 2:length(p)
                x = mult(x, C_derivatives_at_0_in_terms_of_A[p[i]+1])
            end  
            y = add(y, x)
        end
        push!(r,y)
    end
    r
end


multinomial_coeff(q::Int, k::Array{Int,1}) = div(factorial(q), prod([factorial(i) for i in k]))


function gen_order_conditions(N::Integer,J::Integer, K::Integer)
    a = [giac[giac(string("a",j,k)) for k=1:K] for j=1:J]
    c = giac[giac(string("c",k)) for k=1:K] 
    C = gen_exp_tBt_derivatives_at_0_in_terms_of_A(N, a[1], c) 
    for q=1:N-1
        for k0 in Combinatorics.WithReplacementCombinations(1:J,q+1)
            k = zeros(Int,s)
            for j in k0
                k[j]+=1
            end
            coeff = multinomial_coeff(q+1, k) 
            x = C 
        end   
        for k0 in Combinatorics.WithReplacementCombinations(1:J+1,q)
            k = zeros(Int,s)
            for j in k0
                k[j]+=1
            end
            coeff = multinomial_coeff(q, k) 
        end   
    end
end




end # module