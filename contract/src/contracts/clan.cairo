#[starknet::contract]
pub mod ClanSystem {
    use contract::interfaces::IClanSystem::IClanSystem;
    use contract::structs::clanstruct::Clan;
    use core::array::ArrayTrait;
    use starknet::ContractAddress;
    use starknet::storage::{
        Map, MutableVecTrait, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
        Vec,
    };

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
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        ClanCreated: ClanCreated,
        MemberJoined: MemberJoined,
        MemberLeft: MemberLeft,
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

    #[abi(embed_v0)]
    impl ClanSystemImpl of IClanSystem<ContractState> {
        fn create_clan(ref self: ContractState, name: ByteArray, symbol: ByteArray) {
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

            // Emit event
            self
                .emit(
                    ClanCreated {
                        clan_id, name: name.clone(), symbol: symbol.clone(), creator: caller,
                    },
                );
        }

        fn join_clan(ref self: ContractState, clan_id: felt252) {
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

            // Emit event
            self.emit(Event::MemberJoined(MemberJoined { clan_id, member: caller }));
        }


        fn leave_clan(ref self: ContractState) {
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
            self.user_to_clan.entry(caller).write(0);

            // Emit event
            self.emit(MemberLeft { clan_id, member: caller });
        }

        fn get_clan_info(self: @ContractState, clan_id: felt252) -> Clan {
            self.clans.entry(clan_id).read()
        }

        fn get_user_clan(self: @ContractState, user: ContractAddress) -> felt252 {
            self.user_to_clan.entry(user).read()
        }
    }
}
