%lang starknet

from contracts.utils.Constants import ( JACKPOT_CHANCE, WINNER_PERCENTAGE, MASON_PERCENTAGE,
TEAM_PERCENTAGE, RESERVE_PERCENTAGE, TICKET_PRICE)
from contracts.utils.Interfaces import PseudoRandom
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from openzeppelin.token.erc20.library import IERC20

@storage_var
func pseudo_address() -> (address: felt):
end

@external
func greedyBastard{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(amount: felt):

    let (pseudo) = pseudo_address.read()
    let (sender) = get_caller_address()
    let (recipient) = get_contract_address()

    PseudoRandom.get_pseudorandom(
        pseudo,get_caller_address)

    IERC20.transferFrom(sender,recipient, amount)
    return()
end

