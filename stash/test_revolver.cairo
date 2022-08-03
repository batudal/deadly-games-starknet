%lang starknet

from protostar.asserts import assert_eq, assert_not_eq
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from src.modules.games.greed.IGreed import IRevolver
from src.helpers.Interfaces import IDeadlyGames, IKarma
from starkware.starknet.common.syscalls import get_contract_address
from src.openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from src.modules.games.revolver.Constants import TICKET_PRICE

@external
func __setup__{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    let (local contract_address : felt) = get_contract_address()
    tempvar token_address
    %{
        context.token_address = deploy_contract("./src/mock/Mock20.cairo",[0x01,0x01,18,ids.contract_address]).contract_address
        ids.token_address = context.token_address
        context.karma_address = deploy_contract("./src/modules/token/Karma.cairo",[0x01,0x01,18,ids.contract_address]).contract_address
        context.deadly_games_address = deploy_contract("./src/DeadlyGames.cairo",[ids.contract_address]).contract_address
        context.revolver_address = deploy_contract("./src/modules/games/revolver/Revolver.cairo",[context.deadly_games_address]).contract_address
        context.xoroshiro_address = deploy_contract("./src/modules/utils/random/Xoroshiro128SS.cairo", [42,context.revolver_address]).contract_address
    %}
    let (balance : Uint256) = IERC20.balanceOf(
        contract_address=token_address, account=contract_address
    )
    uint256_eq(balance, Uint256(100, 0))
    set_addresses()
    add_active_revolver()
    return ()
end

func add_active_revolver{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    local revolver_address : felt
    local deadly_games_address : felt
    %{
        ids.revolver_address=context.revolver_address
        ids.deadly_games_address=context.deadly_games_address
    %}
    IDeadlyGames.add_game(
        contract_address=deadly_games_address, name=42, author=42, implementation=revolver_address
    )
    IDeadlyGames.activate_game(contract_address=deadly_games_address, id=1)
    return ()
end

@external
func test_revolver_entry{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    let (local contract_address : felt) = get_contract_address()
    local revolver_address : felt
    local token_address : felt
    %{
        ids.revolver_address = context.revolver_address
        ids.token_address = context.token_address
    %}
    IERC20.approve(contract_address=token_address, spender=revolver_address, amount=Uint256(TICKET_PRICE, 0))
    let (allowance : Uint256) = IERC20.allowance(
        contract_address=token_address, owner=contract_address, spender=revolver_address
    )
    uint256_eq(allowance, Uint256(TICKET_PRICE, 0))
    # add event expectation here
    IRevolver.enter(contract_address=revolver_address, ticket_amount=1)
    # add assertions here
    return ()
end