%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address
from src.helpers.Interfaces import IGame, IKarma
from starkware.cairo.common.uint256 import Uint256

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

@storage_var
func dao_active() -> (state : felt):
end

# --------------------------- #
# initializer
# --------------------------- #

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    let (local caller) = get_caller_address()
    admin.write(caller)
    return ()
end

# --------------------------- #
# internal fxns
# --------------------------- #

func only_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    let (local caller) = get_caller_address()
    let (current) = admin.read()
    with_attr error_message("Caller is not the admin."):
        assert caller = current
    end
    return ()
end

# --------------------------- #
# mutative fxns
# --------------------------- #

@external
func mint_karma{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amount : Uint256, user : felt
):
    alloc_locals
    # check module access
    let (local sender) = get_caller_address()
    let (access_state) = module_access.read(address=sender)
    assert access_state = 1

    # mint karma
    let (karma_address) = karma_token.read()
    IKarma.mint(contract_address=karma_address, to=user, amount=amount)
    return ()
end

@external
func set_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    admin_address : felt
):
    only_admin()
    let (karma_address) = karma_token.read()
    IKarma.transferOwnership(contract_address=karma_address, newOwner=admin_address)
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

@external
func emergency_shutdown{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id : felt, to_address : felt
):
    alloc_locals
    only_admin()
    let (local dao_state : felt) = dao_active.read()
    assert dao_state = 1
    let (admin_address) = admin.read()
    let (game) = games.read(id)
    IGame.emergency_shutdown(contract_address=game.implementation, to_address=admin_address)
    return ()
end

@external
func transcendence{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    dao_address : felt
):
    only_admin()
    set_admin(dao_address)
    dao_active.write(1)
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
