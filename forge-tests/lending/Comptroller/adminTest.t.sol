// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-tests/lending/DeployBasicLendingMarket.t.sol";

/*//////////////////////////////////////////////////////////////
        Compound Tests: tests/Comptroller/adminTest.js
//////////////////////////////////////////////////////////////*/

contract Test_Comptroller_Admin is BasicLendingMarket {
  function test_admin() public {
    address result = oComptroller.admin();
    assertEq(result, address(this));
  }

  function test_pendingAdmin() public {
    address result = oComptroller.pendingAdmin();
    assertEq(result, address(0));
  }

  function test_setPendingAdmin_access_control() public {
    vm.startPrank(alice);
    _expectFail(
      ComptrollerErrorReporter.Error.UNAUTHORIZED,
      ComptrollerErrorReporter.FailureInfo.SET_PENDING_ADMIN_OWNER_CHECK
    );
    uint256 result = oComptroller._setPendingAdmin(alice);
    assertEq(result, 1); // Assert that the call is UNAUTHORIZED
    address pendingAdmin = oComptroller.pendingAdmin();
    assertEq(pendingAdmin, address(0));
  }

  function test_setPendingAdmin() public {
    vm.expectEmit(true, true, true, true);
    emit NewPendingAdmin(address(0), charlie);
    oComptroller._setPendingAdmin(charlie);
    address admin = oComptroller.admin();
    address pendingAdmin = oComptroller.pendingAdmin();
    assertEq(admin, address(this));
    assertEq(pendingAdmin, charlie);
  }

  function test_setPendingAdmin_overwrite() public {
    oComptroller._setPendingAdmin(charlie);
    oComptroller._setPendingAdmin(bob);
    address admin = oComptroller.admin();
    address pendingAdmin = oComptroller.pendingAdmin();
    assertEq(admin, address(this));
    assertEq(pendingAdmin, bob);
  }

  function test_acceptAdmin_fail_not_set() public {
    vm.startPrank(alice);
    _expectFail(
      ComptrollerErrorReporter.Error.UNAUTHORIZED,
      ComptrollerErrorReporter.FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK
    );
    uint256 result = oComptroller._acceptAdmin();
    address admin = oComptroller.admin();
    assertEq(result, 1); // Assert that the call is UNAUTHORIZED
    assertEq(admin, address(this));
  }

  function test_acceptAdmin_access_control() public {
    oComptroller._setPendingAdmin(alice);
    vm.startPrank(bob);
    _expectFail(
      ComptrollerErrorReporter.Error.UNAUTHORIZED,
      ComptrollerErrorReporter.FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK
    );
    uint256 result = oComptroller._acceptAdmin();
    address admin = oComptroller.admin();
    assertEq(result, 1); // Assert that the call is UNAUTHORIZED
    assertEq(admin, address(this));
  }

  function test_acceptAdmin() public {
    oComptroller._setPendingAdmin(bob);
    vm.prank(bob);
    vm.expectEmit(true, true, true, true);
    emit NewAdmin(address(this), bob);
    uint256 result = oComptroller._acceptAdmin();
    address admin = oComptroller.admin();
    assertEq(result, 0);
    assertEq(admin, bob);
  }

  event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
  event NewAdmin(address oldAdmin, address newAdmin);
}
