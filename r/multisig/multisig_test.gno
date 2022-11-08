package multisig

import (
	"testing"
)

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
