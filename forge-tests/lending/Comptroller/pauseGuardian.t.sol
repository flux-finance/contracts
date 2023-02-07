// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-tests/lending/DeployBasicLendingMarket.t.sol";

/*//////////////////////////////////////////////////////////////
  Compound Tests: tests/Comptroller/pauseGuardianTest.js
//////////////////////////////////////////////////////////////*/

contract Test_Lending_Market_Seize_Token_Amount is BasicLendingMarket {
  function test_setPauseGuardian_fail_access_control() public {
    vm.startPrank(alice);
    _expectFail(
      ComptrollerErrorReporter.Error.UNAUTHORIZED,
      ComptrollerErrorReporter.FailureInfo.SET_PAUSE_GUARDIAN_OWNER_CHECK
    );
    uint256 reply = oComptroller._setPauseGuardian(alice);
    address pasueGuardian = oComptroller.pauseGuardian();
    assertEq(reply, 1);
    assertEq(pasueGuardian, address(0));
  }

  function test_setPauseGuardian() public {
    vm.expectEmit(true, true, true, true);
    emit NewPauseGuardian(address(0), alice);
    uint256 reply = oComptroller._setPauseGuardian(alice);
    address pauseGuardian = oComptroller.pauseGuardian();
    assertEq(reply, 0);
    assertEq(pauseGuardian, alice);
  }

  function test_pauseGuardian() public {
    oComptroller._setPauseGuardian(alice);
    enterMarkets(charlie, address(fCASH), 100e18);

    vm.startPrank(alice);
    vm.expectEmit(true, true, true, true);
    emit ActionPaused("Transfer", true);
    bool reply = oComptroller._setTransferPaused(true);
    assertEq(reply, true);

    vm.expectRevert(bytes("only admin can unpause"));
    oComptroller._setTransferPaused(false);
    vm.stopPrank();

    vm.prank(charlie);
    vm.expectRevert(bytes("transfer is paused"));
    fCASH.transfer(bob, 100e8);

    oComptroller._setTransferPaused(false);
    vm.prank(charlie);
    fCASH.transfer(bob, 100e8);
    uint256 bobBal = fCASH.balanceOf(bob);
  }

  function test_pauseGuardian_can_pause_seizures() public {
    oComptroller._setPauseGuardian(alice);

    vm.startPrank(alice);
    vm.expectEmit(true, true, true, true);
    emit ActionPaused("Seize", true);
    bool reply = oComptroller._setSeizePaused(true);
    assertEq(reply, true);

    vm.expectRevert(bytes("only admin can unpause"));
    oComptroller._setSeizePaused(false);
    vm.stopPrank();

    vm.expectRevert(bytes("seize is paused"));
    oComptroller.seizeAllowed(
      address(fCASH),
      address(fDAI),
      address(this),
      address(alice),
      100e6
    );
  }

  function test_pauseGuardian_can_pause_mint() public {
    oComptroller._setPauseGuardian(alice);

    vm.startPrank(alice);
    vm.expectEmit(true, true, true, true);
    emit ActionPaused(address(fCASH), "Mint", true);
    oComptroller._setMintPaused(address(fCASH), true);

    vm.expectRevert(bytes("only admin can unpause"));
    oComptroller._setMintPaused(address(fCASH), false);
    vm.stopPrank();

    vm.expectRevert(bytes("mint is paused"));
    oComptroller.mintAllowed(address(fCASH), address(alice), 100e18);
  }

  function test_pauseGuardian_can_pause_borrows() public {
    oComptroller._setPauseGuardian(alice);

    vm.startPrank(alice);
    vm.expectEmit(true, true, true, true);
    emit ActionPaused(address(fCASH), "Borrow", true);
    bool reply = oComptroller._setBorrowPaused(address(fCASH), true);
    assertEq(reply, true);

    vm.expectRevert(bytes("only admin can unpause"));
    oComptroller._setMintPaused(address(fCASH), false);
    vm.stopPrank();

    vm.expectRevert(bytes("borrow is paused"));
    oComptroller.borrowAllowed(address(fCASH), bob, 10e6);
  }

  event NewPauseGuardian(address oldPauseGuardian, address pauseGuardian);
  event ActionPaused(string action, bool pauseState);
  event ActionPaused(address oToken, string action, bool pauseState);
}
