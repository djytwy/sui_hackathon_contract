// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module pts::pts {
    use sui::{
        coin::{Self ,Coin,  TreasuryCap},
        balance,
        url
    };

    // === Constants ===
    /// The maximum supply of the E4C token. 1 Billion E4C tokens including two decimals.
    const PtsTokenDecimalPoints: u64 = 1_000_000_000;
    const PtsTokenMaxSupply: u64 = 1_000_000_000 * PtsTokenDecimalPoints;

    // TODO: update the token metadata according to the requirements.
    const PtsTokenDecimals: u8 = 9;
    const PtsTokenSymbol: vector<u8> = b"PTS";
    const PtsTokenName: vector<u8> = b"$PTS";
    const PtsTokenDescription: vector<u8> = b"The $PTS token, pool token ";
    const PtsTokenURL: vector<u8> = b"https://ambrus.s3.amazonaws.com/E4C-tokenicon.png";

    /// [One Time Witness] Pts is a one-time witness struct that is used to initialize the Pts token.
    public struct PTS has drop {}

     const AddressHadExist: u64 = 0;
     const AmountLessThenzero: u64 =1;
     const OnlyOwnerCanAddAdmin: u64 = 2;
    
       public struct AllowCap<phantom T> has key, store {
        id: UID,
        addresses: vector<address>,
        owner: address,
    }

    public struct MintCap<phantom T> has key, store {
        id: UID,
            treasury_cap: TreasuryCap<T>,
        }
    fun init(otw: PTS, ctx: &mut TxContext) {
        // Create a regulated currency with the given metadata.


        let  ( treasury_cap, metadata ) = coin::create_currency(
            otw,
            PtsTokenDecimals,
            PtsTokenSymbol,
            PtsTokenName,
            PtsTokenDescription,
            option::some(url::new_unsafe_from_bytes(PtsTokenURL)),
            ctx
        );
    
       let allowCap = AllowCap<PTS> {
              id: object::new(ctx),
              addresses: vector::empty(),
              owner: ctx.sender(),
         };

          // Send the deny cap to the sender.
          transfer::public_share_object(allowCap);
          // Send the total supply; 1B to the sender.
          transfer::public_share_object(MintCap{id: object::new(ctx),treasury_cap});
       
    
        // Unwrap and burn the treasury cap and get the total supply.

        // Freeze the metadata and total supply object.
    
        transfer::public_freeze_object(metadata);
        
    }

    public fun is_allow(allow_cap: &AllowCap<PTS>, admin: address):bool {
        vector::contains<address>(&allow_cap.addresses, &admin)
    }

    public fun add_allow_cap(allow_cap: &mut AllowCap<PTS>, admin: address, ctx: &TxContext) {
           assert!(!vector::contains<address>(&allow_cap.addresses, &admin), AddressHadExist);
           assert!(allow_cap.owner == ctx.sender(), OnlyOwnerCanAddAdmin);
           let len  = vector::length(&allow_cap.addresses);
           vector::insert(&mut allow_cap.addresses,  admin,len);
    }
    public fun mint(allow_cap: &AllowCap<PTS>, mintCap: &mut MintCap<PTS>, to: address,  amount: u64, ctx: &mut TxContext) {
        assert!(amount > 0, AmountLessThenzero);
        assert!(vector::contains<address>(&allow_cap.addresses, &ctx.sender()), AddressHadExist);
       let MintCap{
            ..,
            treasury_cap,
       } = mintCap;
       let create_coin=  coin::mint(treasury_cap, amount, ctx);
         transfer::public_transfer(create_coin, to);
    }
    public fun burn( mintCap: &mut MintCap<PTS>, coins: Coin<PTS>) {
          let MintCap{
            ..,
            treasury_cap,
       } = mintCap;
        coin::burn(treasury_cap, coins);
    }


        public fun get_transfer_cap(meta: &MintCap<PTS>): u64 {
                coin::total_supply(&meta.treasury_cap)
            }
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) { init(PTS {}, ctx); }

}