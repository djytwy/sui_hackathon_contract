// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module ots_staking::staking {

    use sui::{
        balance::{Self, Balance},
        coin::{Self, Coin},
        event,
        math,
        table::{Self, Table},
        transfer::{Self, public_share_object},
        clock::Clock,
    };

    use ots::ots::OTS;
    use ots_staking::pts::{Self, PTS , AllowCap, MintCap};

    // === Errors ===
    const EStakingQuantityTooLow: u64 = 0;
    const EStakingQuantityTooHigh: u64 = 1;
    const EStakingTimeNotEnded: u64 = 2;
    const EAmountMustBeGreaterThanZero: u64 = 3;
    const EAmountTooHigh: u64 = 4;
    const ENotOwner: u64 = 5;
    const EStakingOver: u64 = 6;
    const ESTakingTimeShort: u64 = 7;

    /// [Owned Object]: StakingReceipt represents a receipt of staked tokens.
    /// The receipt will have complete setup upon creation including rewards since it's fixed.
    /// Once it's created, you can only unstake the tokens when the staking time is ended.
    public struct StakingReceipt has key, store {
        id: UID,
        // Amount of tokens staked in the receipt
        amount_staked: u64,
        owner: address
    }

    public struct Claimed has copy, drop {
        receipt_id: ID,
        owner: address,
        amount: u64,
    }
     public struct DropRewardPool has key, store { 
        id: UID,
        balance: Balance<PTS>,

    }

    /// [Shared Object]: GameLiquidityPool is a store of minted OTS tokens.
    public struct GameLiquidityPool has key {
        id: UID,
        balance: Balance<OTS>,
        ctoken: u64,
        otoken: u64,
        owner: address,
    }

    /// Event emitted when a new staking receipt is created
    public struct Staked has copy, drop {
        receipt_id: ID,
        owner: address,
        amount: u64,
    }


    public struct RewardPoolToken has copy, drop {
            receipt_id: ID,
            owner: address,
            amount: u64,
        }
    public struct ReceiptCreate has copy, drop {
        receipt_id: ID,
        owner: address
    }

     public struct RewardPoolCreate has copy, drop {
        receipt_id: ID,
        owner: address
    }

    /// Event emitted when unstaking tokens from a receipt
    public struct Unstaked has copy, drop {
        receipt_id: ID,
        owner: address,
        amount: u64,
    }

    /// Event emitted when ots tokens are placed in the GameLiquidityPool
    public struct PoolPlaced has copy, drop {
        sender: address,
        amount: u64,
    }

    /// Event emitted when ots tokens are taken from the GameLiquidityPool
    public struct PoolWithdrawn has copy, drop {
        sender: address,
        amount: u64,
    }
    public struct AutherizeCap has key, store {
        id: UID,
    }

    public struct RewardCap<phantom T> has key, store {
        id: UID,
        balance: Balance<T>,
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(
            GameLiquidityPool { id: object::new(ctx), balance: balance::zero() , otoken:0, ctoken: 0, owner: ctx.sender() }
        );
         transfer::transfer(AutherizeCap {
            id: object::new(ctx),
        }, ctx.sender());
    }


public fun create_reward_pool<T:drop>(_:&AutherizeCap,ctx: &mut TxContext){
    let id =object::new(ctx);
    let eid = id.to_inner();
    let rewardCap = RewardCap<T> {
        id: id,
        balance: balance::zero(),
    };
    transfer::share_object(rewardCap);
    event::emit(RewardPoolCreate {
        receipt_id: eid,
        owner: ctx.sender()
    });
}

  public fun create_stake_receive(ctx: &mut TxContext):StakingReceipt{
    let id =object::new(ctx);
    let eid = id.to_inner();

       event::emit(ReceiptCreate {
            receipt_id: eid,
            owner: ctx.sender()
        });
        StakingReceipt {
            id: id,
            amount_staked: 0,
            owner: ctx.sender(),
        }

  }

  public fun getStakeReceiptAmount(receipt: &StakingReceipt):u64 {
    receipt.amount_staked
  }
  public fun getGameLiquidityPoolBalance(liquidity_pool: &GameLiquidityPool):u64 {
        liquidity_pool.balance.value()
  }

  public fun getGameLiquidityPoolPool(liquidity_pool: &GameLiquidityPool):u64 {
        liquidity_pool.ctoken
  }

public fun getDropRewardPoolBalance(drop_reward_pool: &DropRewardPool):u64 {
drop_reward_pool.balance.value()
}

  public fun reward_pool_token(
        mintCap: &mut MintCap<PTS>, 
        reward: u64,
        ctx: &mut TxContext){
        let id = object::new(ctx);
       let eid = id.to_inner();
       let pts_coin = pts::mint_reward(mintCap, reward, ctx);
        // liquidity_pool.ctoken = liquidity_pool.ctoken + reward;
        public_share_object(DropRewardPool {
            id: id,
            balance: pts_coin.into_balance(),
        });
        event::emit(RewardPoolToken {
            receipt_id: eid,
            owner: ctx.sender(),
            amount: reward,
        });
     }

     public fun computer(liquidity_pool: &mut GameLiquidityPool,drop_reward_pool: &mut DropRewardPool, stake_receipt:&mut StakingReceipt):u64{
         let pre_step =(stake_receipt.amount_staked as u128) * (drop_reward_pool.balance.value() as u128);
             pre_step.divide_and_round_up(liquidity_pool.ctoken as u128) as u64

     }

     public fun claim_pool_token(liquidity_pool: &mut GameLiquidityPool,drop_reward_pool: &mut DropRewardPool, stake_receipt:&mut StakingReceipt,ctx: &mut TxContext):Coin<PTS>{
        
        assert!(stake_receipt.amount_staked > 0, EStakingQuantityTooLow);
         assert!(stake_receipt.amount_staked < liquidity_pool.ctoken , EStakingQuantityTooLow);
         assert!(liquidity_pool.ctoken > 0 , EStakingQuantityTooLow); 
    let pre_step =(stake_receipt.amount_staked as u128) * (drop_reward_pool.balance.value() as u128);
        let StakingReceipt{
            id:_,
            amount_staked:_,
            owner:_,
        } = stake_receipt;
        
        let  DropRewardPool{
            id:_,
            balance: _,
        } = drop_reward_pool;

        let  GameLiquidityPool{
                id:_,
                balance: _,
                otoken:_,
                ctoken,
                    owner:_,
             } = liquidity_pool;

        let reward_amount = pre_step.divide_and_round_up(*ctoken as u128) as u64;
       let  pts_coin= coin::take(&mut drop_reward_pool.balance, reward_amount, ctx);

        liquidity_pool.ctoken = liquidity_pool.ctoken + reward_amount;
        event::emit(Claimed {
            receipt_id: stake_receipt.id.to_inner(),
            owner: ctx.sender(),
            amount: reward_amount,
        });
        pts_coin
     }


public fun stake(
        stake: Coin<OTS>,
        liquidity_pool: &mut GameLiquidityPool,
        allowCap: &AllowCap<PTS>,
        mintCap: &mut MintCap<PTS>, 
        receipt: &mut StakingReceipt,
        ctx: &mut TxContext
    ){
       let GameLiquidityPool{
              id,
              balance: ostBalance,
              otoken,
              ctoken,
                owner,
         } = liquidity_pool;
         
         let origin_balance = coin::value(&stake);
                 assert!(origin_balance > 0, EStakingQuantityTooLow);
            let exchange_token  = stake.value() * 1;

        pts::mint(allowCap, mintCap, ctx.sender(), exchange_token, ctx);


        event::emit(Staked {
            receipt_id: receipt.id.to_inner(),
            owner: ctx.sender(),
            amount:origin_balance,
        });
        
        balance::join(&mut liquidity_pool.balance, stake.into_balance());
        liquidity_pool.ctoken = liquidity_pool.ctoken + exchange_token;
        liquidity_pool.otoken = liquidity_pool.otoken + origin_balance;
        receipt.amount_staked = receipt.amount_staked + origin_balance;
    }


 public fun add_reward<T:drop>( rewardCap: & mut RewardCap<T>, coins: Coin<T>){
    assert!(coins.value() > 0, EAmountMustBeGreaterThanZero);
    balance::join(&mut rewardCap.balance, coins.into_balance());
  }

  public fun drop_reword<T:drop>( rewardCap: & mut RewardCap<T>, share: u64, to: address, ctx: &mut TxContext){
    assert!(share > 0, EAmountMustBeGreaterThanZero);
    let bs = balance::split(&mut rewardCap.balance, share);
    let coins = coin::from_balance(bs, ctx);
    transfer::public_transfer(coins,  to);

  }

    /// Unstake the tokens from the receipt.
    /// This function can be called only when the staking time is ended
    public fun unstake(
        receipt: StakingReceipt,
         liquidity_pool: &mut GameLiquidityPool,
        ctx: &mut TxContext
    ):Coin<OTS> {
        let StakingReceipt {
            id,
            amount_staked,
            owner:_,
        } = receipt;

        event::emit(Unstaked {
            receipt_id: id.to_inner(),
            owner: ctx.sender(),
            amount: amount_staked,
        });

        id.delete();
                 liquidity_pool.otoken = liquidity_pool.otoken - amount_staked;
           let GameLiquidityPool{
              id:_,
              balance: ostBalance,
              otoken:_,
              ctoken:_,
                owner:_,
         } = liquidity_pool;
         assert!(ostBalance.value() >= amount_staked, EAmountTooHigh);
        let bs = balance::split(ostBalance, amount_staked);
      coin::from_balance(bs, ctx)


    }

    /// Put back ots tokens to the GameLiquidityPool without capability check.
    /// This function can be called by anyone.
    public fun place_in_pool(liquidity_pool: &mut GameLiquidityPool, coin: Coin<OTS>, ctx: &mut TxContext) {
        assert!(coin.value() > 0, EAmountMustBeGreaterThanZero);

        event::emit(PoolPlaced {
            sender: ctx.sender(),
            amount: coin.value()
        });

               liquidity_pool.otoken = liquidity_pool.otoken + coin.value();
                liquidity_pool.balance.join(coin.into_balance());
    }

    // === Private Functions ===

    /// Take OTS tokens from the GameLiquidityPool without capability check.
    /// This function is only accessible to the friend module.
   public fun ots_tokens_request(
        liquidity_pool: &mut GameLiquidityPool,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<OTS> {
        assert!(amount > 0, EAmountMustBeGreaterThanZero);
        assert!(amount <= liquidity_pool.balance.value(), EAmountTooHigh);
        assert!(liquidity_pool.owner == ctx.sender(), ENotOwner);

        event::emit(PoolWithdrawn {
            sender: ctx.sender(),
            amount
        });
        
        coin::take(&mut liquidity_pool.balance, amount, ctx)
    }
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) { init(ctx); }

  

}
