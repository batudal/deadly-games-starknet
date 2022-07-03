%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address

# ------------------------------------------------- #
#
# Deadly Games
#
# This contract allows for module operations.
# Modules get access to Karma minting.
# Admin role will be transferred to DAO account.
#
# Author: @takez0_o
# Sponsorship: @dec0ded
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
func set_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    admin_address : felt
):
    only_admin()
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
