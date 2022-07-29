%lang starknet

from src.helpers.Interfaces import IXoroshiro128
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem, split_felt
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
)
from starkware.cairo.common.math import unsigned_div_rem
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_mul,
    uint256_sub,
    uint256_unsigned_div_rem,
    uint256_add,
    uint256_le,
)

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
func token_address() -> (address : felt):
end

@storage_var
func pseudo_addr() -> (address : felt):
end

@event
func new_entry(user : felt, round : felt):
end

@event
func shots_fired(loser : felt):
end

@view
func latest_round() -> (round : Round):
    let (index : felt) = counter.read()
    let (last_round : Round) = rounds.read(count=index)
    return (last_round)
end

func get_next_rnd{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    rnd : felt
):
    alloc_locals
    let (local addr) = pseudo_addr.read()
    let (rnd) = IXoroshiro128.next(contract_address=addr)
    return (rnd)
end

func register_player(counter : felt, round : Round, user_index : felt, caller : felt):
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
    rounds.write(count=counter, round=round)
    return()
end

@external
func enter(round : felt):
    let (caller : felt) = get_caller_address()
    entrance_check(caller)
    new_entry.emit(user=caller)
    let (current_count : felt) = counter.read()
    counter.write(current_count + 1)
    let (round : felt, user_index : felt) = unsigned_div_rem(current_count, 6)
    let (current_round : Round) = rounds.read(round)
    register_player(counter=current_count, round=current_round, user_index=user_index, caller=caller)

    if user_index == 0:
        let (local loser : felt) = fire()
        distribute_rewards(round=current_round, loser=loser)
        create_new_round(round=current_round)
    end
    return ()
end

func fire() -> (loser : felt):
    let (rnd : felt) = get_next_rnd()
    let (q, r) = unsigned_div_rem(rnd, 6)
    let (loser_index) = r + 1
    return (loser_index)
end

func distribute_rewards(round : felt, loser : felt):
    let (token) = token_address.read()
    let (amount,_) = unsigned_div_rem(TICKET_PRICE, 5)
    let (token_amount : Uint256) = split_felt(amount)
    let (winners : felt*) = get_winners_array(round=round, loser=loser)
    send_recursive(5, winners, token_amount)
    return ()
end

func send_recursive(counter : felt, winners : felt*, amount : Uint256):
    if counter == 0:
        return()
    end
    let (player) = winners[counter]
    IERC20.transfer(contract_address=token_addr, recipient=player, amount=amount)
    send_recursive(counter - 1, winners, amount)
end

func create_new_round(round : felt):

    return ()
end

func get_winners_array(round : Round, loser : felt) -> (winners : felt*):
    alloc_locals
    let (local players : felt*)
    let (local index) = 0
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
    return(winners)
end

func entrance_check(caller : felt):
    
end
