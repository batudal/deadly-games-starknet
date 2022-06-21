%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.serialize import serialize_word
from src.deadly_games import compute_keccak
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_unsigned_div_rem,
    uint256_eq,
    uint256_check,
)

@external
func test_keccak{syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr}():
    alloc_locals
    let (local k : Uint256) = compute_keccak{bitwise_ptr=bitwise_ptr}(0, 0)
    uint256_check(k)

    let s = Uint256(low=4, high=0)
    let t = Uint256(low=7, high=0)

    let (q : Uint256, r : Uint256) = uint256_unsigned_div_rem(k, t)
    assert s = r
    return ()
end
