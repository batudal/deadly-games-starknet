%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.cairo_keccak.keccak import keccak_felts, finalize_keccak, keccak_bigend

const DEADLY_PERKS_ADDRESS = (0xaB9F9F4e9aadf82Fbf0Fa171De0f5eebaf2D859f)
# let PREFIXES : (
#     felt, felt, felt, felt, felt, felt, felt, felt, felt
# ) = (
#     'Formation: ',
#     'Greed: ',
#     'Lust: ',
#     'Wrath: ',
#     'Gluttony: ',
#     'Pride: ',
#     'Envy: ',
#     'Sloth: ',
#     '???: ')
#     let PARSED_PREFIXES : (
#     (felt, felt) , felt, felt, felt, (felt, felt), felt, felt, felt, felt
# ) = (
#     ['oitamroF',' :n'],
#     [' :deerG'],
#     [' :tsuL'],
#     [' :htarW'],
#     ['ynottulG',' :'],
#     [' :edirP'],
#     [' :yvnE'],
#     [' :htolS'],
#     [' :???'])

struct Prefix:
    member prefix : felt
    member parsed : felt
    member length : felt
end

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
func prefixes(id : felt) -> (prefix : Prefix*):
end

@storage_var
func user_perks(user : felt) -> (perks : Perks):
end

@storage_var
func perk_prefixes(index : felt) -> (prefix : felt):
end

@event
func perks_bridged(user : felt, tokenId : felt):
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
    let keccak_res : Uint256 = compute_keccak(input_len=2, input=inputs, n_bytes=2)
    let (local perk_length : felt) = perk_lengths.read(token_id)
    let (q, r) = unsigned_div_rem(value=keccak_res.low, div=perk_length)
    return (r)
end

@view
func compute_keccak{output_ptr : felt*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
    prefix_id : felt, token_id : felt, n_bytes : felt
) -> (res : Uint256):
    alloc_locals
    let (local keccak_ptr : felt*) = alloc()
    let keccak_ptr_start = keccak_ptr
    tempvar _prefix = prefixes.read(id=token_id)
    tempvar _length = 0
    let (local input : felt*) = alloc()
    let (local input_ : felt) = alloc()
    if prefix_id == 0:
        assert input[0] = 'oitamroF'
        assert input[1] = ' :n'
        assert input[2] = token_id
        input_ = 'Formation: '
        _length = 11
    end
    if prefix_id == 1:
        assert input[0] = ' :deerG'
        assert input[1] = token_id
        input_ = 'Greed: '
        _length = 7
    end
    if prefix_id == 2:
        assert input[0] = ' :tsuL'
        assert input[1] = token_id
        input_ = 'Lust: '
        _length = 6
    end
    if prefix_id == 3:
        assert input[0] = ' :htarW'
        assert input[1] = token_id
        input_ = 'Wrath: '
        _length = 7
    end
    if prefix_id == 4:
        assert input[0] = 'ynottulG'
        assert input[1] = ' :'
        assert input[2] = token_id
        input_ = 'Gluttony: '
        _length = 10
    end
    if prefix_id == 5:
        assert input[0] = ' :edirP'
        assert input[1] = token_id
        input_ = 'Pride: '
        _length = 7
    end
    if prefix_id == 6:
        assert input[0] = ' :yvnE'
        assert input[1] = token_id
        input_ = 'Envy: '
        _length = 6
    end
    if prefix_id == 7:
        assert input[0] = ' :htolS'
        assert input[1] = token_id
        input_ = 'Sloth: '
        _length = 7
    end
    if prefix_id == 8:
        assert input[0] = ' :???'
        assert input[1] = token_id
        input_ = '???: '
        _length = 5
    end

    let (output) = keccak{keccak_ptr=keccak_ptr}(input, _length)
    %{
        input_str = ids.input_ + ids.token_id
        output = ''.join(v.to_bytes(8, 'little').hex() for v in memory.get_range(ids.output, 4))
        print(f'Keccak of "{input_str}": {output}')
        from web3 import Web3
        assert '0x' + output == Web3.keccak(text=input_str).hex()
    %}
    assert output_ptr[0] = output[0]
    assert output_ptr[1] = output[1]
    assert output_ptr[2] = output[2]
    assert output_ptr[3] = output[3]
    let output_ptr = output_ptr + 4

    finalize_keccak(keccak_ptr_start=keccak_ptr_start, keccak_ptr_end=keccak_ptr)
    return (output)
end
