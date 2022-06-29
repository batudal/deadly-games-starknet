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
    uint256_mul,
    uint256_reverse_endian,
)

@external
func test_keccak{syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr}():
    alloc_locals
    let (local k : Uint256) = compute_keccak(0, 0)
    uint256_check(k)
    # 163350357956845617524507815902528900710

    local s : Uint256 = Uint256(4, 0)
    local t : Uint256 = Uint256(7, 0)
    let (q : Uint256, r : Uint256) = uint256_unsigned_div_rem(k, t)
    assert s = r
    return ()
end
