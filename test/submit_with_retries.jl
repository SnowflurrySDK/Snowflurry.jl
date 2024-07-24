using Snowflurry
using Test
using HTTP

# dummy arguments for submitter function 
expected_a= 123
expected_b= "456"
expected_c= Dict{String, Int}("key"=>789)

expected_histogram = Dict{String,Int}("00"=>23, "10"=>321)
expected_qpu_time = 4321
expected_error_msg = "expected_message"

status_failed = Snowflurry.Status(Snowflurry.failed_status, expected_error_msg)
status_cancelled = Snowflurry.Status(Snowflurry.cancelled_status, "")
status_succeeded = Snowflurry.Status(Snowflurry.succeeded_status, "")



function make_mock_submitter!(
    return_tuples::Array{Tuple{Status,Dict{String,Int},Int}}, 

    # must be a reference value, so the caller can assert the mutated binding
    # see: https://docs.julialang.org/en/v1/manual/functions/#man-argument-passing
    attempts_counter::Vector{Int}, 
    )::Function 
    return function(args...)

        # confirm arguments are piped through
        @assert args[1] == expected_a
        @assert args[2] == expected_b
        @assert args[3] == expected_c

        attempts_counter[1]+=1
        return return_tuples[attempts_counter[1]]
    end
end

@testset "submit with retries: succeeds on third attempt" begin

    return_tuples=[
        (status_failed, Dict{String,Int}(),0)
        (status_failed, Dict{String,Int}(),0)
        (status_succeeded, expected_histogram, expected_qpu_time)
    ]

    attempts_counter = [0]

    histogram, qpu_time = Snowflurry.submit_with_retries(make_mock_submitter!(return_tuples, attempts_counter), expected_a, expected_b, expected_c)

    @test attempts_counter[1] == 3
    @test histogram == expected_histogram
    @test qpu_time == expected_qpu_time
end

@testset "submit with retries: three failed attempts" begin

    return_tuples=[
        (status_failed, Dict{String,Int}(),0)
        (status_failed, Dict{String,Int}(),0)
        (status_failed, Dict{String,Int}(),0)
    ]

    attempts_counter = [0]

    @test_throws ErrorException(expected_error_msg) Snowflurry.submit_with_retries(make_mock_submitter!(return_tuples, attempts_counter), expected_a, expected_b, expected_c)

    @test attempts_counter[1] == 3
end

@testset "submit with retries: single attempt returns cancelled" begin

    return_tuples=[
        (status_cancelled, Dict{String,Int}(),0)
        (status_failed, Dict{String,Int}(),0) # should not be attempted
        (status_failed, Dict{String,Int}(),0)
    ]

    attempts_counter = [0]

    @test_throws ErrorException("job was cancelled") Snowflurry.submit_with_retries(make_mock_submitter!(return_tuples, attempts_counter), expected_a, expected_b, expected_c)

    @test attempts_counter[1] == 1
end