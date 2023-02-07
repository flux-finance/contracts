pragma solidity 0.8.16;

import "forge-tests/lending/DeployBasicLendingMarket.t.sol";

contract Test_IRModel is BasicLendingMarket {
  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);
  event NewInterestParams(
    uint baseRatePerBlock,
    uint multiplierPerBlock,
    uint jumpMultiplierPerBlock,
    uint kink
  );

  function test_owner() public {
    assertEq(interestRateModel.owner(), address(this));
  }

  function test_transferOwnership() public {
    // Transfer Ownership
    vm.expectEmit(true, true, true, true);
    emit OwnershipTransferRequested(address(this), charlie);
    interestRateModel.transferOwnership(charlie);

    // Accept Transfer
    vm.startPrank(charlie);
    vm.expectEmit(true, true, true, true);
    emit OwnershipTransferred(address(this), charlie);
    interestRateModel.acceptOwnership();
    assertEq(interestRateModel.owner(), charlie);
  }

  function test_transferOwnership_fail_invalidAccept() public {
    interestRateModel.transferOwnership(alice);

    // Revert on accepting from non-pending owner
    vm.startPrank(charlie);
    vm.expectRevert("Must be proposed owner");
    interestRateModel.acceptOwnership();
  }

  function test_updateJumpRateModel() public {
    uint256 multiplierPerYear = 0.04e18;
    uint256 jumpMultiplierPerYear = 0.4e18;
    uint256 kink = 0.9e18;
    uint256 multiplierPerBlock = (multiplierPerYear * 1e18) / (2628000 * kink);
    uint256 jumpMultiplierPerBlock = (jumpMultiplierPerYear) / (2628000);
    vm.expectEmit(true, true, true, true);
    emit NewInterestParams(0, multiplierPerBlock, jumpMultiplierPerBlock, kink);
    interestRateModel.updateJumpRateModel(
      0,
      multiplierPerYear,
      jumpMultiplierPerYear,
      kink
    );
  }

  function test_updateJumpRateModel_fail_notOwner() public {
    vm.startPrank(charlie);
    vm.expectRevert("Only callable by owner");
    interestRateModel.updateJumpRateModel(0, 0.04e18, 0.4e18, 0.9e18);
  }
}
