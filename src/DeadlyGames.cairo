%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_not_equal
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
# Originated in: @decodedlabs
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
func admin_address() -> (address : felt):
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
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(admin : felt):
    admin_address.write(admin)
    return ()
end

# --------------------------- #
# internal fxns
# --------------------------- #

func only_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    let (local caller) = get_caller_address()
    let (current) = admin_address.read()
    with_attr error_message("Caller is not the admin."):
        assert caller = current
    end
    return ()
end

# --------------------------- #
# mutative fxns
# --------------------------- #

@external
func set_karma_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    karma_address : felt
):
    karma_token.write(value=karma_address)
    return ()
end

@external
func set_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(new_admin : felt):
    only_admin()
    let (karma_address) = karma_token.read()
    IKarma.transferOwnership(contract_address=karma_address, newOwner=new_admin)
    admin_address.write(new_admin)
    return ()
end

@external
func mint_karma{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amount : Uint256, user : felt
):
    alloc_locals
    # check module access
    let (local sender) = get_caller_address()
    let (access_state) = module_access.read(address=sender)
    with_attr error_message("Module with no access."):
        assert access_state = 1
    end
    # mint karma
    let (karma_address) = karma_token.read()
    IKarma.mint(contract_address=karma_address, to=user, amount=amount)
    return ()
end

@external
func update_game{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id : felt, name : felt, author : felt, implementation : felt
):
    only_admin()
    let (game : Game) = games.read(id)
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
    local game : Game = Game(name, author, implementation, 0)
    let (ctr) = counter.read()
    let id = ctr + 1
    is_name_unq(name=name, count=id)
    is_implementation_unq(implementation=implementation, count=id)
    games.write(id, game)
    module_access.write(implementation, 0)
    counter.write(id)
    return ()
end

func is_name_unq{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    name : felt, count : felt
):
    if count == 0:
        return ()
    end
    let (game : Game) = games.read(count)
    assert_not_equal(game.name, name)
    return is_name_unq(name=name, count=count - 1)
end

func is_implementation_unq{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    implementation : felt, count : felt
):
    if count == 0:
        return ()
    end
    let (game : Game) = games.read(count)
    assert_not_equal(game.implementation, implementation)
    return is_implementation_unq(implementation=implementation, count=count - 1)
end

@external
func activate_game{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(id : felt):
    alloc_locals
    let (game : Game) = games.read(id)
    let new_game = Game(
        name=game.name, author=game.author, implementation=game.implementation, active=1
    )
    games.write(id=id, value=new_game)
    module_access.write(game.implementation, 1)
    return ()
end

@external
func disable_game{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(id : felt):
    alloc_locals
    only_admin()
    let (game : Game) = games.read(id)
    let new_game = Game(
        name=game.name, author=game.author, implementation=game.implementation, active=0
    )
    games.write(id=id, value=new_game)
    module_access.write(game.implementation, 0)
    return ()
end

@external
func emergency_shutdown{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id : felt, to_address : felt
):
    alloc_locals
    only_admin()
    let (local dao_state : felt) = dao_active.read()
    with_attr error_message("Dao is not active."):
        assert dao_state = 1
    end
    let (admin) = admin_address.read()
    let (game) = games.read(id)
    IGame.emergency_shutdown(contract_address=game.implementation, to_address=admin)
    return ()
end

@external
func transcendence_to_dao{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
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
func get_admin_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    admin : felt
):
    alloc_locals
    let (local admin) = admin_address.read()
    return (admin)
end

@view
func get_counter{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    count : felt
):
    alloc_locals
    let (local count) = counter.read()
    return (count)
end

@view
func get_game{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(id : felt) -> (
    game : Game
):
    alloc_locals
    let (local game : Game) = games.read(id=id)
    return (game)
end

@view
func get_karma_token{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    address : felt
):
    alloc_locals
    let (local address) = karma_token.read()
    return (address)
end

@view
func get_module_access{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
) -> (access : felt):
    alloc_locals
    let (local access) = module_access.read(address=address)
    return (access)
end

@view
func get_dao_active{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    state : felt
):
    alloc_locals
    let (local state) = dao_active.read()
    return (state)
end
