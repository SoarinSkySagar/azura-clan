use contract::structs::clanstruct::Clan;
use starknet::ContractAddress;


#[starknet::interface]
pub trait IClanSystem<TContractState> {
    /// Create a new clan
    fn create_clan(ref self: TContractState, name: ByteArray, symbol: ByteArray);

    /// Join an existing clan
    fn join_clan(ref self: TContractState, clan_id: felt252);

    /// Leave current clan
    fn leave_clan(ref self: TContractState);

    /// Get clan information
    fn get_clan_info(self: @TContractState, clan_id: felt252) -> Clan;

    /// Get user's current clan ID
    fn get_user_clan(self: @TContractState, user: ContractAddress) -> felt252;
}
