%lang starknet

from src.helpers.Interfaces import IDeadlyGames
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from starkware.cairo.common.uint256 import Uint256, uint256_add

@storage_var
func token() -> (address : felt):
end

@storage_var
func karma_addr() -> (address : felt):
end

@storage_var
func deadly_games_addr() -> (address : felt):
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
func emergency_shutdown{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    to_address : felt, admin_address : felt
):
    only_deadly_games()
    let (_token) = token.read()
    let (sender) = get_contract_address()
    let (local amount : Uint256) = IERC20.balance_of(contract_address=_token, account=sender)
    IERC20.transferFrom(
        contract_address=_token, sender=sender, recipient=admin_address, amount=amount
    )
end
