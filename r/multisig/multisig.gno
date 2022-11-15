package multisig

import (
	"fmt"
	"std"
	"strconv"
	"strings"
	"time"
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

func (s ProposalStatus) String() string {
	switch s {
	case PENDING:
		return "Pending"
	case TO_EXECUTE:
		return "ToExecute"
	case EXECUTED:
		return "Executed"
	case EXPIRED:
		return "Expired"
	case CANCELLED:
		return "Cancelled"
	}
	return ""
}

type Proposal struct {
	Id          uint64         // incremented at every new proposal
	Title       string         // title metadata
	Description string         // description metadata
	Expiration  uint64         // expiration timestamp
	Tx          []Msg          // raw transaction
	Status      ProposalStatus // 0: PENDING | 1: TO_EXECUTE | 2: EXECUTED | 3: EXPIRED
	Approvals   []Approval     // approvals on the proposal
}

type Quorum struct {
	members     []std.Address // members of the quorum
	minApproval uint64        // approval ratio of the quorum
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
	caller := std.GetOrigCaller()

	// if sender is not in the current quorum, revert
	isCallerMultisigMember := isQuorumMember(caller)
	if !isCallerMultisigMember {
		panic("caller is not a multisig member")
	}

	// if expirationTimestamp is already reached, panic
	if time.Now().Unix() > int64(expirationTimestamp) {
		panic("expiration time already passed")
	}

	// Create a proposal for the quorum and add it to the proposals array
	proposalId := uint64(len(proposals))
	proposals = append(proposals, Proposal{
		Id:          proposalId,
		Title:       title,
		Description: description,
		Expiration:  expirationTimestamp,
		Tx:          rawTx,
		Status:      PENDING, // 0: PENDING | 1: TO_EXECUTE | 2: EXECUTED | 3: EXPIRED
		Approvals: []Approval{
			{
				address:   caller,
				timestamp: uint64(time.Now().Unix()),
			},
		}, // approvals on the proposal
	})
}

func Approve(proposalId uint64, execute bool) {
	caller := std.GetOrigCaller()

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

	// if proposal expiration time is reached, set proposal as EXPIRED
	if time.Now().Unix() > int64(proposal.Expiration) {
		proposals[proposalId].Status = EXPIRED
		return
	}

	// Create an approval in a the specified proposal
	proposals[proposalId].Approvals = append(proposal.Approvals, Approval{
		address:   caller,
		timestamp: uint64(time.Now().Unix()),
	})

	if len(proposals[proposalId].Approvals) >= int(quorum.minApproval) {
		// if current quorum is reached after this vote on the proposal, set proposal to TO_EXECUTE
		proposals[proposalId].Status = TO_EXECUTE
		if execute { // if current quorum is reached after this vote on the proposal and execute is true, execute the proposal
			Execute(proposalId)
		}
	}
}

func Execute(proposalId uint64) {
	caller := std.GetOrigCaller()

	if int(proposalId) >= len(proposals) {
		panic("invalid proposal id")
	}
	proposal := proposals[proposalId]

	// if tx is not TO_EXECUTE, revert
	if proposal.Status != TO_EXECUTE {
		panic("not an executable proposal")
	}

	// if sender is not in the current quorum, revert
	isCallerMultisigMember := isQuorumMember(caller)
	if !isCallerMultisigMember {
		panic("caller is not a multisig member")
	}

	// if expiration time is reached, set proposal as CANCELLED
	if time.Now().Unix() > int64(proposal.Expiration) {
		proposals[proposalId].Status = CANCELLED
		return
	}

	// TODO: Execute an approved tx

	// set proposal to EXECUTED
	proposals[proposalId].Status = EXECUTED
}

func updateQuorum(addresses []std.Address, minApproval uint64) {
	// TODO: if sender is not the multisig calling itself, revert

	// Update the current quorum
	// Note: to update the quorum, users have to make a proposal with rawTx calling this internal func
	quorum.members = addresses
	quorum.minApproval = minApproval
}

func GetQuorum() Quorum {
	return quorum
}

func GetProposal(proposalId uint64) Proposal {
	if int(proposalId) >= len(proposals) {
		panic("invalid proposal id")
	}
	return proposals[proposalId]
}

func GetProposals(startAfter, limit uint64) []Proposal {
	max := uint64(len(proposals))
	if startAfter+limit < max {
		max = startAfter + limit
	}
	return proposals[startAfter:max]
}

func Render(path string) string {
	if path == "" {
		membersText := ``
		for _, member := range quorum.members {
			membersText += fmt.Sprintf("- %s\n", member.String())
		}

		pendingProposals := ``
		executedProposals := ``
		cancelledProposals := ``

		for index, proposal := range proposals {
			switch proposal.Status {
			case PENDING:
				pendingProposals += fmt.Sprintf("- [%s](https://gnosig.com/proposal/%d)\n", proposal.Title, index+1)
			case EXECUTED:
				executedProposals += fmt.Sprintf("- [%s](https://gnosig.com/proposal/%d)\n", proposal.Title, index+1)
			case CANCELLED:
				cancelledProposals += fmt.Sprintf("- [%s](https://gnosig.com/proposal/%d)\n", proposal.Title, index+1)
			}
		}

		return fmt.Sprintf(`
# Gnosig setup

Members:
%s

Minimum approval needed: %d

# Proposals

Pending:
%s

Executed:
%s

Cancelled:
%s`, membersText, quorum.minApproval, pendingProposals, executedProposals, cancelledProposals)
	}

	subPath := strings.Split(path, "/")
	switch subPath[0] {
	case "proposal":
		if len(subPath) == 1 {
			panic("no proposal id provided on path")
		}
		proposalId, err := strconv.Atoi(subPath[1])
		if err != nil {
			panic(err)
		}
		if len(proposals) <= int(proposalId) {
			panic("invalid proposal id")
		}
		proposal := proposals[proposalId]

		statusText := proposal.Status.String()
		approversText := ``
		for _, approval := range proposal.Approvals {
			approversText += fmt.Sprintf("- %s\n", approval.address.String())
		}
		return fmt.Sprintf(`Status: %s
Need at least %d approvals

Proposal description:
%s

Approved by:
%s`, statusText, quorum.minApproval, proposal.Description, approversText)
	}

	return ""
}
