using Snowflurry
using Test
using HTTP

# dummy arguments for submitter function 
expected_a = 123
expected_b = "456"
expected_c = Dict{String,Int}("key" => 789)

args = [expected_a, expected_b, expected_c]

expected_histogram = Dict{String,Int}("00" => 23, "10" => 321)
expected_qpu_time = 42
expected_error_msg = "expected_message"

failed_status = Snowflurry.Status(Snowflurry.failed_status, expected_error_msg)
cancelled_status = Snowflurry.Status(Snowflurry.cancelled_status, "")
succeeded_status = Snowflurry.Status(Snowflurry.succeeded_status, "")
invalid_status_type = "INVALID"
invalid_status = Snowflurry.Status(invalid_status_type, "")

success_tuple = (succeeded_status, expected_histogram, expected_qpu_time)
failure_tuple = (failed_status, Dict{String,Int}(), expected_qpu_time)
cancellation_tuple = (cancelled_status, Dict{String,Int}(), expected_qpu_time)
invalid_response_tuple = (invalid_status, Dict{String,Int}(), expected_qpu_time)

function make_submitter_spy(
    return_tuples::Array{Tuple{Status,Dict{String,Int},Int}},

    # must be a reference value, so the caller can assert the mutated binding
    # see: https://docs.julialang.org/en/v1/manual/functions/#man-argument-passing
    attempts_counter::Vector{Int},
)::Function
    return function (args...)

        # confirm arguments are piped through
        @assert args[1] == expected_a
        @assert args[2] == expected_b
        @assert args[3] == expected_c

        attempts_counter[1] += 1
        return return_tuples[attempts_counter[1]]
    end
end

@testset "submit with retries: success cases" begin

    test_specs = [
        ([success_tuple], 1),
        ([failure_tuple, success_tuple], 2),
        ([failure_tuple, failure_tuple, success_tuple], 3),
    ]

    for (return_tuple, expected_attempts) in test_specs
        attempts_counter = [0]

        histogram, qpu_time = Snowflurry.submit_with_retries(
            make_submitter_spy(return_tuple, attempts_counter),
            args...,
        )

        @test attempts_counter[1] == expected_attempts
        @test histogram == expected_histogram
        @test qpu_time == expected_qpu_time
    end
end

@testset "submit with retries: failure cases" begin

    test_specs = [
        (
            [failure_tuple, failure_tuple, failure_tuple],
            3,
            ErrorException(
                "job has failed with the following message: $expected_error_msg",
            ),
        ),
        ([cancellation_tuple], 1, ErrorException("job was cancelled")),
        (
            [invalid_response_tuple],
            1,
            AssertionError(
                "Server returned an unrecognized status type: $invalid_status_type",
            ),
        ),
    ]

    for (return_tuple, expected_attempts, error_message) in test_specs
        attempts_counter = [0]

        @test_throws error_message Snowflurry.submit_with_retries(
            make_submitter_spy(return_tuple, attempts_counter),
            args...,
        )

        @test attempts_counter[1] == expected_attempts
    end
end
