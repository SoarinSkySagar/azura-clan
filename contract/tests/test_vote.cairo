use contract::interfaces::IQuadraticVoting::{IQuadraticVotingDispatcher, IQuadraticVotingDispatcherTrait, IQuadraticVotingSafeDispatcher};
use contract::contracts::vote::QuadraticVoting;
use contract::structs::votestructs::{ProposalStatus};

use openzeppelin::access::ownable::interface::{IOwnableDispatcher};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait, declare, spy_events, start_cheat_caller_address,
    stop_cheat_caller_address,
    start_cheat_block_timestamp, stop_cheat_block_timestamp
};
use starknet::ContractAddress;
use core::traits::TryInto;

// Test account -> Owner
fn OWNER() -> ContractAddress {
    'OWNER'.try_into().unwrap()
}

// Test account -> User
fn VOTER() -> ContractAddress {
    'VOTER'.try_into().unwrap()
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
    let (qv, _, _) = deploy_contract();

    let description = "Test Proposal";
    let voting_time: u64 = 24; // hours
    let mut spy = spy_events();

    start_cheat_caller_address(qv.contract_address, OWNER());


    start_cheat_caller_address(qv.contract_address, OWNER());

    let proposal_id = qv.create_proposal(description.clone(), voting_time);

    stop_cheat_caller_address(qv.contract_address);

    assert(proposal_id == 1, 'Proposal ID should be 1');

    let expected_event = QuadraticVoting::Event::ProposalCreated(
        QuadraticVoting::ProposalCreated {
            creator: OWNER(),
            proposal_id: 1,
            description: description,
            voting_time_in_hours: voting_time,
        }
    );

    spy.assert_emitted(@array![(qv.contract_address, expected_event)]);
}

#[test]
fn test_set_proposal_to_tally() {
    let (qv, _, _) = deploy_contract();

    let description = "Test Proposal";
    let voting_time: u64 = 24; // hours

    start_cheat_caller_address(qv.contract_address, OWNER());

    let proposal_id = qv.create_proposal(description.clone(), voting_time);

    start_cheat_block_timestamp(qv.contract_address, voting_time * 3600);

    qv.set_proposal_to_tally(proposal_id);

    stop_cheat_block_timestamp(qv.contract_address);

    stop_cheat_caller_address(qv.contract_address);
}

#[test]
fn test_set_proposal_to_ended() {
    let (qv, _, _) = deploy_contract();

    let description = "Test Proposal";
    let voting_time: u64 = 24; // hours

    start_cheat_caller_address(qv.contract_address, OWNER());

    let proposal_id = qv.create_proposal(description.clone(), voting_time);

    start_cheat_block_timestamp(qv.contract_address, voting_time * 3600);

    qv.set_proposal_to_tally(proposal_id);

    qv.set_proposal_to_ended(proposal_id);

    stop_cheat_block_timestamp(qv.contract_address);

    stop_cheat_caller_address(qv.contract_address);
}

#[test]
fn test_get_proposal_status() {
    let (qv, _, _) = deploy_contract();

    let description = "Test Proposal";
    let voting_time: u64 = 24; // hours

    start_cheat_caller_address(qv.contract_address, OWNER());

    let proposal_id = qv.create_proposal(description.clone(), voting_time);

    let proposal_status = qv.get_proposal_status(proposal_id);

    assert!(proposal_status == ProposalStatus::IN_PROGRESS, "Proposal status should be IN_PROGRESS");
}

#[test]
fn test_get_proposal_expiration_time() {
    let (qv, _, _) = deploy_contract();

    let description = "Test Proposal";
    let voting_time: u64 = 24; // hours

    start_cheat_caller_address(qv.contract_address, OWNER());

    let proposal_id = qv.create_proposal(description.clone(), voting_time);

    let proposal_expiration_time = qv.get_proposal_expiration_time(proposal_id);

    assert!(proposal_expiration_time > 0, "Proposal expiration time should be greater than 0");
}
