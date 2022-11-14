package multisig

import (
	"std"
	"testing"
	"time"
)

var caller std.Address = "g1rel7980x4y257yh30umy3jx223efwakvnabcde"
var caller1 std.Address = "g1rel7980x4y257yh30umy3jx223efwakvnaaaaa"
var caller2 std.Address = "g1rel7980x4y257yh30umy3jx223efwakvnbbbbb"
var quorumMembers = []std.Address{
	"g1rel7980x4y257yh30umy3jx223efwakvnaaaaa",
	"g1rel7980x4y257yh30umy3jx223efwakvnbbbbb",
	"g1rel7980x4y257yh30umy3jx223efwakvnccccc",
}

func assertPanic(t *testing.T, f func()) {
	defer func() {
		if r := recover(); r == nil {
			t.Errorf("The code did not panic")
		}
	}()
	f()
}

func TestInitialRender(t *testing.T) {
	expected := `
# Gnosig setup

Members:


Minimum approval needed: 0

# Proposals

Pending:


Executed:


Cancelled:
`

	// check home rendering for empty set
	got := Render("")
	if got != expected {
		t.Errorf("Expected %q, got %q.", expected, got)
	}

	// check panics for not available proposal
	assertPanic(t, func() { Render("proposal/1") })
}

func TestCreateProposal(t *testing.T) {
	// set caller before contract call
	std.TestSetOrigCaller(caller)
	// TODO: check not multisig member call
	// TODO: check already expired timestmap
	// TODO: check proposal addition check
	CreateProposal("title", "description", []Msg{}, uint64(time.Now().Unix()))
	proposals := GetProposals(0, 10)
	if len(proposals) != 1 {
		t.Errorf("Expected number of proposals %d got %d", 1, len(proposals))
	}
}

// func TestApprove(t *testing.T) {
// 	// set caller before contract call
// 	std.TestSetOrigCaller(caller)
// 	// TODO: check not multisig member call
// 	// TODO: invalid proposal id check
// 	// TODO: approvals increase check
// 	Approve(0, false)
// 	// TODO: already approved proposal check
// 	// TODO: already expired proposal check
// }

// func TestExecute(t *testing.T) {
// 	// set caller before contract call
// 	std.TestSetOrigCaller(caller)
// 	// TODO: proposal id check
// 	// TODO: proposal status check if TO_EXECUTE
// 	// TODO: check caller is multisig member
// 	// TODO: check status update to EXECTED
// 	Execute(0)
// 	// TODO: already expired proposal check
// }

// func TestUpdateQuorum(t *testing.T) {
// 	// set caller before contract call
// 	std.TestSetOrigCaller(caller)
// 	updateQuorum(quorumMembers, 2)
// 	quorum := GetQuorum()
// 	// TODO: check members update
// 	// TODO: check minApproval update
// }

// func TestGetProposal(t *testing.T) {
// 	quorum := GetProposal(0)
// 	// TODO: invalid proposal id check
// 	// TODO: correct proposal response check
// }
