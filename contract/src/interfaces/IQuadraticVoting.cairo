use starknet::ContractAddress;

#[starknet::interface]
trait IQVVoting<TContractState> {
    // / Create a new proposal
    fn create_proposal(ref self: TContractState, description: felt252, vote_expiration_time: u64) -> u64;

    // / Get proposal tally
    fn set_proposal_to_tally(ref self: TContractState, proposal_id: u64);

    // / Set proposal to ended
    fn set_proposal_to_ended(ref self: TContractState, proposal_id: u64);

    // / Get proposal status
    fn get_proposal_status(self: @TContractState, proposal_id: u64) -> ProposalStatus;

    // / Get proposal expiration time
    fn get_proposal_expiration_time(self: @TContractState, proposal_id: u64) -> u64;

    // / Count votes for a proposal
    fn count_votes(self: @TContractState, proposal_id: u256) -> (u256, u256);

    // Case vote for a proposal
    fn cast_vote(ref self: TContractState, proposal_id: u64, num_tokens: u256, vote: bool);

    // Check if a user has voted
    fn user_has_voted(self: @TContractState, proposal_id: u64, user: ContractAddress) -> bool;

    // Sqrt function
    fn sqrt(self: @TContractState, x: u256) -> u256;

    // Mint tokens
    fn mint(ref self: TContractState, account: ContractAddress, amount: u256);

    // Balance of an account
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
}
