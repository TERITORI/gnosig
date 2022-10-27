package multisig

// state
// we multiply by this when calculating needed_votes in order to round up properly
// Note: `10u128.pow(9)` fails as "u128::pow` is not yet stable as a const fn"
const PRECISION_FACTOR = 1_000_000_000

type Config struct {
	Threshold       Threshold
	MaxVotingPeriod uint64
	// Total weight and voters are queried from this contract
	// GroupAddr Cw4Contract
}

type Group struct {
	Members []Member
}

type Member struct {
	Address string
	Power   uint64
}

type Threshold struct {
	// /// Declares that a fixed weight of Yes votes is needed to pass.
	// /// See `ThresholdResponse.AbsoluteCount` in the cw3 spec for details.
	// AbsoluteCount { weight: u64 },

	// /// Declares a percentage of the total weight that must cast Yes votes in order for
	// /// a proposal to pass.
	// /// See `ThresholdResponse.AbsolutePercentage` in the cw3 spec for details.
	// AbsolutePercentage { percentage: Decimal },

	// /// Declares a `quorum` of the total votes that must participate in the election in order
	// /// for the vote to be considered at all.
	// /// See `ThresholdResponse.ThresholdQuorum` in the cw3 spec for details.
	// ThresholdQuorum { threshold: Decimal, quorum: Decimal },
}

type Proposal struct {
	Title       string
	Description string
	StartHeight uint64
	Expires     uint64
	Msgs        []Msg
	Status      Status
	// pass requirements
	Threshold Threshold
	// the total weight when the proposal started (used to calculate percentages)
	TotalWeight uint64
	// summary of existing votes
	Votes Votes
}

type Status struct {
}

// weight of votes for each option
type Votes struct {
	Yes     uint64
	No      uint64
	Abstain uint64
	Veto    uint64
}

type Msg struct{}

// impl Votes {
//     /// sum of all votes
//     pub fn total(&self) -> u64 {
//         self.yes + self.no + self.abstain + self.veto
//     }

//     /// create it with a yes vote for this much
//     pub fn yes(init_weight: u64) -> Self {
//         Votes {
//             yes: init_weight,
//             no: 0,
//             abstain: 0,
//             veto: 0,
//         }
//     }

//     pub fn add_vote(&mut self, vote: Vote, weight: u64) {
//         match vote {
//             Vote::Yes => self.yes += weight,
//             Vote::Abstain => self.abstain += weight,
//             Vote::No => self.no += weight,
//             Vote::Veto => self.veto += weight,
//         }
//     }
// }

// impl Proposal {
//     /// current_status is non-mutable and returns what the status should be.
//     /// (designed for queries)
//     pub fn current_status(&self, block: &BlockInfo) -> Status {
//         let mut status = self.status;

//         // if open, check if voting is passed or timed out
//         if status == Status::Open && self.is_passed(block) {
//             status = Status::Passed;
//         }
//         if status == Status::Open && self.expires.is_expired(block) {
//             status = Status::Rejected;
//         }

//         status
//     }

//     /// update_status sets the status of the proposal to current_status.
//     /// (designed for handler logic)
//     pub fn update_status(&mut self, block: &BlockInfo) {
//         self.status = self.current_status(block);
//     }

//     // returns true iff this proposal is sure to pass (even before expiration if no future
//     // sequence of possible votes can cause it to fail)
//     pub fn is_passed(&self, block: &BlockInfo) -> bool {
//         match self.threshold {
//             Threshold::AbsoluteCount {
//                 weight: weight_needed,
//             } => self.votes.yes >= weight_needed,
//             Threshold::AbsolutePercentage {
//                 percentage: percentage_needed,
//             } => {
//                 self.votes.yes
//                     >= votes_needed(self.total_weight - self.votes.abstain, percentage_needed)
//             }
//             Threshold::ThresholdQuorum { threshold, quorum } => {
//                 // we always require the quorum
//                 if self.votes.total() < votes_needed(self.total_weight, quorum) {
//                     return false;
//                 }
//                 if self.expires.is_expired(block) {
//                     // If expired, we compare Yes votes against the total number of votes (minus abstain).
//                     let opinions = self.votes.total() - self.votes.abstain;
//                     self.votes.yes >= votes_needed(opinions, threshold)
//                 } else {
//                     // If not expired, we must assume all non-votes will be cast as No.
//                     // We compare threshold against the total weight (minus abstain).
//                     let possible_opinions = self.total_weight - self.votes.abstain;
//                     self.votes.yes >= votes_needed(possible_opinions, threshold)
//                 }
//             }
//         }
//     }
// }

// // this is a helper function so Decimal works with u64 rather than Uint128
// // also, we must *round up* here, as we need 8, not 7 votes to reach 50% of 15 total
// fn votes_needed(weight: u64, percentage: Decimal) -> u64 {
//     let applied = percentage * Uint128::new(PRECISION_FACTOR * weight as u128);
//     // Divide by PRECISION_FACTOR, rounding up to the nearest integer
//     ((applied.u128() + PRECISION_FACTOR - 1) / PRECISION_FACTOR) as u64
// }

// // we cast a ballot with our chosen vote and a given weight
// // stored under the key that voted
// #[derive(Serialize, Deserialize, Clone, PartialEq, JsonSchema, Debug)]
// pub struct Ballot {
//     pub weight: u64,
//     pub vote: Vote,
// }

// // unique items
// pub const CONFIG: Item<Config> = Item::new("config");
// pub const PROPOSAL_COUNT: Item<u64> = Item::new("proposal_count");

// // multiple-item map
// pub const BALLOTS: Map<(u64, &Addr), Ballot> = Map::new("votes");
// pub const PROPOSALS: Map<u64, Proposal> = Map::new("proposals");

// pub fn next_id(store: &mut dyn Storage) -> StdResult<u64> {
//     let id: u64 = PROPOSAL_COUNT.may_load(store)?.unwrap_or_default() + 1;
//     PROPOSAL_COUNT.save(store, &id)?;
//     Ok(id)
// }

// pub fn parse_id(data: &[u8]) -> StdResult<u64> {
//     match data[0..8].try_into() {
//         Ok(bytes) => Ok(u64::from_be_bytes(bytes)),
//         Err(_) => Err(StdError::generic_err(
//             "Corrupted data found. 8 byte expected.",
//         )),
//     }
// }

// // commands
//     Propose {
//         title: String,
//         description: String,
//         msgs: Vec<CosmosMsg<Empty>>,
//         // note: we ignore API-spec'd earliest if passed, always opens immediately
//         latest: Option<Expiration>,
//     },
//     Vote {
//         proposal_id: u64,
//         vote: Vote,
//     },
//     Execute {
//         proposal_id: u64,
//     },
//     Close {
//         proposal_id: u64,
//     },
//     /// Handles update hook messages from the group contract
//     MemberChangedHook(MemberChangedHookMsg),

// // query
// 	/// Return ThresholdResponse
//     Threshold {},
//     /// Returns ProposalResponse
//     Proposal { proposal_id: u64 },
//     /// Returns ProposalListResponse
//     ListProposals {
//         start_after: Option<u64>,
//         limit: Option<u32>,
//     },
//     /// Returns ProposalListResponse
//     ReverseProposals {
//         start_before: Option<u64>,
//         limit: Option<u32>,
//     },
//     /// Returns VoteResponse
//     Vote { proposal_id: u64, voter: String },
//     /// Returns VoteListResponse
//     ListVotes {
//         proposal_id: u64,
//         start_after: Option<String>,
//         limit: Option<u32>,
//     },
//     /// Returns VoterInfo
//     Voter { address: String },
//     /// Returns VoterListResponse
//     ListVoters {
//         start_after: Option<String>,
//         limit: Option<u32>,
//     },

func Render(path string) string {
	// if path == "" {
	// 	text := "# Welcome"
	// 	if len(Hello) == 0 {
	// 		return text + "\n"
	// 	}
	// 	for _, h := range Hello {
	// 		text += "\n* " + h
	// 	}
	// 	return text
	// }
	// Hello = append(Hello, path)
	// return "# " + hello.World(path)
	return ""
}
