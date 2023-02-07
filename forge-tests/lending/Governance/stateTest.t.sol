pragma solidity 0.8.16;

import "forge-tests/lending/DeployBasicLendingMarket.t.sol";
import "contracts/lending/ondo/ondo-token/IOndo.sol";

/*//////////////////////////////////////////////////////////////
  Compound Tests: tests/Governance/GovernorBravo/StateTest.js
//////////////////////////////////////////////////////////////*/

contract Test_Lending_Market_Governance_state is BasicLendingMarket {
  address[] targets;
  uint[] values;
  string[] signatures;
  bytes[] calldatas;
  string[] description;

  function test_Invalid_for_proposal_not_found() public {
    vm.expectRevert(bytes("GovernorBravo::state: invalid proposal id"));
    governorProxied.state(5);
  }

  function test_proposal_is_pending() public {
    createSimpleProposal();
    uint256 result = governorProxied.state(2);
    assertEq(result, 0); // Assert that the proposal is Pending
  }

  function test_proposal_is_active() public {
    createSimpleProposal();
    vm.roll(block.number + 10);
    uint256 result = governorProxied.state(2);
    assertEq(result, 1); // Assert that the proposal is Active
  }

  function test_proposal_is_canceled() public {
    createSimpleProposal();
    vm.roll(block.number + 10);
    governorProxied.cancel(2);
    uint256 result = governorProxied.state(2);
    assertEq(result, 2); // Assert that the proposal is Canceled
  }

  function test_proposal_is_defeated() public {
    createSimpleProposal();
    vm.roll(block.number + 20000);
    uint256 result = governorProxied.state(2);
    assertEq(result, 3); // Assert that the proposal is defeated
  }

  function test_proposal_succeeded() public {
    createSimpleProposal();
    enfranchise(charlie, 5000000e18);
    vm.prank(charlie);
    governorProxied.castVote(2, 1);
    vm.roll(block.number + 20000);
    uint256 result = governorProxied.state(2);
    assertEq(result, 4); // Assert that the proposal Succeeded
  }

  function test_proposal_queued() public {
    createSimpleProposal();
    enfranchise(charlie, 5000000e18);
    vm.prank(charlie);
    governorProxied.castVote(2, 1);
    vm.roll(block.number + 20000);

    governorProxied.queue(2);
    uint256 result = governorProxied.state(2);
    assertEq(result, 5); // Assert that the proposal is queued
  }

  function test_proposal_expired() public {
    createSimpleProposal();
    enfranchise(charlie, 5000000e18);
    vm.prank(charlie);
    governorProxied.castVote(2, 1);
    vm.roll(block.number + 20000);
    governorProxied.queue(2);
    vm.warp(block.timestamp + 25 days);
    uint256 result = governorProxied.state(2);
    assertEq(result, 6); // Assert that the proposal is Expired
  }

  function test_proposal_executed() public {
    createSimpleProposal();
    enfranchise(charlie, 5000000e18);
    vm.prank(charlie);
    governorProxied.castVote(2, 1);
    vm.roll(block.number + 20000);
    governorProxied.queue(2);
    vm.warp(block.timestamp + 10 days);
    governorProxied.execute(2);
    uint256 result = governorProxied.state(2);
    assertEq(result, 7); // Assert that the proposal is Executed
  }

  function createSimpleProposal() public {
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
  }

  function enfranchise(address user, uint256 amount) public {
    vm.prank(ONDO_WHALE);
    ONDO_TOKEN.transfer(user, amount);
    vm.prank(user);
    ONDO_TOKEN.delegate(user);
    vm.roll(block.number + 2);
  }
}
