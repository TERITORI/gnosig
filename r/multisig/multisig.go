package multisig

import (
	"std"
)

// MULTI SIG DATA TYPES
type Approval struct {
	address   std.Address // address of the approver
	timestamp uint64      // block timestamp of the approval
}

type ProposalStatus uint32

const (
	PENDING    ProposalStatus = 0
	TO_EXECUTE ProposalStatus = 1
	EXECUTED   ProposalStatus = 2
	EXPIRED    ProposalStatus = 3
	CANCELLED  ProposalStatus = 4
)

type Proposal struct {
	Id          uint64         // incremented at every new proposal
	Title       string         // title metadata
	Description string         // description metadata
	Expiration  uint64         // expiration timestamp
	Tx          []Msg          // raw transaction
	status      ProposalStatus // 0: PENDING | 1: TO_EXECUTE | 2: EXECUTED | 3: EXPIRED
	Approvals   []Approval     // approvals on the proposal
}

type Quorum struct {
	members []std.Address // members of the quorum
	ratio   float64       // approval ratio of the quorum
}

// MULTI SIG STATE
var quorum Quorum

var proposals []Proposal

type Msg struct{}

func isQuorumMember(address std.Address) bool {
	for _, member := range quorum.members {
		if member == address {
			return true
		}
	}
	return false
}

// MULTI SIG FUNCTIONS
func CreateProposal(title, description string, rawTx []Msg, expirationTimestamp uint64) {
	// assert CallTx call.
	std.AssertOriginCall()
	caller := std.GetCallerAt(2)
	if caller != std.GetOrigCaller() {
		panic("should not happen") // because std.AssertOrigCall().
	}

	// if sender is not in the current quorum, revert
	isCallerMultisigMember := isQuorumMember(caller)
	if !isCallerMultisigMember {
		panic("caller is not a multisig member")
	}

	// TODO: if expirationTimestamp is already reached, panic

	// Create a proposal for the quorum and add it to the proposals array
	proposalId := uint64(len(proposals))
	proposals = append(proposals, Proposal{
		Id:          proposalId,
		Title:       title,
		Description: description,
		Expiration:  expirationTimestamp,
		Tx:          rawTx,
		status:      PENDING,      // 0: PENDING | 1: TO_EXECUTE | 2: EXECUTED | 3: EXPIRED
		Approvals:   []Approval{}, // approvals on the proposal
	})
}

func Approve(proposalId uint64, execute bool) {
	// assert CallTx call.
	std.AssertOriginCall()
	caller := std.GetCallerAt(2)
	if caller != std.GetOrigCaller() {
		panic("should not happen") // because std.AssertOrigCall().
	}

	// if sender is not in the current quorum, revert
	isCallerMultisigMember := isQuorumMember(caller)
	if !isCallerMultisigMember {
		panic("caller is not a multisig member")
	}

	// if sender already approved this proposal, panic
	if int(proposalId) >= len(proposals) {
		panic("invalid proposal id")
	}
	proposal := proposals[proposalId]
	for _, approval := range proposal.Approvals {
		if approval.address == caller {
			panic("already approved")
		}
	}

	// TODO: if proposal expiration time is reached, set proposal as EXPIRED
	proposals[proposalId].status = EXPIRED

	// Create an approval in a the specified proposal
	proposals[proposalId].Approvals = append(proposal.Approvals, Approval{
		address:   caller,
		timestamp: 0, // TODO: set from block timestamp
	})

	if float64(quorum.members)*float64(quorum.ratio) >= float64(len(proposal.Approvals)) {
		if execute { // if current quorum is reached after this vote on the proposal and execute is true, execute the proposal
			Execute(proposalId)
		} else { // if current quorum is reached after this vote on the proposal and execute is false, set proposal to TO_EXECUTE
			proposals[proposalId].status = TO_EXECUTE
		}
	}
}

func Execute(proposalId uint64) {
	// assert CallTx call.
	std.AssertOriginCall()
	caller := std.GetCallerAt(2)
	if caller != std.GetOrigCaller() {
		panic("should not happen") // because std.AssertOrigCall().
	}

	if int(proposalId) >= len(proposals) {
		panic("invalid proposal id")
	}
	proposal := proposals[proposalId]

	// if tx is not TO_EXECUTE, revert
	if proposal.status != TO_EXECUTE {
		panic("not an executable proposal")
	}

	// if sender is not in the current quorum, revert
	isCallerMultisigMember := isQuorumMember(caller)
	if !isCallerMultisigMember {
		panic("caller is not a multisig member")
	}

	// TODO: if expiration time is reached, set proposal as CANCELLED
	proposals[proposalId].status = CANCELLED

	// TODO: Execute an approved tx

	// set proposal to EXECUTED
	proposals[proposalId].status = EXECUTED
}

func updateQuorum(addresses []std.Address, ratio float64) {
	// TODO: if sender is not the multisig calling itself, revert

	// Update the current quorum
	// Note: to update the quorum, users have to make a proposal with rawTx calling this internal func
	quorum.members = addresses
	quorum.ratio = ratio
}

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
