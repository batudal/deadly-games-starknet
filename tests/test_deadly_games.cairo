%lang starknet

from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from protostar.asserts import assert_eq
from src.helpers.Interfaces import IDeadlyGames, IKarma

@external
func __setup__{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    let KARMA_NAME = 0x4B61726D6120546F6B656E
    let KARMA_SYMBOL = 0x4B41524D41
    let (local contract_address) = get_contract_address()
    %{
        context.contract_address = ids.contract_address
        context.KARMA_NAME = ids.KARMA_NAME
        context.KARMA_SYMBOL = ids.KARMA_SYMBOL
        context.deadly_games_address = deploy_contract("./src/DeadlyGames.cairo").contract_address 
        context.karma_address = deploy_contract("src/modules/token/Karma.cairo",[ids.KARMA_NAME,ids.KARMA_SYMBOL,18,ids.contract_address]).contract_address
    %}
    check_karma_deployment()
    return ()
end

func check_karma_deployment{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    local karma_address : felt
    tempvar KARMA_NAME
    tempvar KARMA_SYMBOL
    %{
        ids.KARMA_NAME = context.KARMA_NAME
        ids.KARMA_SYMBOL = context.KARMA_SYMBOL 
        ids.karma_address = context.karma_address
    %}
    let (local asset_name) = IKarma.name(contract_address=karma_address)
    assert_eq(asset_name, KARMA_NAME)
    let (local asset_symbol) = IKarma.symbol(contract_address=karma_address)
    assert_eq(asset_symbol, KARMA_SYMBOL)
    return ()
end

@external
func test_constructor{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    tempvar deadly_games_address
    tempvar contract_address
    %{
        ids.contract_address=context.contract_address
        ids.deadly_games_address = context.deadly_games_address
    %}
    let (local admin) = IDeadlyGames.get_admin_address(contract_address=deadly_games_address)
    assert_eq(contract_address, admin)
    return ()
end

func karma_transfer_owner{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    local karma_address
    local deadly_games_address
    %{
        ids.karma_address=context.karma_address
        ids.deadly_games_address=context.deadly_games_address
    %}
    IKarma.transferOwnership(contract_address=karma_address, newOwner=deadly_games_address)
    let (local owner) = IKarma.owner(contract_address=karma_address)
    assert_eq(owner, deadly_games_address)
    return ()
end

@external
func test_transcendence_to_dao{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    tempvar deadly_games_address
    tempvar karma_address
    %{
        ids.deadly_games_address = context.deadly_games_address 
        ids.karma_address=context.karma_address
    %}
    karma_transfer_owner()
    IDeadlyGames.set_karma_address(
        contract_address=deadly_games_address, karma_address=karma_address
    )
    IDeadlyGames.transcendence_to_dao(contract_address=deadly_games_address, dao_address=123)
    let (local new_admin) = IDeadlyGames.get_admin_address(contract_address=deadly_games_address)
    assert_eq(new_admin, 123)
    return ()
end

# add caller as an implementation
@external
func test_add_game{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    tempvar deadly_games_address
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
        ids.deadly_games_address = context.deadly_games_address
    %}
    IDeadlyGames.add_game(
        contract_address=deadly_games_address, name=42, author=42, implementation=contract_address
    )
    let (game) = IDeadlyGames.get_game(contract_address=deadly_games_address, id=1)
    assert_eq(game.name, 42)
    assert_eq(game.author, 42)
    assert_eq(game.implementation, contract_address)
    assert_eq(game.active, 0)
    let (access) = IDeadlyGames.get_module_access(
        contract_address=deadly_games_address, address=contract_address
    )
    assert_eq(access, 0)
    IDeadlyGames.activate_game(contract_address=deadly_games_address, id=1)
    let (game) = IDeadlyGames.get_game(contract_address=deadly_games_address, id=1)
    assert_eq(game.active, 1)
    let (access) = IDeadlyGames.get_module_access(
        contract_address=deadly_games_address, address=contract_address
    )
    assert_eq(access, 1)
    return ()
end

@external
func test_remove_game{syscall_ptr : felt*, range_check_ptr}():
    test_add_game()
    tempvar deadly_games_address
    tempvar contract_address
    %{
        ids.deadly_games_address = context.deadly_games_address
        ids.contract_address = context.contract_address
    %}
    IDeadlyGames.disable_game(contract_address=deadly_games_address, id=1)
    let (game) = IDeadlyGames.get_game(contract_address=deadly_games_address, id=1)
    assert_eq(game.active, 0)
    let (access) = IDeadlyGames.get_module_access(
        contract_address=deadly_games_address, address=contract_address
    )
    assert_eq(access, 0)
    return ()
end
