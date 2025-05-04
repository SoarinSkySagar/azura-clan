use contract::structs::votestructs::{ProposalStatus, Vote};
use starknet::ContractAddress;

#[starknet::interface]
pub trait IQuadraticVoting<TContractState> {
    // / Create a new proposal
    fn create_proposal(
        ref self: TContractState, description: ByteArray, vote_expiration_time: u64,
    ) -> u64;

    // / Get proposal tally
    fn set_proposal_to_tally(ref self: TContractState, proposal_id: u64);

    // / Set proposal to ended
    fn set_proposal_to_ended(ref self: TContractState, proposal_id: u64);

    // / Get proposal status
    fn get_proposal_status(self: @TContractState, proposal_id: u64) -> ProposalStatus;

    // / Get proposal expiration time
    fn get_proposal_expiration_time(self: @TContractState, proposal_id: u64) -> u64;

    // / Count votes for a proposal
    fn count_votes(self: @TContractState, proposal_id: u64) -> (u256, u256);

    // Case vote for a proposal
    fn cast_vote(ref self: TContractState, proposal_id: u64, num_tokens: u256, vote: Vote);

    // Check if a user has voted
    fn user_has_voted(self: @TContractState, proposal_id: u64, user: ContractAddress) -> bool;

    // Sqrt function
    fn sqrt(self: @TContractState, x: u256) -> u256;

    // Transfer tokens
    fn _transfer(ref self: TContractState, recipient: ContractAddress, amount: u256);

    // Approve tokens
    fn _approve(ref self: TContractState, spender: ContractAddress, amount: u256);

    // Transfer tokens from one address to another
    fn _transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256,
    );

    // Get balance of an address
    fn _balance_of(self: @TContractState, account: ContractAddress) -> u256;

    // Get total supply of tokens
    fn _total_supply(self: @TContractState) -> u256;

    // Mint new tokens
    fn _mint(ref self: TContractState, recipient: ContractAddress, amount: u256);

    // Get allowance of tokens
    fn _allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
}
