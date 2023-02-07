// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-tests/lending/DeployBasicLendingMarket.t.sol";

/*//////////////////////////////////////////////////////////////
    Compound Tests: tests/Comptroller/comptrollerTest.js
//////////////////////////////////////////////////////////////*/

contract Test_Comptroller is BasicLendingMarket {
  function test_admin() public {
    address admin = oComptroller.admin();
    assertEq(admin, address(this));
  }

  function test_closeFactorMantissa() public {
    uint256 closeFactor = oComptroller.closeFactorMantissa();
    assertEq(closeFactor, 0.5e18);
  }

  function test_setLiquidationIncentive_access_control() public {
    vm.startPrank(alice);
    _expectFail(
      ComptrollerErrorReporter.Error.UNAUTHORIZED,
      ComptrollerErrorReporter.FailureInfo.SET_LIQUIDATION_INCENTIVE_OWNER_CHECK
    );
    uint256 reply = oComptroller._setLiquidationIncentive(1.3e18);
    assertEq(reply, 1); // Assert that the call returns UNAUTHORIZED
    uint256 incentive = oComptroller.liquidationIncentiveMantissa();
    assertEq(incentive, 1.05e18); // Assert that the incentive has not changed.
  }

  function test_setLiquidationIncentive() public {
    vm.expectEmit(true, true, true, true);
    emit NewLiquidationIncentive(1.05e18, 1.3e18);
    uint256 reply = oComptroller._setLiquidationIncentive(1.3e18);
    assertEq(reply, 0);
    uint256 incentive = oComptroller.liquidationIncentiveMantissa();
    assertEq(incentive, 1.3e18);
  }

  function test_setPriceOracle_access_control() public {
    vm.startPrank(alice);
    _expectFail(
      ComptrollerErrorReporter.Error.UNAUTHORIZED,
      ComptrollerErrorReporter.FailureInfo.SET_PRICE_ORACLE_OWNER_CHECK
    );
    uint256 reply = oComptroller._setPriceOracle(address(420));
    assertEq(reply, 1);
    address oracle = oComptroller.oracle();
    assertEq(oracle, address(ondoOracle));
  }

  function test_setPriceOracle() public {
    vm.expectEmit(true, true, true, true);
    emit NewPriceOracle(address(ondoOracle), address(oComptroller));
    uint256 reply = oComptroller._setPriceOracle(address(oComptroller));
    address oracle = oComptroller.oracle();
    assertEq(reply, 0); // Assert that there was no error w/ call
    assertEq(oracle, address(oComptroller));
  }

  function test_setCollateralFactor_access_control() public {
    vm.startPrank(alice);
    _expectFail(
      ComptrollerErrorReporter.Error.UNAUTHORIZED,
      ComptrollerErrorReporter.FailureInfo.SET_COLLATERAL_FACTOR_OWNER_CHECK
    );
    uint256 reply = oComptroller._setCollateralFactor(address(fCASH), 1e18);
    assertEq(reply, 1);
  }

  function test_setBorrowPaused() public {
    bool result = oComptroller._setBorrowPaused(address(fUSDC), true);
    assertEq(result, true); // Assert that the lending market has paused borrows
  }

  function test_setCollateralFactor_to_max() public {
    vm.expectEmit(true, true, true, true);
    emit NewCollateralFactor(address(fUSDC), .85e18, .98e18);
    uint256 result = oComptroller._setCollateralFactor(address(fUSDC), .98e18);
    assertEq(result, 0); // Assert no error was thrown
  }

  function test_setCollateralFactor_fail_max_exceeded() public {
    _expectFail(
      ComptrollerErrorReporter.Error.INVALID_COLLATERAL_FACTOR,
      ComptrollerErrorReporter.FailureInfo.SET_COLLATERAL_FACTOR_VALIDATION
    );
    oComptroller._setCollateralFactor(address(fUSDC), .99e18);
  }

  function test_borrow_fail_paused() public {
    oComptroller._setBorrowPaused(address(fUSDC), true);
    _addAddressToKYC(kycRequirementGroup, charlie);
    enterMarkets(charlie, address(fDAI), 100e18);
    _addAddressToKYC(kycRequirementGroup, alice);
    enterMarkets(alice, address(fUSDC), 100e6);
    vm.prank(charlie);
    vm.expectRevert("borrow is paused");
    fUSDC.borrow(1e18);
  }

  function test_setCollateralFactor_fail_asset_not_listed() public {
    _expectFail(
      ComptrollerErrorReporter.Error.MARKET_NOT_LISTED,
      ComptrollerErrorReporter.FailureInfo.SET_COLLATERAL_FACTOR_NO_EXISTS
    );
    uint256 reply = oComptroller._setCollateralFactor(address(USDC), 1e18);
    assertEq(reply, 9);
  }

  function test_setCollateralFactor_fail_no_underlying_price() public {
    IOndoOracle mockOracle = IOndoOracle(
      deployCode(
        "MockPriceOracle.sol:MockPriceOracle",
        abi.encode(address(fUSDC))
      )
    );
    mockOracle.setPrice(address(fUSDC), 0);
    mockOracle.setPrice(address(fDAI), 1000027000000000000);
    oComptroller._setPriceOracle(address(mockOracle));
    _expectFail(
      ComptrollerErrorReporter.Error.PRICE_ERROR,
      ComptrollerErrorReporter.FailureInfo.SET_COLLATERAL_FACTOR_WITHOUT_PRICE
    );
    oComptroller._setCollateralFactor(address(fUSDC), 0.75e18);
  }

  function test_setCollateralFactor() public {
    vm.expectEmit(true, true, true, true);
    emit NewCollateralFactor(address(fUSDC), 0.85e18, 0.92e18);
    uint256 reply = oComptroller._setCollateralFactor(address(fUSDC), 0.92e18);
    assertEq(reply, 0);
    (, uint collateralFactorMantissa) = oComptroller.markets(address(fUSDC));
    assertEq(collateralFactorMantissa, 0.92e18);
  }

  function test_supportMarket_access_control() public {
    vm.startPrank(alice);
    _expectFail(
      ComptrollerErrorReporter.Error.UNAUTHORIZED,
      ComptrollerErrorReporter.FailureInfo.SUPPORT_MARKET_OWNER_CHECK
    );
    uint256 reply = oComptroller._supportMarket(address(USDC));
    assertEq(reply, 1);
  }

  function test_supportMarket_fail_asset_not_cToken() public {
    vm.expectRevert();
    oComptroller._supportMarket(address(USDC));
  }

  function test_supportMarket_fail_redundant_call() public {
    _expectFail(
      ComptrollerErrorReporter.Error.MARKET_ALREADY_LISTED,
      ComptrollerErrorReporter.FailureInfo.SUPPORT_MARKET_EXISTS
    );
    oComptroller._supportMarket(address(fDAI));
  }

  event NewCollateralFactor(
    address oToken,
    uint256 oldCollateralFactorMantissa,
    uint256 newLiquidationIncentiveMantissa
  );
  event NewLiquidationIncentive(
    uint256 oldLiquidationIncentiveMantissa,
    uint256 newLiquidationIncentiveMantissa
  );
  event NewPriceOracle(address oldOracle, address newOracle);
  event MarketListed(address oToken);
}
