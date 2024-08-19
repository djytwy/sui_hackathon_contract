#[test_only]
module pts::pts_tests {
    use pts::pts::{Self, PTS, AllowCap, MintCap } ;
    use sui::{
        test_utils::assert_eq, 
        test_scenario as ts,
        coin::{Self,Coin, TreasuryCap, DenyCap},
        balance,

    };
    const PTS_DECIMALS: u64 = 1_000_000_000;
    const EXPECTED_TOTAL_SUPPLY: u64 = 1_000_000_000 * PTS_DECIMALS;
    #[test]
    #[expected_failure]
    fun test_treasury_cap_is_burnt() {
        let mut scenario = ts::begin(@ptstester);
        {
            pts::init_for_testing(scenario.ctx());
        };
        ts::next_tx(&mut scenario, @ptstester);
        {
            let treasury = scenario.take_shared<AllowCap<PTS>>();
            scenario.return_to_sender(treasury);
        };
        scenario.end();
    }


    #[test]
    fun test_add_allow_cap_supply() {
        let mut scenario = ts::begin(@ptstester);
        {
            pts::init_for_testing(ts::ctx(&mut scenario));
        };
        ts::next_tx(&mut scenario, @ptstester);
        {
            let mut allow = scenario.take_shared<AllowCap<PTS>>();

            pts::add_allow_cap(&mut allow, @operator, ts::ctx(&mut scenario));
            assert!(pts::is_allow(&allow, @operator));
           ts::return_shared(allow);

        };
        ts::next_tx(&mut scenario, @operator);
        {
              let  allow = scenario.take_shared<AllowCap<PTS>>();
                        let mut mintCap = scenario.take_shared<MintCap<PTS>>();
             pts::mint(&allow,&mut mintCap,@ptstester, 1000 * PTS_DECIMALS, ts::ctx(&mut scenario));
             let _balance =pts::get_transfer_cap(&mintCap);
             assert_eq(_balance, 1000 * PTS_DECIMALS);
             ts::return_shared(mintCap);
                ts::return_shared(allow);

        };
             ts::next_tx(&mut scenario, @ptstester);
        {              let pstCoin =  scenario.take_from_sender<Coin<PTS>>();
                                let mut mintCap = scenario.take_shared<MintCap<PTS>>();
              assert!(coin::value(&pstCoin)==1000 * PTS_DECIMALS);
             pts::burn(&mut mintCap,pstCoin);
             ts::return_shared(mintCap);
        };


        scenario.end();
    }

}
