use contract::interfaces::IQuadraticVoting::{IQuadraticVotingDispatcher, IQuadraticVotingDispatcherTrait, IQuadraticVotingSafeDispatcher};
use contract::contracts::vote::QuadraticVoting;
use contract::structs::votestructs::{ProposalStatus, Vote};

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

    let description: ByteArray = "Test Proposal";
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

#[test]
fn test_cast_vote() {
    let (qv, _, _) = deploy_contract();

    let description: ByteArray = "Test Proposal";
    let num_tokens: u256 = 10;
    let voting_time: u64 = 24; // hours

    start_cheat_caller_address(qv.contract_address, OWNER());

    qv._mint(VOTER(), num_tokens);
    let voter_balance_before = qv._balance_of(VOTER());
    let contract_balance_before = qv._balance_of(qv.contract_address);

    let proposal_id = qv.create_proposal(description.clone(), voting_time);

    stop_cheat_caller_address(qv.contract_address);

    start_cheat_caller_address(qv.contract_address, VOTER());

    qv.cast_vote(proposal_id, num_tokens, Vote::YES);

    let voter_balance_after = qv._balance_of(VOTER());
    let contract_balance_after = qv._balance_of(qv.contract_address);

    assert!(qv.user_has_voted(proposal_id, VOTER()), "User should have voted on this proposal");
    assert!(voter_balance_after == voter_balance_before - num_tokens, "Voter balance should be 0 after voting");
    assert!(contract_balance_after == contract_balance_before + num_tokens, "Contract balance should be equal to the number of tokens");
    assert!(qv.get_proposal_status(proposal_id) == ProposalStatus::IN_PROGRESS, "Proposal status should be IN_PROGRESS");
    assert!(qv.get_proposal_expiration_time(proposal_id) > 0, "Proposal expiration time should be greater than 0");
    
    stop_cheat_caller_address(qv.contract_address);
}

#[test]
fn test_user_has_voted() {
    let (qv, _, _) = deploy_contract();

    let description: ByteArray = "Test Proposal";
    let voting_time: u64 = 24; // hours

    start_cheat_caller_address(qv.contract_address, OWNER());

    qv._mint(VOTER(), 10);

    let proposal_id = qv.create_proposal(description.clone(), voting_time);

    stop_cheat_caller_address(qv.contract_address);

    start_cheat_caller_address(qv.contract_address, VOTER());

    qv.cast_vote(proposal_id, 10, Vote::YES);

    assert!(qv.user_has_voted(proposal_id, VOTER()), "User should have voted on this proposal");

    stop_cheat_caller_address(qv.contract_address);
}

#[test]
fn test_sqrt() {
    let (qv, _, _) = deploy_contract();

    let x: u256 = 16;

    start_cheat_caller_address(qv.contract_address, OWNER());

    let result = qv.sqrt(x);

    assert!(result == 4, "Square root of 16 should be 4");

    stop_cheat_caller_address(qv.contract_address);
}

#[test]
fn test_count_vote() {
    let (qv, _, _) = deploy_contract();

    let description: ByteArray = "Test Proposal";
    let voting_time: u64 = 24; // hours

    start_cheat_caller_address(qv.contract_address, OWNER());

    qv._mint(OWNER(), 20);
    qv._mint(VOTER(), 10);

    let proposal_id = qv.create_proposal(description.clone(), voting_time);

    qv.cast_vote(proposal_id, 20, Vote::NO);

    stop_cheat_caller_address(qv.contract_address);

    start_cheat_caller_address(qv.contract_address, VOTER());

    qv.cast_vote(proposal_id, 10, Vote::YES);

    let (yes_votes, no_votes) = qv.count_votes(proposal_id);

    println!("Yes votes: {}", yes_votes);
    println!("No votes: {}", no_votes);

    assert!(yes_votes == 3, "Yes votes should be 3 => sqrt(10)");
    assert!(no_votes == 4, "No votes should be 4 => sqrt(20)");

    stop_cheat_caller_address(qv.contract_address);
}