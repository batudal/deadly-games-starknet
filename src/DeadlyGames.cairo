%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from src.helpers.Interfaces import IGame

# ------------------------------------------------- #
#
# Deadly Games
#
# This contract allows for module operations.
# Modules get access to Karma minting.
# Admin role will be transferred to DAO account.
#
# Make your game contract ownable and transfer
# ownership to this contract upon deployment.
#
# Author: @takez0_o
# Supported by: @matchboxDAO
# Originated in: @decodedLabs
#
# ------------------------------------------------- #

# --------------------------- #
# types
# --------------------------- #

struct Game:
    member name : felt
    member author : felt
    member implementation : felt
    member active : felt
end

# --------------------------- #
# storage vars
# --------------------------- #

@storage_var
func counter() -> (count : felt):
end

@storage_var
func games(id : felt) -> (game : Game):
end

@storage_var
func admin() -> (address : felt):
end

@storage_var
func karma_token() -> (address : felt):
end

# 0-no access, 1-has access
@storage_var
func module_access(address : felt) -> (access : felt):
end

# --------------------------- #
# initializer
# --------------------------- #

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    admin_address : felt
):
    admin.write(admin_address)
    return ()
end

# --------------------------- #
# internal fxns
# --------------------------- #

func only_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    let (local caller) = get_caller_address()
    let (current) = admin.read()
    assert caller = current
    return ()
end

# --------------------------- #
# mutative fxns
# --------------------------- #

@external
func emergency_shutdown{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id : felt, to_address : felt
):
    only_admin()
    let (admin_address) = admin.read()
    let (game_address) = games.read(id)
    IGame.emergency_shutdown(
        contract_address=game_address, to_address=to_address, admin_address=admin_address
    )

    return ()
end

@external
func mint_karma{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amount : Uint256, user : felt
):
    # check module access
    let (sender) = get_caller_address
    let (access_state) = module_access.read(address=sender)
    assert access_state = 1

    # mint karma
    let (karma_address) = karma_token.read()
    IERC20.mint(contract_address=karma_address, recipient=user, amount=amount)
end

@external
func set_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    admin_address : felt
):
    only_admin()
    let (karma_address) = karma_token.read()
    IERC20.transferOwnership(contract_address=karma_address, recipient=admin_address)
    admin.write(admin_address)
    return ()
end

@external
func update_game{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    name : felt, id : felt, author : felt, implementation : felt
):
    only_admin()
    let (game) = games.read(id)
    game.name = name
    game.author = author
    game.implementation = implementation
    return ()
end

@external
func add_game{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    name : felt, author : felt, implementation : felt
):
    alloc_locals
    only_admin()
    local game : Game = Game(name, author, implementation, 0)
    let (ctr) = counter.read()
    let id = ctr + 1
    games.write(id, game)
    module_access.write(implementation, 1)
    counter.write(id)
    return ()
end

@external
func activate_game{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(id : felt):
    alloc_locals
    only_admin()
    let (local game : Game) = games.read(id)
    game.active = 1
    return ()
end

@external
func disable_game{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(id : felt):
    alloc_locals
    only_admin()
    let (local game : Game) = games.read(id)
    game.active = 0
    return ()
end

# --------------------------- #
# view fxns
# --------------------------- #

@view
func is_active{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(id : felt) -> (
    active : felt
):
    let (game) = games.read(id)
    return (active=game.active)
end
