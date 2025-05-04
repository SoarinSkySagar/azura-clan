#[starknet::contract]
pub mod ClanNFT {
    use contract::interfaces::IClanNFT::IClanNFT;
    use core::array::ArrayTrait;
    use openzeppelin::access::accesscontrol::{AccessControlComponent, DEFAULT_ADMIN_ROLE};
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::{ERC721Component, ERC721HooksEmptyImpl};
    use starknet::ContractAddress;
    use starknet::storage::{
        Map, MutableVecTrait, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
        Vec,
    };

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);

    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    #[abi(embed_v0)]
    impl AccessControlImpl =
        AccessControlComponent::AccessControlImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;

    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        // ERC721 storage
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        // SRC5 storage
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        // AccessControl storage
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        // Clan contract address
        clan_contract: ContractAddress,
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, name: ByteArray, symbol: ByteArray, clan_contract: ContractAddress,
    ) {
        let base_uri: ByteArray = "ipfs://";

        self.accesscontrol.initializer();
        self.erc721.initializer(name, symbol, base_uri);
        self.accesscontrol._grant_role(DEFAULT_ADMIN_ROLE, clan_contract);
        self.clan_contract.write(clan_contract);
    }

    #[abi(embed_v0)]
    impl ClanNFTImpl of IClanNFT<ContractState> {
        /// Create a new clan
        fn mint_nft(ref self: ContractState, token_id: u256, recipient: ContractAddress) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            let data: Span<felt252> = array![0].span();
            self.erc721.safe_mint(recipient, token_id, data);
        }

        /// Burn an NFT for the clan
        fn burn_nft(ref self: ContractState, token_id: u256) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            self.erc721.burn(token_id);
        }
    }
}
