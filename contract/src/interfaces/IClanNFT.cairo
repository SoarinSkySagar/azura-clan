use starknet::ContractAddress;

#[starknet::interface]
pub trait IClanNFT<TContractState> {
    /// Mint a new NFT for the clan
    fn mint_nft(ref self: TContractState, token_id: u256, recipient: ContractAddress);
    /// Burn an NFT for the clan
    fn burn_nft(ref self: TContractState, token_id: u256);
}
