%lang starknet

from src.modules.games.greed.Constants import (
    JACKPOT_CHANCE,
    WINNER_PERCENTAGE,
    MASON_PERCENTAGE,
    DEV_PERCENTAGE,
    RESERVE_PERCENTAGE,
    PERCENTAGE,
    TICKET_PRICE,
)
from src.helpers.Interfaces import IXoroshiro128
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
)
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_mul,
    uint256_unsigned_div_rem,
    uint256_add,
)
from starkware.cairo.common.serialize import serialize_word

struct Jackpot:
    member winner : felt
    member winner_count : felt
    member epoch : felt
    member total_amount : Uint256
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
func token() -> (address : felt):
end

@storage_var
func karma_token() -> (address : felt):
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
    alloc_locals
    # deposit
    let (sender) = get_caller_address()
    let (recipient) = get_contract_address()
    let (_token) = token.read()
    local ticket_price : Uint256 = Uint256(TICKET_PRICE, 0)
    local _ticket_amount : Uint256 = Uint256(low=ticket_amount, high=0)
    let (_amount_low, _amount_high) = uint256_mul(ticket_price, _ticket_amount)
    IERC20.transferFrom(
        contract_address=_token, sender=sender, recipient=recipient, amount=_amount_low
    )
    let (current_jackpot) = jackpot_amount.read()
    let (total_jackpot, carry) = uint256_add(current_jackpot, _amount_low)
    jackpot_amount.write(total_jackpot)

    # reward karma
    let (karma_tokn) = karma_token.read()
    IERC20.transfer(contract_address=karma_tokn, recipient=sender, amount=_ticket_amount)

    # rng
    let (rnd) = get_next_rnd()
    let (q, r) = unsigned_div_rem(rnd, 100)
    let (_epoch) = epoch.read()
    let (_wincount) = win_counts.read(sender)
    let (block_timestamp) = get_block_timestamp()
    let jackpot : Jackpot = Jackpot(
        winner=sender,
        winner_count=_wincount,
        epoch=_epoch,
        total_amount=total_jackpot,
        timestamp=block_timestamp,
    )

    # # register and mint
    if r != 0:
        # IERC1155.mint(
        #     contract_address=loser_token, sender=sender, recipient=recipient, amount=_amount
        # )
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        # announce
        jackpots.write(_epoch, jackpot)
        # IERC1155.mint(contract_address=winner_token, sender=sender, recipient=recipient, amount=_amount)
        win_counts.write(user=sender, value=_wincount + 1)

        # convert
        let percentage : Uint256 = Uint256(low=PERCENTAGE, high=0)
        let winner_percentage : Uint256 = Uint256(low=WINNER_PERCENTAGE, high=0)
        let mason_percentage : Uint256 = Uint256(low=MASON_PERCENTAGE, high=0)
        let dev_percentage : Uint256 = Uint256(low=DEV_PERCENTAGE, high=0)
        let reserve_percentage : Uint256 = Uint256(low=RESERVE_PERCENTAGE, high=0)

        # distribute
        let (local share, rem) = uint256_unsigned_div_rem(total_jackpot, percentage)
        let (local winner_share_low, winner_share_high) = uint256_mul(share, winner_percentage)
        let (local mason_share_low, mason_share_high) = uint256_mul(share, mason_percentage)
        let (local dev_share_low, dev_share_high) = uint256_mul(share, dev_percentage)
        let (local reserve_share_low, reserve_share_high) = uint256_mul(share, reserve_percentage)
        let (local current_treasury) = treasury_amount.read()
        IERC20.transfer(contract_address=_token, recipient=sender, amount=winner_share_low)
        IERC20.transfer(contract_address=_token, recipient=sender, amount=dev_share_low)
        jackpot_amount.write(reserve_share_low)
        let (local for_treasury, carry) = uint256_add(current_treasury, mason_share_low)
        treasury_amount.write(for_treasury)

        # align ptrs
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end
    return ()
end

@external
func get_next_rnd{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    rnd : felt
):
    alloc_locals
    let (local addr) = pseudo_address.read()
    let (rnd) = IXoroshiro128.next(contract_address=addr)
    return (rnd)
end
