#[starknet::contract]
pub mod ClanSystem {
    use contract::interfaces::IClanNFT::{IClanNFTDispatcher, IClanNFTDispatcherTrait};
    use contract::interfaces::IClanSystem::IClanSystem;
    use contract::structs::clanstruct::Clan;
    use core::array::ArrayTrait;
    use starknet::storage::{
        Map, MutableVecTrait, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
        Vec,
    };
    use starknet::syscalls::deploy_syscall;
    use starknet::{ClassHash, ContractAddress, get_contract_address};

    #[storage]
    struct Storage {
        // Mapping from clan ID to Clan struct
        clans: Map<felt252, Clan>,
        // Mapping from user address to clan ID (0 means no clan)
        user_to_clan: Map<ContractAddress, felt252>,
        // Total number of clans created
        clan_count: felt252,
        // Mapping from clan ID to Vec of member addresses
        clan_members: Map<felt252, Vec<ContractAddress>>,
        // Mapping from clan ID to NFT contract address
        clan_nft_contracts: Map<felt252, ContractAddress>,
        // Class hash for the NFT contract
        nft_class_hash: felt252,
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        ClanCreated: ClanCreated,
        MemberJoined: MemberJoined,
        MemberLeft: MemberLeft,
        ClanNFTCreated: ClanNFTCreated,
    }

    #[derive(Drop, starknet::Event)]
    struct ClanCreated {
        pub clan_id: felt252,
        pub name: ByteArray,
        pub symbol: ByteArray,
        pub creator: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct MemberJoined {
        pub clan_id: felt252,
        pub member: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct MemberLeft {
        pub clan_id: felt252,
        pub member: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct ClanNFTCreated {
        pub clan_id: felt252,
        pub nft_contract: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, class_hash: felt252) {
        // Initialize class hash for the NFT contract
        self.nft_class_hash.write(class_hash);
    }

    #[abi(embed_v0)]
    impl ClanSystemImpl of IClanSystem<ContractState> {
        fn create_clan(
            ref self: ContractState, name: ByteArray, symbol: ByteArray, token_id: u256,
        ) {
            // Validate symbol is exactly 3 characters
            assert(symbol.len() == 3, 'Symbol must be 3 characters');
            let caller = starknet::get_caller_address();

            // Check if caller is already in a clan
            let current_clan = self.user_to_clan.entry(caller).read();
            assert(current_clan == 0, 'Already in a clan');

            // Get new clan ID
            let clan_id = self.clan_count.read() + 1;

            // Create new clan
            let new_clan = Clan { name: name.clone(), symbol: symbol.clone() };

            // Store clan and update user mapping
            self.clans.entry(clan_id).write(new_clan);
            self.user_to_clan.entry(caller).write(clan_id);
            self.clan_count.write(clan_id);

            // Initialize clan members vec and add creator
            self.clan_members.entry(clan_id).push(caller);

            // Create NFT contract for the clan
            self.create_clan_nft(name.clone(), symbol.clone(), clan_id);
            // Mint NFT for the clan
            let nft_dispatcher = self.get_nft_dispatcher(clan_id);
            nft_dispatcher.mint_nft(token_id, caller);

            // Emit event
            self
                .emit(
                    ClanCreated {
                        clan_id, name: name.clone(), symbol: symbol.clone(), creator: caller,
                    },
                );
        }

        fn join_clan(ref self: ContractState, clan_id: felt252, token_id: u256) {
            let caller = starknet::get_caller_address();

            // Check if caller is already in a clan
            let current_clan = self.user_to_clan.entry(caller).read();
            assert(current_clan == 0, 'Already in a clan');

            // Get clan members vec
            let clan_members = self.clan_members.entry(clan_id);

            // Copy elements from storage Vec to memory Array
            let mut clan_members_array = array![];
            let mut i: u64 = 0;
            while i != clan_members.len() {
                clan_members_array.append(clan_members.at(i).read());
                i += 1;
            }

            // Check clan capacity
            assert(clan_members_array.len() < 16, 'Clan is at max capacity');

            // Add user to clan members
            clan_members.push(caller);
            self.user_to_clan.entry(caller).write(clan_id);

            // Mint NFT for the clan
            let nft_dispatcher = self.get_nft_dispatcher(clan_id);
            nft_dispatcher.mint_nft(token_id, caller);

            // Emit event
            self.emit(Event::MemberJoined(MemberJoined { clan_id, member: caller }));
        }


        fn leave_clan(ref self: ContractState, token_id: u256) {
            let caller = starknet::get_caller_address();

            // Get user's current clan
            let clan_id = self.user_to_clan.entry(caller).read();
            assert(clan_id != 0, 'Not in any clan');

            // Get clan members vec
            let clan_members = self.clan_members.entry(clan_id);
            let mut clan_members_array = array![];
            let mut i: u64 = 0;
            while i != clan_members.len() {
                clan_members_array.append(clan_members.at(i).read());
                i += 1;
            }

            // Find and remove user from members array
            let mut new_members = array![];
            let members_len = clan_members_array.len();

            let mut j: u32 = 0;
            while j != members_len {
                let member = clan_members_array.at(j);
                if *member != caller {
                    new_members.append(*member);
                }
                i += 1;
            }

            let mut j: u32 = 0;
            while j != new_members.len() {
                clan_members.at(i).write(*new_members.at(j));
                j += 1;
            }

            // Burn the NFT for the clan when leaving the clan
            let nft_dispatcher = self.get_nft_dispatcher(clan_id);
            nft_dispatcher.burn_nft(token_id);

            // Emit event
            self.emit(MemberLeft { clan_id, member: caller });
        }

        fn create_clan_nft(
            ref self: ContractState, name: ByteArray, symbol: ByteArray, clan_id: felt252,
        ) {
            let clan_address = get_contract_address();
            let nft_class_hash: ClassHash = self.nft_class_hash.read().try_into().unwrap();

            let mut constructor_calldata = array![];

            (name, symbol, clan_address).serialize(ref constructor_calldata);

            let (contract_address, _) = deploy_syscall(
                nft_class_hash, 4242, constructor_calldata.span(), false,
            )
                .unwrap();

            self.clan_nft_contracts.entry(clan_id).write(contract_address);

            self.emit(ClanNFTCreated { clan_id, nft_contract: contract_address });
        }

        fn get_nft_dispatcher(self: @ContractState, clan_id: felt252) -> IClanNFTDispatcher {
            IClanNFTDispatcher { contract_address: self.get_clan_nft(clan_id) }
        }

        fn get_clan_info(self: @ContractState, clan_id: felt252) -> Clan {
            self.clans.entry(clan_id).read()
        }

        fn get_user_clan(self: @ContractState, user: ContractAddress) -> felt252 {
            self.user_to_clan.entry(user).read()
        }

        fn get_clan_nft(self: @ContractState, clan_id: felt252) -> ContractAddress {
            self.clan_nft_contracts.entry(clan_id).read()
        }
    }
}
