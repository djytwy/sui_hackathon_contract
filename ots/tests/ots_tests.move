#[test_only]
module ots::ots_tests {
    use ots::ots::{Self, OTS, OTSTotalSupply } ;
    use sui::{
        test_utils::assert_eq, 
        test_scenario as ts,
        coin::{TreasuryCap, DenyCap}
    };
    const OTS_DECIMALS: u64 = 1_000_000_000;
    const EXPECTED_TOTAL_SUPPLY: u64 = 1_000_000_000 * OTS_DECIMALS;
    #[test]
    #[expected_failure]
    fun test_treasury_cap_is_burnt() {
        let mut scenario = ts::begin(@otstester);
        {
            ots::init_for_testing(scenario.ctx());
        };
        ts::next_tx(&mut scenario, @otstester);
        {
            let treasury = scenario.take_from_sender<TreasuryCap<OTS>>();
            scenario.return_to_sender(treasury);
        };
        scenario.end();
    }
    #[test]
    fun test_deny_cap_existed() {
        let mut scenario = ts::begin(@otstester);
        {
            ots::init_for_testing(scenario.ctx());
        };
        ts::next_tx(&mut scenario, @otstester);
        {
            let deny = scenario.take_from_sender<DenyCap<OTS>>();
            scenario.return_to_sender(deny);
        };
        scenario.end();
    }

    #[test]
    fun test_immutable_supply() {
        let mut scenario = ts::begin(@otstester);
        {
            ots::init_for_testing(ts::ctx(&mut scenario));
        };
        ts::next_tx(&mut scenario, @otstester);
        {
            assert!(!scenario.has_most_recent_for_sender<OTSTotalSupply>(), 0);
        };
        ts::next_tx(&mut scenario, @otstester);
        {
            let supply_data = scenario.take_immutable<OTSTotalSupply>();
            let total_supply = supply_data.get_total_supply();
            assert_eq(total_supply, EXPECTED_TOTAL_SUPPLY);
            ts::return_immutable(supply_data);
        };
        scenario.end();
    }

}
