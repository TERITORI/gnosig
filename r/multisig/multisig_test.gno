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
	quorum = Quorum{
		members:     quorumMembers,
		minApproval: 2,
	}

	// check not multisig member call
	std.TestSetOrigCaller(caller)
	assertPanic(t, func() { CreateProposal("title", "description", []Msg{}, uint64(time.Now().Unix())+1000) })

	// check already expired timestmap
	std.TestSetOrigCaller(caller1)
	assertPanic(t, func() { CreateProposal("title", "description", []Msg{}, uint64(time.Now().Unix())-1) })

	// check proposal addition check
	std.TestSetOrigCaller(caller1)
	CreateProposal("title", "description", []Msg{}, uint64(time.Now().Unix())+1000)
	proposals := GetProposals(0, 10)
	if len(proposals) != 1 {
		t.Errorf("Expected number of proposals %d got %d", 1, len(proposals))
	}
}

func TestApprove(t *testing.T) {
	// check not multisig member call
	std.TestSetOrigCaller(caller)
	assertPanic(t, func() { Approve(0, false) })

	// invalid proposal id check
	std.TestSetOrigCaller(caller2)
	assertPanic(t, func() { Approve(1, false) })

	std.TestSetOrigCaller(caller2)
	Approve(0, false)

	// approvals increase check
	proposal := GetProposal(0)
	if len(proposal.Approvals) != 2 {
		t.Errorf("Expected number of approvals %d got %d", 2, len(proposals))
	}
	if proposal.Status != TO_EXECUTE {
		t.Errorf("Expected proposal status TO_EXECUTE got %d", proposal.Status)
	}

	// already approved proposal check
	assertPanic(t, func() { Approve(0, false) })
}

func TestExecute(t *testing.T) {
	// check caller is multisig member
	std.TestSetOrigCaller(caller)
	assertPanic(t, func() { Execute(0) })

	// proposal id check
	std.TestSetOrigCaller(caller2)
	assertPanic(t, func() { Execute(1) })

	// valid execution
	std.TestSetOrigCaller(caller2)
	Execute(0)

	// check valid execution result
	proposal := GetProposal(0)
	if proposal.Status != EXECUTED {
		t.Errorf("Expected proposal status EXECUTED got %d", proposal.Status)
	}
}

func TestUpdateQuorum(t *testing.T) {
	// set caller before contract call
	std.TestSetOrigCaller(caller)
	updateQuorum(quorumMembers, 3)
	quorum := GetQuorum()

	if len(quorum.members) != 3 {
		t.Errorf("Expected quorum members %d got %d", 3, len(quorum.members))
	}
	if quorum.minApproval != 3 {
		t.Errorf("Expected quorum minApproval %d got %d", 3, quorum.minApproval)
	}
}
