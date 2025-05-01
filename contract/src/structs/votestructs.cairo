use starknet::ContractAddress;
use starknet::storage::{Map, Vec};

#[derive(Copy, PartialEq, Drop, Serde, starknet::Store)]
pub enum Vote {
    #[default]
    YES,
    NO,
}

#[derive(Drop, Serde, PartialEq, starknet::Store)]
pub enum ProposalStatus {
    #[default]
    IN_PROGRESS,
    TALLY,
    ENDED,
}

#[starknet::storage_node]
pub struct Proposal {
    pub creator: ContractAddress,
    pub status: ProposalStatus,
    pub yes_votes: u256,
    pub no_votes: u256,
    pub description: ByteArray,
    pub voters: Vec<ContractAddress>,
    pub expiration_time: u64,
    pub voter_info: Map::<ContractAddress, Voter>,
}

#[derive(Drop, Serde, starknet::Store)]
pub struct Voter {
    pub has_voted: bool,
    pub vote: Vote,
    pub weight: u256,
}