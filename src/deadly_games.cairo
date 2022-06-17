%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.cairo_keccak.keccak import keccak_felts, finalize_keccak, keccak_bigend
const DEADLY_PERKS_ADDRESS = (0xaB9F9F4e9aadf82Fbf0Fa171De0f5eebaf2D859f)
let PREFIXES : (
    felt, felt, felt, felt, felt, felt, felt, felt, felt
) = (
    'Formation: ',
    'Greed: ',
    'Lust: ',
    'Wrath: ',
    'Gluttony: ',
    'Pride: ',
    'Envy: ',
    'Sloth: ',
    '???: ')

struct Perks:
    member formation : felt
    member greed : felt
    member lust : felt
    member wrath : felt
    member gluttony : felt
    member pride : felt
    member envy : felt
    member sloth : felt
    member key : felt
end

@storage_var
func user_perks(user : felt) -> (perks : Perks):
end

@storage_var
func perk_lengths(id : felt) -> (length : felt):
end

@storage_var
func perk_prefixes(index : felt) -> (prefix : felt):
end

@event
func perks_bridged(user : felt, tokenId : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    prefixes_len : felt, prefixes : felt*
):
    perk_prefixes.write(0, prefixes[0])
    perk_prefixes.write(1, prefixes[1])
    perk_prefixes.write(2, prefixes[2])
    perk_prefixes.write(3, prefixes[3])
    perk_prefixes.write(4, prefixes[4])
    perk_prefixes.write(5, prefixes[5])
    perk_prefixes.write(6, prefixes[6])
    perk_prefixes.write(7, prefixes[7])
    perk_prefixes.write(8, prefixes[8])
    return ()
end

@l1_handler
func bridge_handler{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    from_address : felt,
    user : felt,
    tokenId : felt,
    formation : felt,
    greed : felt,
    lust : felt,
    wrath : felt,
    gluttony : felt,
    pride : felt,
    envy : felt,
    sloth : felt,
    key : felt,
):
    assert from_address = DEADLY_PERKS_ADDRESS
    let _perks = Perks(
        formation=formation,
        greed=greed,
        lust=lust,
        wrath=wrath,
        gluttony=gluttony,
        pride=pride,
        envy=envy,
        sloth=sloth,
        key=key,
    )
    user_perks.write(user, _perks)
    perks_bridged.emit(user=user, tokenId=tokenId)
    return ()
end

@view
func get_user_perks{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    user : felt
) -> (res : Perks):
    let (res) = user_perks.read(user=user)
    return (res)
end

@view
func get_perk_index{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(token_id : felt, perk_selector : felt) -> (res : felt):
    alloc_locals
    let inputs : felt* = alloc()
    assert inputs[0] = 'greed: '  # prefix
    assert inputs[1] = token_id
    let keccak_res : Uint256 = compute_keccak(input_len=2, input=inputs, n_bytes=2)
    let (local perk_length : felt) = perk_lengths.read(token_id)
    let (q, r) = unsigned_div_rem(value=keccak_res.low, div=perk_length)
    return (r)
end

@view
func compute_keccak{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
    input_len : felt, input : felt*, n_bytes : felt
) -> (res : Uint256):
    alloc_locals

    let (local keccak_ptr_start : felt*) = alloc()
    let keccak_ptr = keccak_ptr_start

    let (local output : Uint256) = keccak_bigend{keccak_ptr=keccak_ptr}(input, n_bytes)
    finalize_keccak(keccak_ptr_start=keccak_ptr_start, keccak_ptr_end=keccak_ptr)

    return (output)
end
