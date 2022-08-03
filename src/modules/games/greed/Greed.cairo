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
from src.helpers.Interfaces import IDeadlyGames
from src.modules.games.greed.IGreedMark import IGreedMark
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
    uint256_sub,
    uint256_unsigned_div_rem,
    uint256_add,
    uint256_le,
)

@event
func greed_entry(user : felt, amount : felt):
end

@event
func greed_winner(user : felt):
end

@event
func greed_loser(user : felt):
end

@event
func emergency_shutdown_executed():
end

@event
func user_has_claimed(user : felt):
end

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
func user_claimed(user : felt) -> (amount : Uint256):
end

@storage_var
func jackpots(epoch : felt) -> (jackpot : Jackpot):
end

@storage_var
func tickets_sold() -> (count : felt):
end

@storage_var
func epoch() -> (count : felt):
end

@storage_var
func pseudo_addr() -> (address : felt):
end

@storage_var
func token_addr() -> (address : felt):
end

@storage_var
func deadly_games_addr() -> (address : felt):
end

@storage_var
func greed_mark_addr() -> (address : felt):
end

@storage_var
func jackpot_amount() -> (amount : Uint256):
end

@storage_var
func treasury_amount() -> (amount : Uint256):
end

@storage_var
func initialized() -> (state : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    deadly_games_address : felt
):
    deadly_games_addr.write(deadly_games_address)
    return ()
end

func only_deadly_games{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    let (local caller) = get_caller_address()
    let (current) = deadly_games_addr.read()
    assert caller = current
    return ()
end

@external
func set_addresses{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_address : felt,
    deadly_games_address : felt,
    pseudo_address : felt,
    greed_mark_address : felt,
):
    let (state) = initialized.read()
    assert (state) = 0
    token_addr.write(token_address)
    deadly_games_addr.write(deadly_games_address)
    pseudo_addr.write(pseudo_address)
    greed_mark_addr.write(greed_mark_address)
    initialized.write(1)
    return ()
end

@external
func greed{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(ticket_amount : felt):
    alloc_locals
    # deposit
    let (sender : felt) = get_caller_address()
    greed_entry.emit(sender, ticket_amount)
    let (currently_sold : felt) = tickets_sold.read()
    tickets_sold.write(currently_sold + ticket_amount)
    let (recipient : felt) = get_contract_address()
    let (token_address : felt) = token_addr.read()
    local ticket_price : Uint256 = Uint256(TICKET_PRICE, 0)
    local _ticket_amount : Uint256 = Uint256(low=ticket_amount, high=0)
    let (_amount_low, _amount_high) = uint256_mul(ticket_price, _ticket_amount)
    IERC20.transferFrom(
        contract_address=token_address, sender=sender, recipient=recipient, amount=_amount_low
    )
    let (current_jackpot : Uint256) = jackpot_amount.read()
    let (total_jackpot, carry) = uint256_add(current_jackpot, _amount_low)
    jackpot_amount.write(total_jackpot)

    # reward karma
    let (deadly_games_address) = deadly_games_addr.read()
    IDeadlyGames.mint_karma(
        contract_address=deadly_games_address, amount=_ticket_amount, user=sender
    )
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
        let (local greed_mark_address) = greed_mark_addr.read()
        IGreedMark.mint_fcker(
            contract_address=greed_mark_address, user=sender, amount=ticket_amount
        )
        greed_loser.emit(user=sender)

        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        let (local greed_mark_address) = greed_mark_addr.read()
        IGreedMark.mint_lcker(contract_address=greed_mark_address, user=sender)
        greed_winner.emit(user=sender)
        # announce
        jackpots.write(_epoch, jackpot)
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
        IERC20.transfer(contract_address=token_address, recipient=sender, amount=winner_share_low)
        IERC20.transfer(contract_address=token_address, recipient=sender, amount=dev_share_low)
        jackpot_amount.write(reserve_share_low)
        let (local for_treasury, carry) = uint256_add(current_treasury, mason_share_low)
        treasury_amount.write(for_treasury)

        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end
    return ()
end

func get_next_rnd{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    rnd : felt
):
    alloc_locals
    let (local addr) = pseudo_addr.read()
    let (rnd) = IXoroshiro128.next(contract_address=addr)
    return (rnd)
end

@external
func emergency_shutdown{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    to_address : felt, admin_address : felt
):
    alloc_locals
    only_deadly_games()
    let (_token) = token_addr.read()
    let (sender) = get_contract_address()
    let (local amount : Uint256) = IERC20.balanceOf(contract_address=_token, account=sender)
    IERC20.transferFrom(
        contract_address=_token, sender=sender, recipient=admin_address, amount=amount
    )
    return ()
end

@external
func claim{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    let (token_address : felt) = token_addr.read()
    let (current_treasury : Uint256) = treasury_amount.read()
    let (local caller) = get_caller_address()
    let (user_win_count) = win_counts.read(caller)
    let user_win_count_uint : Uint256 = Uint256(low=user_win_count, high=0)
    let (total_win_count) = epoch.read()
    let total_win_count_uint : Uint256 = Uint256(low=total_win_count, high=0)
    let (local claimed : Uint256) = user_claimed.read(caller)
    let (local product_low, product_high) = uint256_mul(current_treasury, user_win_count_uint)
    let (local share, r) = uint256_unsigned_div_rem(product_low, total_win_count_uint)
    let (local result) = uint256_sub(share, claimed)
    let (local assertion) = uint256_le(Uint256(0, 0), result)
    assert (assertion) = 1
    IERC20.transfer(contract_address=token_address, recipient=caller, amount=share)
    user_has_claimed.emit(caller)
    return ()
end

@view
func get_token_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    address : felt
):
    let (token_address : felt) = token_addr.read()
    return (address=token_address)
end

@view
func get_deadly_games_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (address : felt):
    let (deadly_games_address : felt) = deadly_games_addr.read()
    return (address=deadly_games_address)
end

@view
func get_pseudo_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    address : felt
):
    let (pseudo_address : felt) = pseudo_addr.read()
    return (address=pseudo_address)
end
@view
func get_greed_mark_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (address : felt):
    let (greed_mark_address : felt) = greed_mark_addr.read()
    return (address=greed_mark_address)
end

@view
func get_jackpot_amount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    amount : Uint256
):
    let (current_jackpot_amount : Uint256) = jackpot_amount.read()
    return (amount=current_jackpot_amount)
end

@view
func get_epoch{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    count : felt
):
    let (current_epoch) = epoch.read()
    return (count=current_epoch)
end

@view
func get_tickets_sold{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    count : felt
):
    let (currently_sold : felt) = tickets_sold.read()
    return (count=currently_sold)
end

@view
func get_ticket_price{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    amount : felt
):
    return (TICKET_PRICE)
end
