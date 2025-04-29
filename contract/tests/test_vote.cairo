use contract::contracts::vote::{QuadraticVoting, IQuadraticVotingDispatcher, IQuadraticVotingDispatcherTrait, IQuadraticVotingSafeDispatcher, IQuadraticVotingSafeDispatcherTrait};

use openzeppelin::access::ownable::interface::{IOwnableDispatcher, IOwnableDispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait, declare, spy_events, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use starknet::ContractAddress;
use core::traits::TryInto;

// Test account -> Owner
fn OWNER() -> ContractAddress {
    'OWNER'.try_into().unwrap()
}

// Test account -> User
fn USER() -> ContractAddress {
    'USER'.try_into().unwrap()
}

// Helper function to deploy the contract
fn deploy_contract() -> (IQuadraticVotingDispatcher, IOwnableDispatcher, IQuadraticVotingSafeDispatcher) {
    let contract_class = declare("QuadraticVoting").unwrap().contract_class();

    let mut constructor_calldata = array![];

    let name: ByteArray = "QuadraticVoting";
    let symbol: ByteArray = "QV";

    OWNER().serialize(ref constructor_calldata);
    name.serialize(ref constructor_calldata);
    symbol.serialize(ref constructor_calldata);

    let (contract_address, _) = contract_class.deploy(
        @constructor_calldata
    ).unwrap();

    let qv = IQuadraticVotingDispatcher { contract_address };
    let ownable = IOwnableDispatcher { contract_address };
    let safe_dispatcher = IQuadraticVotingSafeDispatcher { contract_address };

    (qv, ownable, safe_dispatcher)
}

#[test]
fn test_create_proposal() {
    // 1. Deploy the contract
    let owner: ContractAddress = 123.try_into().unwrap();
    let (dispatcher, contract_address) = deploy_contract(
        owner,
        create_byte_array(array!['MyToken'].span()),
        create_byte_array(array!['MTK'].span())
    );

    // 2. Prepare test data
    let description = create_byte_array(array!['Test Proposal'].span());
    let voting_time: u64 = 24; // hours

    // 3. Call the function
    let mut spy = spy_events();
    let proposal_id = dispatcher.create_proposal(description.clone(), voting_time);

    // 4. Assertions
    assert(proposal_id == 1, 'Proposal ID should be 1');

    // Verify event emission
    let expected_event = Event::ProposalCreated(
        ProposalCreated {
            creator: get_caller_address(),
            proposal_id: 1,
            description: description,
            voting_time_in_hours: voting_time,
        }
    );
    spy.assert_emitted(@array![(contract_address, expected_event)]);
}