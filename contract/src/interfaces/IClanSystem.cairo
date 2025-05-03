use contract::interfaces::IClanNFT::IClanNFTDispatcher;
use contract::structs::clanstruct::Clan;
use starknet::ContractAddress;


#[starknet::interface]
pub trait IClanSystem<TContractState> {
    /// Create a new clan
    fn create_clan(ref self: TContractState, name: ByteArray, symbol: ByteArray, token_id: u256);

    /// Join an existing clan
    fn join_clan(ref self: TContractState, clan_id: felt252, token_id: u256);

    /// Leave current clan
    fn leave_clan(ref self: TContractState, token_id: u256);

    // Create a new NFT contract for the clan
    fn create_clan_nft(
        ref self: TContractState, name: ByteArray, symbol: ByteArray, clan_id: felt252,
    );

    /// Get clan information
    fn get_clan_info(self: @TContractState, clan_id: felt252) -> Clan;

    /// Get user's current clan ID
    fn get_user_clan(self: @TContractState, user: ContractAddress) -> felt252;

    /// Get the NFT contract of the clan with the given ID
    fn get_clan_nft(self: @TContractState, clan_id: felt252) -> ContractAddress;

    // Get the NFT dispatcher for the clan with the given ID
    fn get_nft_dispatcher(self: @TContractState, clan_id: felt252) -> IClanNFTDispatcher;
}
