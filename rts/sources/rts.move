// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module rts::rts {
    use sui::{
        coin::{Self},
        balance,
        url
    };

    // === Constants ===
    /// The maximum supply of the E4C token. 1 Billion E4C tokens including two decimals.
    const RtsTokenDecimalPoints: u64 = 1_000_000_000;
    const RtsTokenMaxSupply: u64 = 1_000_000_000 * RtsTokenDecimalPoints;

    // TODO: update the token metadata according to the requirements.
    const RtsTokenDecimals: u8 = 9;
    const RtsTokenSymbol: vector<u8> = b"Rts";
    const RtsTokenName: vector<u8> = b"$Rts";
    const RtsTokenDescription: vector<u8> = b"The $Rts token, ";
    const RtsTokenURL: vector<u8> = b"https://ambrus.s3.amazonaws.com/E4C-tokenicon.png";
    /// [frozen Object] E4CFunded is a struct that holds the total supply of the E4C token.
    public struct RtsTotalSupply has key {
        id: UID,
        total_supply: balance::Supply<RTS>
    }

    /// [One Time Witness] Rts is a one-time witness struct that is used to initialize the Rts token.
    public struct RTS has drop {}

    fun init(rts: RTS, ctx: &mut TxContext) {
        // Create a regulated currency with the given metadata.
        let (mut treasury_cap, deny_cap, metadata) = coin::create_regulated_currency(
            rts,
            RtsTokenDecimals,
            RtsTokenSymbol,
            RtsTokenName,
            RtsTokenDescription,
            option::some(url::new_unsafe_from_bytes(RtsTokenURL)),
            ctx
        );
        // Mint the coin and get the coin object.
        let coin = coin::mint(&mut treasury_cap, RtsTokenMaxSupply, ctx);
        // Unwrap and burn the treasury cap and get the total supply.
        let total_supply = treasury_cap.treasury_into_supply();

        // Freeze the metadata and total supply object.
    
        transfer::public_freeze_object(metadata);
        transfer::freeze_object(RtsTotalSupply { id: object::new(ctx), total_supply });
        
        // Send the deny cap to the sender.
        transfer::public_transfer(deny_cap, ctx.sender());
        // Send the total supply; 1B to the sender.
        transfer::public_transfer(coin, ctx.sender());

    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) { init(RTS {}, ctx); }

    #[test_only]
    public fun get_total_supply(meta: &RtsTotalSupply): u64 {
        balance::supply_value(&meta.total_supply)
    }
}