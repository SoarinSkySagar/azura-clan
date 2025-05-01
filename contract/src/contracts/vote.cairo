#[starknet::contract]
pub mod QuadraticVoting {
    use contract::structs::votestructs::{Proposal, ProposalStatus, Voter, Vote};
    use contract::interfaces::IQuadraticVoting::IQuadraticVoting;

    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess, VecTrait, MutableVecTrait
    };
    use core::num::traits::Sqrt;

    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableTwoStepImpl = OwnableComponent::OwnableTwoStepImpl<ContractState>;
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        proposals: Map::<u64, Proposal>,
        proposal_count: u64,
        total_supply: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        VoteCasted: VoteCasted,
        ProposalCreated: ProposalCreated,
    }

    #[derive(Drop, starknet::Event)]
    pub struct VoteCasted {
        pub voter: ContractAddress,
        pub proposal_id: u64,
        pub weight: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ProposalCreated {
        pub creator: ContractAddress,
        pub proposal_id: u64,
        pub description: ByteArray,
        pub voting_time_in_hours: u64,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, owner: ContractAddress, name: ByteArray, symbol: ByteArray
    ) {
        self.erc20.initializer(name, symbol);
        self.ownable.initializer(owner);
        self.proposal_count.write(0);
        self.total_supply.write(0);
    }

    #[abi(embed_v0)]
    impl QuadraticVotingImpl of IQuadraticVoting<ContractState> {
        fn create_proposal(
            ref self: ContractState, description: ByteArray, vote_expiration_time: u64
        ) -> u64 {
            assert!(vote_expiration_time > 0, "The voting period cannot be 0");
            assert!(description.len() > 0, "The description cannot be empty");

            self.ownable.assert_only_owner();

            let proposal_count = self.proposal_count.read() + 1;
            self.proposal_count.write(proposal_count);

            let creator = get_caller_address();

            let proposal = self.proposals.entry(proposal_count);

            proposal.creator.write(creator);
            proposal.status.write(ProposalStatus::IN_PROGRESS);
            proposal.yes_votes.write(0);
            proposal.no_votes.write(0);
            proposal.description.write(description.clone());
            proposal.expiration_time.write(
                starknet::get_block_timestamp() + 60 * vote_expiration_time
            );

            self.emit(Event::ProposalCreated(
                ProposalCreated {
                    creator: creator,
                    proposal_id: proposal_count,
                    description: description,
                    voting_time_in_hours: vote_expiration_time,
                }
            ));

            proposal_count
        }

        fn set_proposal_to_tally(ref self: ContractState, proposal_id: u64) {
            self._valid_proposal(proposal_id);
            self.ownable.assert_only_owner();

            let proposal = self.proposals.entry(proposal_id);

            assert!(proposal.status.read() == ProposalStatus::IN_PROGRESS, "Vote is not in progress");
            assert!(
                starknet::get_block_timestamp() >= proposal.expiration_time.read(),
                "Voting period has not expired"
            );

            proposal.status.write(ProposalStatus::TALLY);
        }

        fn set_proposal_to_ended(ref self: ContractState, proposal_id: u64) {
            self._valid_proposal(proposal_id);
            self.ownable.assert_only_owner();

            let proposal = self.proposals.entry(proposal_id);

            assert!(proposal.status.read() == ProposalStatus::TALLY, "Proposal should be in tally");
            assert!(
                starknet::get_block_timestamp() >= proposal.expiration_time.read(),
                "Voting period has not expired"
            );

            proposal.status.write(ProposalStatus::ENDED);
        }

        fn get_proposal_status(self: @ContractState, proposal_id: u64) -> ProposalStatus {
            self._valid_proposal(proposal_id);

            self.proposals.entry(proposal_id).status.read()
        }

        fn get_proposal_expiration_time(self: @ContractState, proposal_id: u64) -> u64 {
            self._valid_proposal(proposal_id);

            self.proposals.entry(proposal_id).expiration_time.read()
        }

        fn count_votes(self: @ContractState, proposal_id: u64) -> (u256, u256) {
            self._valid_proposal(proposal_id);

            let proposal = self.proposals.entry(proposal_id);
            let voters = proposal.voters;
            let mut yes_votes: u256 = 0;
            let mut no_votes: u256 = 0;

            let mut i = 0;
            let len = voters.len();

            while i != len {
                if i == len {
                    break;
                }

                let voter: ContractAddress = voters.at(i).read();
                let voter_info: Voter = proposal.voter_info.entry(voter).read();
                let weight: u256 = voter_info.weight;
                let vote: Vote = voter_info.vote;

                match vote {
                    Vote::YES => {
                      yes_votes = yes_votes + weight;
                    },
                    Vote::NO => {
                      no_votes = no_votes + weight;
                    }
                }

                i += 1;
            };

            (yes_votes, no_votes)
        }

        fn cast_vote(ref self: ContractState, proposal_id: u64, num_tokens: u256, vote: Vote) {
            self._valid_proposal(proposal_id);

            let caller = get_caller_address();
            let contract_address = get_contract_address();
            let proposal = self.proposals.entry(proposal_id);

            assert!(proposal.status.read() == ProposalStatus::IN_PROGRESS, "Proposal has expired.");
            assert!(!self.user_has_voted(proposal_id, caller), "User already voted on this proposal");
            assert!(
                proposal.expiration_time.read() > starknet::get_block_timestamp(),
                "For this proposal, the voting time expired"
            );

            let voter_balance = self._balance_of(caller);

            assert!(voter_balance >= num_tokens, "Not enough tokens to vote");

            self._transfer(
                contract_address,
                num_tokens,
            );

            let weight = self.sqrt(num_tokens);

            let voter_info = Voter { has_voted: true, vote, weight: weight };
            proposal.voter_info.entry(caller).write(voter_info);
            proposal.voters.push(caller);

            self.emit(Event::VoteCasted(VoteCasted {
                voter: caller,
                proposal_id: proposal_id,
                weight: weight,
            }));
        }

        fn user_has_voted(self: @ContractState, proposal_id: u64, user: ContractAddress) -> bool {
            self._valid_proposal(proposal_id);

            let proposal = self.proposals.entry(proposal_id);
            let voter_info = proposal.voter_info.entry(user).read();

            voter_info.has_voted
        }

        fn sqrt(self: @ContractState, x: u256) -> u256 {
            x.sqrt().into()
        }

        fn _transfer(
          ref self: ContractState, recipient: ContractAddress, amount: u256
        ) {
            self.erc20.transfer(recipient, amount);
        }

        fn _approve(
            ref self: ContractState, spender: ContractAddress, amount: u256
        ) {
            self.erc20.approve(spender, amount);
        }

        fn _transfer_from(
            ref self: ContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
        ) {
            self.erc20.transfer_from(sender, recipient, amount);
        }

        fn _balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.erc20.balance_of(account)
        }

        fn _total_supply(self: @ContractState) -> u256 {
            self.erc20.total_supply()
        }

        fn _mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            self.ownable.assert_only_owner();

            self.erc20.mint(recipient, amount);
        }

        fn _allowance(self: @ContractState, owner: ContractAddress, spender: ContractAddress) -> u256 {
            self.erc20.allowance(owner, spender)
        }
    }

    #[generate_trait]
    impl PrivateFunctions of PrivateFunctionsTrait {
        fn _valid_proposal(self: @ContractState, proposal_id: u64) {
            assert!(
                proposal_id > 0 && proposal_id <= self.proposal_count.read(),
                "Not a valid Proposal Id"
            );
        }
    }
}
