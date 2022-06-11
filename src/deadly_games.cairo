%lang starknet

from openzeppelin.token.erc721.ERC721_Mintable_Burnable import constructor
from starkware.cairo.common.math import assert_nn

const DEADLY_PERKS_ADDRESS = (
    0x2Db8c2615db39a5eD8750B87aC8F217485BE11EC)

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
    user_perks.write(user=user, perks=_perks)
end
