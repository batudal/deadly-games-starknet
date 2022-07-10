%lang starknet

from src.helpers.Interfaces import IXoroshiro128
from protostar.asserts import assert_eq, assert_not_eq
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin

@external
func test_basic_xoroshiro{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    local contract_address : felt
    %{ ids.contract_address = deploy_contract("./src/modules/utils/random/Xoroshiro128SS.cairo", [42]).contract_address %}
    let (res_0) = IXoroshiro128.next(contract_address=contract_address)
    let (res_1) = IXoroshiro128.next(contract_address=contract_address)
    with_attr error_message("Invalid random number value(s)"):
        assert_not_eq(res_0, res_1)
    end
    return ()
end
