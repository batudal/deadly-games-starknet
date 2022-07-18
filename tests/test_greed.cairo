%lang starknet

from protostar.asserts import assert_eq, assert_not_eq
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from src.modules.games.greed.IGreed import IGreed
from src.modules.games.greed.IGreedMark import IGreedMark
from src.helpers.Interfaces import IDeadlyGames, IKarma
from starkware.starknet.common.syscalls import get_contract_address
from src.openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from starkware.cairo.common.uint256 import Uint256, uint256_eq

@external
func __setup__{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    let (local contract_address : felt) = get_contract_address()
    tempvar token_address
    %{
        context.token_address = deploy_contract("./src/mock/Mock20.cairo",[0x01,0x01,18,ids.contract_address]).contract_address
        ids.token_address = context.token_address
        context.karma_address = deploy_contract("./src/modules/token/Karma.cairo",[0x01,0x01,18,ids.contract_address]).contract_address
        context.xoroshiro_address = deploy_contract("./src/modules/utils/random/Xoroshiro128SS.cairo", [42]).contract_address
        context.deadly_games_address = deploy_contract("./src/DeadlyGames.cairo").contract_address
        context.greed_address = deploy_contract("./src/modules/games/greed/Greed.cairo",[context.deadly_games_address]).contract_address
        context.greed_mark_address = deploy_contract("./src/modules/games/greed/GreedMark.cairo", [0x4772656564204D61726B,0x474D41524B, context.greed_address]).contract_address
    %}
    let (balance : Uint256) = IERC20.balanceOf(
        contract_address=token_address, account=contract_address
    )
    uint256_eq(balance, Uint256(100, 0))
    set_addresses()
    add_active_greed()
    return ()
end

func set_addresses{syscall_ptr : felt*, range_check_ptr}():
    tempvar token_address : felt
    tempvar deadly_games_address : felt
    tempvar karma_address : felt
    tempvar pseudo_address : felt
    tempvar greed_address : felt
    tempvar greed_mark_address : felt
    %{
        ids.greed_address = context.greed_address
        ids.token_address = context.token_address
        ids.deadly_games_address = context.deadly_games_address
        ids.karma_address = context.karma_address
        ids.pseudo_address = context.xoroshiro_address
        ids.greed_mark_address = context.greed_mark_address
    %}
    IGreed.set_addresses(
        contract_address=greed_address,
        token_address=token_address,
        deadly_games_address=deadly_games_address,
        karma_address=karma_address,
        pseudo_address=pseudo_address,
        greed_mark_address=greed_mark_address,
    )
    IDeadlyGames.set_karma_address(
        contract_address=deadly_games_address, karma_address=karma_address
    )
    IKarma.transferOwnership(contract_address=karma_address, newOwner=deadly_games_address)
    IGreedMark.set_greed_addr(contract_address=greed_mark_address, addr=greed_address)
    return ()
end

func add_active_greed{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    local greed_address : felt
    local deadly_games_address : felt
    %{
        ids.greed_address=context.greed_address
        ids.deadly_games_address=context.deadly_games_address
    %}
    IDeadlyGames.add_game(
        contract_address=deadly_games_address, name=42, author=42, implementation=greed_address
    )
    IDeadlyGames.activate_game(contract_address=deadly_games_address, id=1)
    return ()
end

@external
func test_greed_entry{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    let (local contract_address : felt) = get_contract_address()
    local greed_address : felt
    local token_address : felt
    local greed_mark_address : felt
    %{
        ids.greed_address = context.greed_address
        ids.token_address = context.token_address
        ids.greed_mark_address = context.greed_mark_address
    %}
    IERC20.approve(contract_address=token_address, spender=greed_address, amount=Uint256(2, 0))
    let (allowance : Uint256) = IERC20.allowance(
        contract_address=token_address, owner=contract_address, spender=greed_address
    )
    uint256_eq(allowance, Uint256(2, 0))
    %{ expect_events({"name": "greed_entry", "data": [ids.contract_address,1]},{"name": "new_record_created", "data":[ids.contract_address]},{"name": "greed_loser", "data":[ids.contract_address]}) %}
    IGreed.greed(contract_address=greed_address, ticket_amount=1)
    let (local user_record) = IGreedMark.get_user_record(
        contract_address=greed_mark_address, user=contract_address
    )
    assert_eq(user_record.fcker_count, 1)
    assert_eq(user_record.lcker_count, 0)
    return ()
end

@external
func test_greed_multiple_entry{syscall_ptr : felt*, range_check_ptr}():
    greed_multiple_entry(10)
    return ()
end

func greed_multiple_entry{syscall_ptr : felt*, range_check_ptr}(count : felt):
    alloc_locals
    let (local contract_address : felt) = get_contract_address()
    local greed_address : felt
    local token_address : felt
    local greed_mark_address : felt

    jmp body if count != 0
    return ()

    body:
    %{
        ids.greed_address = context.greed_address
        ids.token_address = context.token_address
        ids.greed_mark_address = context.greed_mark_address
    %}
    IERC20.approve(contract_address=token_address, spender=greed_address, amount=Uint256(2, 0))
    let (allowance : Uint256) = IERC20.allowance(
        contract_address=token_address, owner=contract_address, spender=greed_address
    )
    uint256_eq(allowance, Uint256(2, 0))
    %{ expect_events({"name": "greed_entry", "data": [ids.contract_address,1]},{"name": "new_record_created", "data":[ids.contract_address]},{"name": "greed_loser", "data":[ids.contract_address]}) %}
    IGreed.greed(contract_address=greed_address, ticket_amount=1)
    let (local user_record) = IGreedMark.get_user_record(
        contract_address=greed_mark_address, user=contract_address
    )
    assert_eq(user_record.fcker_count, 11 - count)
    return greed_multiple_entry(count - 1)
end
