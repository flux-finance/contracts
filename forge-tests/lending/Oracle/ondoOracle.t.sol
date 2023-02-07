pragma solidity 0.8.16;

import "forge-tests/lending/DeployBasicLendingMarket.t.sol";

contract Test_Oracle_V1 is TestOndoOracleEvents, BasicLendingMarket {
  address usdtAddr = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

  function test_oracle_has_owner() public {
    assertEq(ondoOracle.owner(), address(this));
  }

  function test_oracle_admin_canTransferOwnership() public {
    ondoOracle.transferOwnership(charlie);
    vm.startPrank(charlie);
    ondoOracle.acceptOwnership();
    assertEq(ondoOracle.owner(), charlie);
  }

  function test_oracle_getUnderlyingPrice_fail_unregisteredToken() public {
    // Revert stems from Compound's oracle, which doesn't support usdt.
    vm.expectRevert("Not found");
    ondoOracle.getUnderlyingPrice(usdtAddr);
  }

  function test_getUnderlyingPrice_manualPricePrecedent() public {
    assertEq(ondoOracle.fTokenToCToken(address(fDAI)), address(cDAI));
    ondoOracle.setPrice(address(fDAI), 1.1e18);
    uint256 oraclePriceUnderlying_fDAI = ondoOracle.getUnderlyingPrice(
      address(fDAI)
    );
    assertEq(oraclePriceUnderlying_fDAI, 1.1e18);
  }

  function test_returnCorrectPrice_fDAI() public {
    uint256 oraclePriceUnderlying_fDAI = ondoOracle.getUnderlyingPrice(
      address(fDAI)
    );
    assertAlmostEqBps(oraclePriceUnderlying_fDAI, 1e18, 100);
  }

  function test_setPrice_fail_nonAdmin() public {
    vm.startPrank(alice);
    vm.expectRevert(bytes("Only callable by owner"));
    ondoOracle.setPrice(address(fCASH), 1100000000000000000);
  }

  function test_setPrice() public {
    vm.expectEmit(true, true, true, true);
    emit UnderlyingPriceSet(address(fDAI), 0, 110e18);
    ondoOracle.setPrice(address(fDAI), 110e18);
    assertEq(ondoOracle.fTokenToUnderlyingPrice(address(fDAI)), 110e18);
    uint256 result = ondoOracle.getUnderlyingPrice(address(fDAI));
    assertEq(result, 110e18);
  }

  function test_setFTokenToCToken_fail_nonAdmin() public {
    vm.startPrank(alice);
    vm.expectRevert(bytes("Only callable by owner"));
    ondoOracle.setFTokenToCToken(address(fDAI), address(cDAI));
  }

  function test_setFTokenToCToken_fail_diffUnderlying() public {
    vm.expectRevert(
      "cToken and fToken must have the same underlying asset if cToken nonzero"
    );
    // fDAI and cLink have different underlying asset
    ondoOracle.setFTokenToCToken(
      address(fDAI),
      address(0xFAce851a4921ce59e912d19329929CE6da6EB0c7)
    );
  }

  function test_setFTokenToCToken() public {
    vm.expectEmit(true, true, true, true);
    emit FTokenToCTokenSet(address(fDAI), address(cDAI), address(cDAI));
    ondoOracle.setFTokenToCToken(address(fDAI), address(cDAI));
    assertEq(ondoOracle.fTokenToCToken(address(fDAI)), address(cDAI));
  }

  function test_setOracle_fail_nonAdmin() public {
    vm.startPrank(alice);
    vm.expectRevert(bytes("Only callable by owner"));
    ondoOracle.setOracle(address(0));
  }

  function test_setOracle() public {
    vm.expectEmit(true, true, true, true);
    emit CTokenOracleSet(
      address(0x50ce56A3239671Ab62f185704Caedf626352741e),
      address(0)
    );
    ondoOracle.setOracle(address(0));
  }
}
