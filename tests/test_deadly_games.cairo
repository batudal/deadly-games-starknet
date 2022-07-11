%lang starknet

from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from protostar.asserts import assert_eq
from src.helpers.Interfaces import IDeadlyGames, IKarma

@external
func __setup__{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    let (local contract_address) = get_contract_address()
    %{
        context.deadly_games_address = deploy_contract("./src/DeadlyGames.cairo").contract_address 
        context.karma_address = deploy_contract("src/modules/token/Karma.cairo",[42,42,18,ids.contract_address]).contract_address
    %}
    check_karma_deployment()
    return ()
end

@external
func test_constructor{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    tempvar deadly_games_address
    let (local contract_address) = get_contract_address()
    %{ ids.deadly_games_address = context.deadly_games_address %}
    let (local admin) = IDeadlyGames.get_admin_address(contract_address=deadly_games_address)
    assert_eq(contract_address, admin)
    return ()
end

func check_karma_deployment{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    local karma_address : felt
    %{ ids.karma_address = context.karma_address %}
    let (local asset_name) = IKarma.name(contract_address=karma_address)
    assert_eq(asset_name, 42)
    let (local asset_symbol) = IKarma.symbol(contract_address=karma_address)
    assert_eq(asset_symbol, 42)
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
