%lang starknet

from src.utils.Constants import (
    JACKPOT_CHANCE,
    WINNER_PERCENTAGE,
    MASON_PERCENTAGE,
    TEAM_PERCENTAGE,
    RESERVE_PERCENTAGE,
    TICKET_PRICE,
)
from src.utils.Interfaces import PseudoRandom
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.uint256 import (
    uint256_add,
    uint256_and,
    uint256_cond_neg,
    uint256_eq,
    uint256_le,
    uint256_lt,
    uint256_mul,
    uint256_neg,
    uint256_not,
    uint256_or,
    uint256_shl,
    uint256_shr,
    uint256_signed_div_rem,
    uint256_signed_le,
    uint256_signed_lt,
    uint256_signed_nn,
    uint256_signed_nn_le,
    uint256_sqrt,
    uint256_sub,
    uint256_unsigned_div_rem,
    uint256_xor,
)

@storage_var
func pseudo_address() -> (address : felt):
end

@storage_var
func token_address() -> (address : felt):
end

@storage_var
func jackpot_amount() -> (amount : Uint256):
end

@external
func greedyBastard{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amount : Uint256
):
    let (pseudo) = pseudo_address.read()
    let (sender) = get_caller_address()
    let (recipient) = get_contract_address()
    let (token) = token_address.read()
    IERC20.transferFrom(contract_address=token, sender=sender, recipient=recipient, amount=amount)
    PseudoRandom.add_to_seed(pseudo, sender, recipient)
    let (random) = PseudoRandom.get_pseudorandom(pseudo)
    return ()
end
