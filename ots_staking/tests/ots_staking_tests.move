#[test_only]
module ots_staking::ots_staking_tests {
    use ots_staking::pts::{Self, PTS,AllowCap,MintCap } ; //  mapping coin
    use ots::ots::{Self, OTS, OTSTotalSupply } ;//stake coin
    use rts::rts::{Self, RTS, RtsTotalSupply } ; // extra reward coin 
    use ots_staking::staking::{Self, StakingReceipt, GameLiquidityPool ,AutherizeCap, DropRewardPool, RewardCap } ;
    use sui::{
        test_utils::{assert_eq, print}, 
        test_scenario as ts,
        coin::{Self, Coin},
        transfer::{Self, transfer,public_transfer, share_object},
    };
    const PTS_DECIMALS: u64 = 1_000_000_000;
    const EXPECTED_TOTAL_SUPPLY: u64 = 1_000_000_000 * PTS_DECIMALS;
    #[test]
    fun test_treasury_cap_is_burnt() {
        let mut scenario = ts::begin(@protool);
        {
            //初始化质押合约
            staking::init_for_testing(scenario.ctx());
        };
        ts::next_tx(&mut scenario, @protool);
        {
            //创建rts(任意币奖励池)奖励池
            let autherizeCap = scenario.take_from_sender<AutherizeCap>();
            staking::create_reward_pool<PTS>(&autherizeCap,ts::ctx(&mut scenario));
            scenario.return_to_sender(autherizeCap);
        };
        ts::next_tx(&mut scenario, @otstester);
        {
            //初始化ots（usdt) 合约
           ots::init_for_testing(scenario.ctx());
        
        };
        ts::next_tx(&mut scenario, @otstester);
        {
            //验证ots 的币总量
           let ots_coin =scenario.take_from_sender<Coin<OTS>>();
           assert_eq(coin::value(&ots_coin), EXPECTED_TOTAL_SUPPLY);
              scenario.return_to_sender(ots_coin);
        };

        ts::next_tx(&mut scenario, @otstester);
        {
            //交易ots 币给到质押者 用于测试
          let mut ots_coin =scenario.take_from_sender<Coin<OTS>>();
                   //交易 10000 ots给到ptstester
                 let trade_coin= coin::split(&mut ots_coin, 10000 * PTS_DECIMALS, ts::ctx(&mut scenario));
                    public_transfer(trade_coin, @ptstester);
        // 交易 10000给到@chad
        let trade_coin= coin::split(&mut ots_coin, 10000 * PTS_DECIMALS, ts::ctx(&mut scenario));
        public_transfer(trade_coin, @chad);
                  pts::init_for_testing(scenario.ctx());
                    scenario.return_to_sender(ots_coin);
        };

        ts::next_tx(&mut scenario, @ptstester);
        {
            //切换到质押者 核实金额
                   let mut ots_coin =scenario.take_from_sender<Coin<OTS>>();
                     assert_eq(coin::value(&ots_coin), 10000 * PTS_DECIMALS);
                    scenario.return_to_sender(ots_coin);
        };

        ts::next_tx(&mut scenario, @ptstester);
        {
            //创建质押者质@ptstester 押凭证 stake_receipt
           let staking_receipt = staking::create_stake_receive(ts::ctx(&mut scenario));
              assert_eq(staking::getStakeReceiptAmount(&staking_receipt), 0);
            //    share_object(staking_receipt);
               public_transfer(staking_receipt, @ptstester);
           
        };
        ts::next_tx(&mut scenario, @chad);
        {
            //创建质押者质@chad押凭证 stake_receipt
        let staking_receipt = staking::create_stake_receive(ts::ctx(&mut scenario));
        assert_eq(staking::getStakeReceiptAmount(&staking_receipt), 0);
        //    share_object(staking_receipt);
        public_transfer(staking_receipt, @chad);

        };
        ts::next_tx(&mut scenario, @ptstester);
        {
            //质押者质@chad押ots币
                 let  stake_receipt = scenario.take_from_sender<StakingReceipt>();
                assert_eq(staking::getStakeReceiptAmount(&stake_receipt), 0);
                  scenario.return_to_sender(stake_receipt);
        };

        ts::next_tx(&mut scenario, @ptstester);
        {
            //质押者质@ptstester押ots币到合约
           
           let mut gameLiquidityPool = scenario.take_shared<GameLiquidityPool>();
            let mut stake_receipt = scenario.take_from_sender<StakingReceipt>();
            let mut ots_coin = scenario.take_from_sender<Coin<OTS>>();
            assert_eq(coin::value(&ots_coin), 10000 * PTS_DECIMALS);
             let  allow = scenario.take_shared<AllowCap<PTS>>();
                        let mut mintCap = scenario.take_shared<MintCap<PTS>>();
                       staking::stake(ots_coin, &mut gameLiquidityPool, &allow, &mut mintCap, &mut stake_receipt, ts::ctx(&mut scenario));
            ts::return_shared(mintCap); 
            ts::return_shared(allow);
            ts::return_shared(gameLiquidityPool);
        scenario.return_to_sender(stake_receipt);

        };

            ts::next_tx(&mut scenario, @chad);
            {
        //质押者质@chad押ots币到合约
            let mut gameLiquidityPool = scenario.take_shared<GameLiquidityPool>();
            let mut stake_receipt = scenario.take_from_sender<StakingReceipt>();
            let  ots_coin = scenario.take_from_sender<Coin<OTS>>();
            assert_eq(coin::value(&ots_coin), 10000 * PTS_DECIMALS);
            let  allow = scenario.take_shared<AllowCap<PTS>>();
            let mut mintCap = scenario.take_shared<MintCap<PTS>>();
            staking::stake(ots_coin, &mut gameLiquidityPool, &allow, &mut mintCap, &mut stake_receipt, ts::ctx(&mut scenario));
            ts::return_shared(mintCap);
            ts::return_shared(allow);
            ts::return_shared(gameLiquidityPool);
            scenario.return_to_sender(stake_receipt);

            };

        ts::next_tx(&mut scenario, @ptstester);
        {
            //验证质押者质@ptstester质押凭证金额
           let  stake_receipt = scenario.take_from_sender<StakingReceipt>();
            assert_eq(staking::getStakeReceiptAmount(&stake_receipt), 10000 * PTS_DECIMALS);
            scenario.return_to_sender(stake_receipt);
            let pts_coin  = scenario.take_from_sender<Coin<PTS>>();
            assert_eq(coin::value(&pts_coin), 10000 * PTS_DECIMALS);
            scenario.return_to_sender(pts_coin);
            // let ots_coin = scenario.take_from_sender<Coin<OTS>>();
            // assert_eq(coin::value(&ots_coin), 0);
            // scenario.return_to_sender(ots_coin);
        };

       ts::next_tx(&mut scenario, @ptstester);
        {
            //验证质押池的金额
            let  gameLiquidityPool = scenario.take_shared<GameLiquidityPool>();
        assert_eq(staking::getGameLiquidityPoolBalance(&gameLiquidityPool), 20000 * PTS_DECIMALS);
        ts::return_shared(gameLiquidityPool);
        };

        ts::next_tx(&mut scenario, @otstester);
        {
            // 发放ctoken 奖励
                let  allow = scenario.take_shared<AllowCap<PTS>>();
                        let mut mintCap = scenario.take_shared<MintCap<PTS>>();
                        staking::reward_pool_token(&mut mintCap, 200 * PTS_DECIMALS, ts::ctx(&mut scenario));
                         ts::return_shared(mintCap);
            ts::return_shared(allow);
            // scenario.return_to_sender(stake_receipt);

        };

        ts::next_tx(&mut scenario, @otstester);
        {
            //验证ctoken奖励池金额
        let  drop_reward_pool = scenario.take_shared<DropRewardPool>();
          assert_eq(staking::getDropRewardPoolBalance(&drop_reward_pool), 200 * PTS_DECIMALS);
            ts::return_shared(drop_reward_pool);
        };
          ts::next_tx(&mut scenario, @ptstester);
            {
                //质押者领取ctoken奖励
            let mut drop_reward_pool = scenario.take_shared<DropRewardPool>();
            let mut gameLiquidityPool = scenario.take_shared<GameLiquidityPool>();
            let mut stake_receipt = scenario.take_from_sender<StakingReceipt>();
            let r_coin =staking::claim_pool_token(&mut gameLiquidityPool,&mut drop_reward_pool,&mut stake_receipt, ts::ctx(&mut scenario));
            // assert_eq(coin::value(&r_coin), 100 * PTS_DECIMALS);

         assert_eq(staking::getGameLiquidityPoolPool(&gameLiquidityPool), 20100 * PTS_DECIMALS);
            // assert_eq(staking::computer(&mut gameLiquidityPool,&mut drop_reward_pool,&mut stake_receipt),100u64);
            let mut o_coin = scenario.take_from_sender<Coin<PTS>>();

             coin::join(&mut o_coin, r_coin);

            ts::return_shared(drop_reward_pool);
            ts::return_shared(gameLiquidityPool);
            scenario.return_to_sender(stake_receipt);
            scenario.return_to_sender(o_coin);

            };

         ts::next_tx(&mut scenario, @ptstester);
        {
            //验证流动性池的ctoken
            let coin_pts = scenario.take_from_sender<Coin<PTS>>();
             let mut gameLiquidityPool = scenario.take_shared<GameLiquidityPool>();
            //  assert_eq(staking::getGameLiquidityPoolPool(&gameLiquidityPool), 20000 * PTS_DECIMALS);
            assert_eq(coin::value(&coin_pts), 10100 * PTS_DECIMALS);
            // assert_eq(coin::value(&coin_pts), 10100 * PTS_DECIMALS);
            // ptintln!("coin_pts:{}",coin::value(&coin_pts));
               scenario.return_to_sender(coin_pts);
                ts::return_shared(gameLiquidityPool);

        };

            ts::next_tx(&mut scenario, @ptstester);
            {
                //解质押
                    let  stake_receipt = scenario.take_from_sender<StakingReceipt>();
                let mut gameLiquidityPool = scenario.take_shared<GameLiquidityPool>();
                let ots= staking::unstake(stake_receipt, &mut gameLiquidityPool, ts::ctx(&mut scenario));
                public_transfer(ots, @ptstester);
                ts::return_shared(gameLiquidityPool);
            };

            ts::next_tx(&mut scenario, @otstester);
            {
                //初始化rts币，并且创建rts奖励池
                 rts::init_for_testing(scenario.ctx());
                 let autherizeCap = scenario.take_from_sender<AutherizeCap>();
                 staking::create_reward_pool<RTS>(&autherizeCap, ts::ctx(&mut scenario));
                    scenario.return_to_sender(autherizeCap);
            };

             ts::next_tx(&mut scenario, @otstester);
            {
                //交易rts币给其他人，用于其他人添加奖励
                let mut rts_coin = scenario.take_from_sender<Coin<RTS>>();
               let split_coin=  coin::split(&mut rts_coin, 10000 * PTS_DECIMALS, ts::ctx(&mut scenario));
              public_transfer(split_coin, @ptstester);
                scenario.return_to_sender(rts_coin);

            };

            ts::next_tx(&mut scenario, @ptstester);
            {
                //添加RTS奖励
                let mut rts_coin = scenario.take_from_sender<Coin<RTS>>();
                let mut reward_cap = scenario.take_shared<RewardCap<RTS>>();
               let split_coin=  coin::split(&mut rts_coin, 100 * PTS_DECIMALS , ts::ctx(&mut scenario));
                 staking::add_reward<RTS>(&mut reward_cap,split_coin);
                scenario.return_to_sender(rts_coin);
                ts::return_shared(reward_cap);

            };
             ts::next_tx(&mut scenario, @otstester);
            { 
                //主动发放奖励
                let mut reward_cap = scenario.take_shared<RewardCap<RTS>>();
                staking::drop_reword(&mut reward_cap, 10 *PTS_DECIMALS ,  @ptstester, ts::ctx(&mut scenario));
                ts::return_shared(reward_cap);
            };

        scenario.end();
    }

}