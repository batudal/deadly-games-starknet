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
func pseudo_addr() -> (address : felt):
end

@storage_var
func token() -> (address : felt):
end

@storage_var
func karma_addr() -> (address : felt):
end

@storage_var
func deadly_games_addr() -> (address : felt):
end

@storage_var
func jackpot_amount() -> (amount : Uint256):
end

@storage_var
func treasury_amount() -> (amount : Uint256):
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
func set_pseudo_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
):
    pseudo_addr.write(address)
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

@external
func emergency_shutdown{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    to_address : felt, admin_address : felt
):
    only_deadly_games()
    let (current_jackpot) = jackpot_amount.read()
    let (_token) = token.read()
    let (sender) = get_contract_address()
    IERC20.transferFrom(
        contract_address=_token, sender=sender, recipient=admin_address, amount=current_jackpot
    )
end
