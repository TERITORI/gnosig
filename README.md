# Gnosig

The goal of the project is to provide multisig functionality in Gnolang.

## Test execution

Use `gnodev test r/solve --verbose --root-dir ../gno` to run the tests.

## Implementation direction

We will follow the implementation of cw3 on cosmwasm.

## User flow

1- you can deploy a contract
2- this contract has a quorum (basically an array of addresses and an agreement ratio) that can be updated (add new members, remove members, change quorum ratio)
3- one member of the quorum can propose a tx
4- each member of the quorum makes a tx to vote yes for the proposed tx id
5- one member can execute the tx if nb of yes > quorum
6- one member can close the proposal if nb of yes < quorum (can be annoying)
I think step 6 is weird, maybe we can just set an expiration period for each proposal when we submit one. If block.timestamp > expiration then no one can vote or execute it
What is you github handle ? 🙂 I'll add you to a github repo for this project

## Research

https://hackmd.io/lF6_guCYQemIYXHV0oCynA

## Resources

https://github.com/slashbinslashnoname/gnoland_cheatsheet
https://github.com/CosmWasm/cw-plus/tree/main/contracts/cw3-flex-multisig
https://notes.pwnh4.com/s/pPIPCgXFw

https://gnoland.space/r/users/types.gno
https://gnoland.space/r/users/users.gno

https://github.com/gnolang/gno/tree/master/examples/gno.land/r/boards
