pragma solidity 0.8.16;

import "forge-tests/lending/Production/Proposals/baseDao.sol";
import "contracts/lending/GovernerAlpha.sol";
import "forge-std/console.sol";

contract Test_Prod_DAO_SetPendingAdmin is BaseDAO {
  // Block Fork: 16386578
  address initialAdmin = 0x118919e891D0205A7492650AD32E727617FA9452;
  uint256 eta = 1673603617;
  uint256 proposalId;
  GovernerAlpha mockAlpha;

  function setUp() public override {
    super.setUp();
    mockAlpha = new GovernerAlpha(1);
  }

  function test_queue_setPendingAdmin() public {
    vm.prank(initialAdmin);
    timelock.queueTransaction(
      address(timelock),
      0,
      "setPendingAdmin(address)",
      abi.encode(address(dao)),
      1673603617
    );
  }

  function test_execute_setPendingAdmin() public {
    assertEq(timelock.pendingAdmin(), address(0));
    test_queue_setPendingAdmin();
    vm.warp(eta + 1);
    vm.prank(initialAdmin);
    timelock.executeTransaction(
      address(timelock),
      0,
      "setPendingAdmin(address)",
      abi.encode(address(dao)),
      1673603617
    );
    assertEq(timelock.pendingAdmin(), address(dao));
  }

  function test_queue_initiate() public {
    vm.prank(initialAdmin);
    timelock.queueTransaction(
      address(dao),
      0,
      "_initiate(address)",
      abi.encode(address(mockAlpha)),
      1673603617
    );
  }

  function test_execute_initiate() public {
    test_queue_initiate();
    test_execute_setPendingAdmin();
    vm.prank(initialAdmin);
    timelock.executeTransaction(
      address(dao),
      0,
      "_initiate(address)",
      abi.encode(address(mockAlpha)),
      1673603617
    );
    assertEq(timelock.admin(), address(dao));
    assertEq(dao.proposalCount(), 1);
  }

  function test_DAO_propose() public {
    test_execute_initiate();
    // Seed  DAO contract with some USDC to then transfer out
    vm.prank(USDC_WHALE);
    USDC.transfer(address(timelock), 1000e6);
    assertEq(USDC.balanceOf(address(timelock)), 1000e6);
    // Setup Params
    targets.push(address(USDC));
    values.push(0);
    signatures.push("transfer(address,uint256)");
    calldatas.push(abi.encode(address(this), 1000e6));
    // Propose
    proposalId = dao.propose(
      targets,
      values,
      signatures,
      calldatas,
      "Transfer 1000 USDC from Timelock to Test Runner"
    );
  }

  function test_DAO_voteAndExecute() public {
    test_DAO_propose();
    // Vote
    vm.roll(block.number + 10);
    dao.castVote(proposalId, 1);
    // Roll Past Voting Period
    vm.roll(block.number + dao.votingPeriod());
    // Queue
    dao.queue(proposalId);
    // Warp past timelock and Execute
    vm.warp(block.timestamp + timelock.delay());
    dao.execute(proposalId);
    // Post tx checks
    assertEq(USDC.balanceOf(address(this)), 1000e6);
    assertEq(USDC.balanceOf(address(timelock)), 0);
  }
}
