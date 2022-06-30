%lang starknet

from src.utils.constants import (
    JACKPOT_CHANCE,
    WINNER_PERCENTAGE,
    MASON_PERCENTAGE,
    TEAM_PERCENTAGE,
    RESERVE_PERCENTAGE,
    TICKET_PRICE,
)
from src.utils.Interfaces import linear_congruential_generator
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.uint256 import uint256_mul

struct Jackpot:
    member winner : felt
    member winner_count : felt
    member epoch : felt
    member total_amount : felt
    member timestamp : felt
end

@storage_var
func win_counts(user : felt) -> (count : felt):
end

@storage_var
func jackpots(epoch : felt) -> (jackpot : Jackpot):
end

@storage_var
func epoch() -> (count : felt):
end

@storage_var
func highest_jackpot() -> (count : felt):
end

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
func greed{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(ticket_amount : felt):
    let (pseudo) = pseudo_address.read()
    let (sender) = get_caller_address()
    let (recipient) = get_contract_address()
    let (token) = token_address.read()
    let ticket_price : Uint256 = cast((low=0, high=TICKET_PRICE), Uint256)
    let _ticket_amount : Uint256 = cast((low=0, high=ticket_amount), Uint256)
    let _amount : Uint256 = uint256_mul(ticket_price, _ticket_amount)

    # IERC20.transferFrom(contract_address=token, sender=sender, recipient=recipient, amount=_amount)
    # linear_congruential_generator.add_to_seed(pseudo, sender, recipient)
    # let (random) = linear_congruential_generator.get_pseudorandom(pseudo)
    # let (_, r) = unsigned_div_rem(random, 100)
    # let (current_balance) = greedyDao.read(sender)
    # tempvar new_balance = current_balance
    # if r == 0:
    #     new_balance = current_balance + 1
    # end
    # win_counts.write(user=sender, value=new_balance)



    return ()
end
