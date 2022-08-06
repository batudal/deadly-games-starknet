%lang starknet

from starkware.cairo.common.alloc import alloc
from src.helpers.Interfaces import IXoroshiro128
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem, split_felt, assert_not_equal
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
)
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_mul,
    uint256_sub,
    uint256_unsigned_div_rem,
    uint256_add,
    uint256_le,
)

@event
func new_entry(user : felt, round_index : felt):
end

@event
func shots_fired(loser : felt):
end

@event
func emergency_shutdown_executed():
end

@event
func new_round(round : felt):
end

struct Round:
    member player_1 : felt
    member player_2 : felt
    member player_3 : felt
    member player_4 : felt
    member player_5 : felt
    member player_6 : felt
end

const TICKET_PRICE = 10000000000000000

@storage_var
func counter() -> (count : felt):
end

@storage_var
func rounds(count : felt) -> (round : Round):
end

@storage_var
func token_addr() -> (address : felt):
end

@storage_var
func pseudo_addr() -> (address : felt):
end

@storage_var
func deadly_games_addr() -> (address : felt):
end

@storage_var
func initialized() -> (state : felt):
end

@view
func latest_round{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    round : Round
):
    let (index : felt) = counter.read()
    let (last_round : Round) = rounds.read(count=index)
    return (last_round)
end

@external
func set_addresses{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_address : felt, deadly_games_address : felt, pseudo_address : felt
):
    let (state) = initialized.read()
    assert (state) = 0
    token_addr.write(token_address)
    deadly_games_addr.write(deadly_games_address)
    pseudo_addr.write(pseudo_address)
    initialized.write(1)
    return ()
end

func get_next_rnd{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    rnd : felt
):
    alloc_locals
    let (local addr) = pseudo_addr.read()
    let (rnd) = IXoroshiro128.next(contract_address=addr)
    return (rnd)
end

func register_player{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    counter : felt, round : Round, user_index : felt, caller : felt
):
    if user_index == 1:
        assert round.player_1 = caller
    end
    if user_index == 2:
        assert round.player_2 = caller
    end
    if user_index == 3:
        assert round.player_3 = caller
    end
    if user_index == 4:
        assert round.player_4 = caller
    end
    if user_index == 5:
        assert round.player_5 = caller
    end
    if user_index == 0:
        assert round.player_6 = caller
    end
    rounds.write(count=counter, value=round)
    return ()
end

@external
func enter{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    let (caller : felt) = get_caller_address()
    let (current_count : felt) = counter.read()
    counter.write(current_count + 1)

    let (local round_index : felt, local user_index : felt) = unsigned_div_rem(current_count, 6)
    let (local current_round : Round) = rounds.read(round_index)
    entrance_check(round=current_round, caller=caller)
    register_player(
        counter=current_count, round=current_round, user_index=user_index, caller=caller
    )
    new_entry.emit(user=caller, round_index=round_index)

    if user_index == 5:
        let (loser : felt) = fire()
        distribute_rewards(round=current_round, loser=loser)
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    if user_index == 0:
        create_new_round(round_index=round_index, caller=caller)
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        entrance_check(round=current_round, caller=caller)
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end
    return ()
end

func fire{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (loser : felt):
    let (rnd : felt) = get_next_rnd()
    let (q, r) = unsigned_div_rem(rnd, 6)
    return (r)
end

func distribute_rewards{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    round : Round, loser : felt
):
    let (amount, _) = unsigned_div_rem(TICKET_PRICE, 5)
    let (token_amount : Uint256) = split_felt(amount)
    let (winners : felt*) = get_winners_array(round=round, loser=loser)
    send_recursive(5, winners, token_amount)
    return ()
end

func send_recursive{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    counter : felt, winners : felt*, amount : Uint256
):
    if counter == 0:
        return ()
    end
    let (token_address) = token_addr.read()
    let (player) = winners[counter]
    IERC20.transfer(contract_address=token_address, recipient=player, amount=amount)
    send_recursive(counter - 1, winners, amount)
end

func create_new_round{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    round_index : felt, caller : felt
):
    let (new_round : Round) = Round(player_1=caller)
    rounds.write(count=round_index + 1, round=new_round)
    new_round.emit(round_index + 1)
    return ()
end

func get_winners_array{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    round : Round, loser : felt
) -> (winners : felt*):
    alloc_locals
    let (local index) = 0
    let (local winners : felt*) = alloc()
    if round.player_1 != loser:
        assert winners[index] = round.player_1
        index = index + 1
    end
    if round.player_2 != loser:
        assert winners[index] = round.player_2
        index = index + 1
    end
    if round.player_3 != loser:
        assert winners[index] = round.player_3
        index = index + 1
    end
    if round.player_4 != loser:
        assert winners[index] = round.player_4
        index = index + 1
    end
    if round.player_5 != loser:
        assert winners[index] = round.player_5
        index = index + 1
    end
    if round.player_6 != loser:
        assert winners[index] = round.player_6
        index = index + 1
    end
    return (winners)
end

func entrance_check{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    round : Round, caller : felt
):
    assert_not_equal(round.player1, caller)
    assert_not_equal(round.player2, caller)
    assert_not_equal(round.player3, caller)
    assert_not_equal(round.player4, caller)
    assert_not_equal(round.player5, caller)
end
