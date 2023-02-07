pragma solidity 0.8.16;

import "forge-tests/lending/DeployBasicLendingMarket.t.sol";

/*//////////////////////////////////////////////////////////////
    Compound Tests: tests/Governance/GovernorBravo/CastVoteTest.js
//////////////////////////////////////////////////////////////*/

contract Test_Lending_Market_Governance_CastVote is BasicLendingMarket {
  address[] targets;
  uint[] values;
  string[] signatures;
  bytes[] calldatas;
  string[] description;

  function test_create_proposal() public {
    targets.push(address(0));
    values.push(0);
    signatures.push("getBalanceOf(address)");
    calldatas.push(abi.encode(targets[0]));
    vm.startPrank(ONDO_WHALE);
    ONDO_TOKEN.delegate(address(this));
    vm.stopPrank();
    vm.roll(block.number + 10);

    governorProxied.propose(
      targets,
      values,
      signatures,
      calldatas,
      "do nothing"
    );
    console.log(governorProxied.latestProposalIds(address(this)));
    console.log(governorProxied.proposalCount());
  }

  function test_reverts_when_no_matching_valid_proposal_id() public {
    vm.startPrank(ONDO_WHALE);
    vm.expectRevert("GovernorBravo::state: invalid proposal id");
    governorProxied.castVote(1, 1);
    vm.stopPrank();
  }

  function test_reverts_voters_cannot_double_vote() public {
    test_create_proposal();

    enfranchise(charlie, 100e18);
    enfranchise(alice, 100e18);

    vm.roll(block.number + 2);

    vm.prank(charlie);
    governorProxied.castVote(2, 1);

    vm.prank(alice);
    governorProxied.castVote(2, 1);

    vm.expectRevert(
      bytes("GovernorBravo::castVoteInternal: voter already voted")
    );
    vm.prank(charlie);
    governorProxied.castVote(2, 1);
  }

  function test_add_sender_to_proposals_voters_set() public {
    test_create_proposal();

    enfranchise(charlie, 100e18);
    console.log();
    vm.roll(block.number + 100);

    console.log(ONDO_TOKEN.getPriorVotes(charlie, block.number - 1));
    vm.prank(charlie);
    governorProxied.castVote(2, 1);

    IGovernorBravoDelegate.Receipt memory result = governorProxied.getReceipt(
      2,
      charlie
    );
    assertEq(result.hasVoted, true);
    assertEq(result.support, 1);
    assertEq(result.votes, 100e18);
  }

  function test_yay_votes_are_counted_for_proposal() public {
    test_create_proposal();

    enfranchise(charlie, 100e18);
    vm.roll(block.number + 100);

    vm.prank(charlie);
    governorProxied.castVote(2, 1);
    uint256 pro = governorProxied.getForVotes(2);
    assertEq(pro, 100e18);
  }

  function test_nay_votes_are_counted_for_proposal() public {
    test_create_proposal();

    enfranchise(charlie, 100e18);
    vm.roll(block.number + 100);

    vm.prank(charlie);
    governorProxied.castVote(2, 0);
    uint256 con = governorProxied.getConVotes(2);
    assertEq(con, 100e18);
  }

  function enfranchise(address user, uint256 amount) public {
    vm.prank(ONDO_WHALE);
    ONDO_TOKEN.transfer(user, amount);
    vm.prank(user);
    ONDO_TOKEN.delegate(user);
  }
}
