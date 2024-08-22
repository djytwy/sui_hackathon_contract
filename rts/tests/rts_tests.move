#[test_only]
module rts::rts_tests {
    use rts::rts::{Self, RTS, RtsTotalSupply } ;
    use sui::{
        test_utils::assert_eq, 
        test_scenario as ts,
        coin::{TreasuryCap, DenyCap}
    };
    const Rts_DECIMALS: u64 = 1_000_000_000;
    const EXPECTED_TOTAL_SUPPLY: u64 = 1_000_000_000 * Rts_DECIMALS;
    #[test]
    #[expected_failure]
    fun test_treasury_cap_is_burnt() {
        let mut scenario = ts::begin(@rtstester);
        {
            rts::init_for_testing(scenario.ctx());
        };
        ts::next_tx(&mut scenario, @rtstester);
        {
            let treasury = scenario.take_from_sender<TreasuryCap<RTS>>();
            scenario.return_to_sender(treasury);
        };
        scenario.end();
    }
    #[test]
    fun test_deny_cap_existed() {
        let mut scenario = ts::begin(@rtstester);
        {
            rts::init_for_testing(scenario.ctx());
        };
        ts::next_tx(&mut scenario, @rtstester);
        {
            let deny = scenario.take_from_sender<DenyCap<RTS>>();
            scenario.return_to_sender(deny);
        };
        scenario.end();
    }

    #[test]
    fun test_immutable_supply() {
        let mut scenario = ts::begin(@rtstester);
        {
            rts::init_for_testing(ts::ctx(&mut scenario));
        };
        ts::next_tx(&mut scenario, @rtstester);
        {
            assert!(!scenario.has_most_recent_for_sender<RtsTotalSupply>(), 0);
        };
        ts::next_tx(&mut scenario, @rtstester);
        {
            let supply_data = scenario.take_immutable<RtsTotalSupply>();
            let total_supply = supply_data.get_total_supply();
            assert_eq(total_supply, EXPECTED_TOTAL_SUPPLY);
            ts::return_immutable(supply_data);
        };
        scenario.end();
    }

}
