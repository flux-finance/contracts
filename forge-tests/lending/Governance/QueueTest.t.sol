pragma solidity 0.8.16;

import "forge-tests/lending/DeployBasicLendingMarket.t.sol";
import "contracts/lending/ondo/ondo-token/IOndo.sol";

/*//////////////////////////////////////////////////////////////
  Compound Tests: tests/Governance/GovernorBravo/QueueTest.js
//////////////////////////////////////////////////////////////*/

contract Test_Lending_Market_Governance_Queue is BasicLendingMarket {
  address[] targets;
  uint[] values;
  string[] signatures;
  bytes[] calldatas;
  string[] description;

  function test_revert_on_queueing_overlapping_actions_same_proposal() public {
    targets.push(address(0));
    targets.push(address(0));
    values.push(0);
    values.push(0);
    signatures.push("getBalanceOf(address)");
    signatures.push("getBalanceOf(address)");
    calldatas.push(abi.encode(targets[0]));
    calldatas.push(abi.encode(targets[1]));

    enfranchise(charlie, 5000000e18);

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

    vm.roll(block.number + 10);
    console.log(governorProxied.state(2));
    console.log("here");

    vm.prank(charlie);
    governorProxied.castVote(2, 1);
    vm.roll(block.timestamp + 17280 + 20);

    vm.expectRevert(
      bytes(
        "GovernorBravo::queueOrRevertInternal: identical proposal action already queued at eta"
      )
    );
    governorProxied.queue(2);
  }

  function test_revert_on_queueing_overlapping_actions_in_different_proposals()
    public
  {
    targets.push(address(0));
    values.push(0);
    signatures.push("getBalanceOf(address)");
    calldatas.push(abi.encode(targets[0]));

    enfranchise(charlie, 5000000e18);

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
    vm.prank(charlie);
    governorProxied.propose(
      targets,
      values,
      signatures,
      calldatas,
      "do nothing"
    );

    vm.roll(block.number + 10);

    vm.startPrank(charlie);
    governorProxied.castVote(2, 1);
    governorProxied.castVote(3, 1);

    vm.roll(block.number + 20000);

    governorProxied.queue(2);
    vm.expectRevert(
      bytes(
        "GovernorBravo::queueOrRevertInternal: identical proposal action already queued at eta"
      )
    );
    governorProxied.queue(3);

    vm.warp(block.timestamp + 101);
    governorProxied.queue(3);
  }

  function enfranchise(address user, uint256 amount) public {
    vm.prank(ONDO_WHALE);
    ONDO_TOKEN.transfer(user, amount);
    vm.prank(user);
    ONDO_TOKEN.delegate(user);
  }
}
