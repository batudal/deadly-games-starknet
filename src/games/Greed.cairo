%lang starknet

from src.utils.constants import (
    JACKPOT_CHANCE,
    WINNER_PERCENTAGE,
    MASON_PERCENTAGE,
    DEV_PERCENTAGE,
    RESERVE_PERCENTAGE,
    TICKET_PRICE,
)
from src.utils.Interfaces import IXoroshiro128
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
)
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from starkware.cairo.common.uint256 import Uint256, uint256_mul, uint256_div
from starkware.cairo.common.serialize import serialize_word

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

@storage_var
func treasury_amount() -> (amount : Uint256):
end

@external
func set_pseudo_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
):
    pseudo_address.write(address)
    return ()
end

@external
func greed{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(ticket_amount : felt):
    # deposit
    let (sender) = get_caller_address()
    let (recipient) = get_contract_address()
    let (token) = token_address.read()
    let ticket_price : Uint256 = cast((low=0, high=TICKET_PRICE), Uint256)
    let _ticket_amount : Uint256 = cast((low=0, high=ticket_amount), Uint256)
    let _amount : Uint256 = uint256_mul(ticket_price, _ticket_amount)
    IERC20.transferFrom(contract_address=token, sender=sender, recipient=recipient, amount=_amount)
    let (current_jackpot) = jackpot_amount.read()
    let (total_jackpot) = current_jackpot + _amount
    jackpot_amount.write(total_jackpot)

    # reward karma
    IERC20.transfer(contract_address=karma_token, recipient=sender, amount=_ticket_amount)

    # rng
    let (rnd) = get_next_rnd()
    let (_, r) = unsigned_div_rem(random, 100)

    # register and mint
    if r != 0:
        IERC1155.mint(
            contract_address=loser_token, sender=sender, recipient=recipient, amount=_amount
        )
    else:
        # announce
        let (local _epoch) = epoch.read()
        let (local _wincount) = win_counts.read(sender)
        let (block_timestamp) = get_block_timestamp()
        let (jackpot) = Jackpot(
            winner=sender,
            winner_count=_wincount,
            epoch=_epoch,
            total_amount=total_jackpot,
            timestamp=block_timestamp,
        )
        jackpots.write(epoch, jackpot)
        IERC1155.mint(
            contract_address=winner_token, sender=sender, recipient=recipient, amount=_amount
        )
        win_counts.write(user=sender, value=new_balance)

        # distribute
        let (share) = uint256_div(total_jackpot, 100)
        let (winner_share) = uint256_mul(share, WINNER_PERCENTAGE)
        let (mason_share) = uint256_mul(share, MASON_PERCENTAGE)
        let (dev_share) = uint256_mul(share, DEV_PERCENTAGE)
        let (reserve_share) = uint256_mul(share, RESERVE_PERCENTAGE)
        let (local current_treasury) = treasury_amount.read()

        IERC20.transfer(contract_address=token, recipient=sender, amount=winner_share)
        IERC20.transfer(contract_address=token, recipient=sender, amount=dev_share)
        jackpot_amount.write(reserve_share)
        treasury_amount.write(current_treasury + mason_share)
    end
    return ()
end

@external
func get_next_rnd{syscall_ptr : felt*, range_check_ptr}() -> (rnd : felt):
    let (local addr) = pseudo_address.read()
    let (rnd) = IXoroshiro128.next(contract_address=addr)
    return (rnd)
end
