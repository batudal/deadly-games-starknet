%lang starknet

from src.utils.Constants import ( JACKPOT_CHANCE, WINNER_PERCENTAGE, MASON_PERCENTAGE,
TEAM_PERCENTAGE, RESERVE_PERCENTAGE, TICKET_PRICE)
from src.utils.Interfaces import PseudoRandom
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from starkware.cairo.common.uint256 import Uint256


@storage_var
func pseudo_address() -> (address: felt):
end

@storage_var
func token_address() -> (address: felt):
end

@external
func greedyBastard{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(amount: Uint256):

    let (pseudo) = pseudo_address.read()
    let (sender) = get_caller_address()
    let (recipient) = get_contract_address()

    # PseudoRandom.get_pseudorandom(
    #     pseudo)

    let (token) = token_address.read()

    IERC20.transferFrom(
        contract_address=token,
        sender=sender,
        recipient=recipient,
        amount=amount)
    return()
end

