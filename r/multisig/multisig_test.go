package multisig

import (
	"testing"
)

func TestVote(t *testing.T) {
	expected := "# Welcome\n"
	got := Render("") // /r/solve
	if got != expected {
		t.Errorf("Expected %q, got %q.", expected, got)
	}
}
