%lang starknet

from contracts.utils.Constants import JACKPOT_CHANCE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from openzeppelin.token.erc20.library import IERC20

@external
func greed{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(amount: felt):
    let (sender) = get_caller_address()
    let (recipient) = get_contract_address()
    IERC20.transferFrom(sender,recipient, amount)
    return()
end


