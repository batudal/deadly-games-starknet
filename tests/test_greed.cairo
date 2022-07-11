%lang starknet

from protostar.asserts import assert_eq, assert_not_eq
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from src.modules.games.greed.IGreed import IGreed
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

@external
func test_greed_entry{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    local deadly_games_address : felt
    local greed_address : felt
    local xoroshiro_address : felt
    let (local caller) = get_caller_address()
    %{
        stop_prank_callable = start_prank(123)
        ids.xoroshiro_address = deploy_contract("./src/modules/utils/random/Xoroshiro128SS.cairo", [42]).contract_address
        ids.deadly_games_address = deploy_contract("./src/DeadlyGames.cairo").contract_address
        ids.greed_address = deploy_contract("./src/modules/games/greed/Greed.cairo",[ids.deadly_games_address]).contract_address
        expect_events({"name": "greed_entry", "data": [50]})
    %}
    IGreed.set_pseudo_address(contract_address=greed_address, pseudo_address=xoroshiro_address)
    IGreed.greed(contract_address=greed_address, ticket_amount=50)
    %{ stop_prank_callable() %}
    return ()
end
