%lang starknet

from protostar.asserts import assert_eq, assert_not_eq
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin

@external
func test_greed_entry{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    local contract_address : felt

    return ()
end
