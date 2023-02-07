// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-tests/lending/DeployBasicLendingMarket.t.sol";

contract Test_Lending_Market_Account_Liquidity is BasicLendingMarket {
  /// @dev DAI is not used as collateral in the production deployment,
  ///      but we are testing account liquidity using DAI here.
  function setUp() public override {
    super.setUp();
    oComptroller._setCollateralFactor(address(fDAI), 75 * 1e16);
  }

  function test_getHypotheticalAccountLiquidity_market_not_entered() public {
    (, uint256 accountLiquidity, uint256 shortFall) = oComptroller
      .getHypotheticalAccountLiquidity(charlie, address(fDAI), 1000e18, 500e18);
    assertEq(0, accountLiquidity);
    assertEq(0, shortFall);
  }

  function test_supplyRatePerBlock_on_init_fDAI() public {
    enterMarkets(charlie, address(fDAI), 100e18);
    uint256 supplyRateUSDC = fDAI.supplyRatePerBlock();
    assertEq(supplyRateUSDC, 0);
  }

  function test_supplyRatePerBlock_on_init_fCASH() public {
    enterMarkets(charlie, address(fUSDC), 100e6);
    uint256 supplyRateCash = fUSDC.supplyRatePerBlock();
    assertEq(supplyRateCash, 0);
  }

  function test_getAccountLiquidity_market_not_entered() public {
    (, uint256 liquidity, uint256 shortfall) = oComptroller.getAccountLiquidity(
      charlie
    );
    assertEq(liquidity, 0);
    assertEq(shortfall, 0);
  }

  function test_supplyRatePerBlock_withBorrows_dai() public {
    _addAddressToKYC(kycRequirementGroup, charlie);
    enterMarkets(charlie, address(fDAI), 1000e18);
    vm.prank(charlie);
    fDAI.borrow(500e18);
    uint256 daiBorrowed = DAI.balanceOf(charlie);
    assertEq(daiBorrowed, 500e18);
    uint256 supplyRateUsdc = fDAI.supplyRatePerBlock();
    assertGt(supplyRateUsdc, 0);
  }

  function test_fuzz_total_account_liquidity_after_supplying_amount(
    uint256 amount
  ) public {
    vm.assume(amount <= DAI.balanceOf(DAI_WHALE) - 1e18);
    amount += 1e18; // Avoid very small amounts
    enterMarkets(charlie, address(fDAI), amount);

    uint256 scaledLiquidity = _getScaledLiquidity(address(fDAI), amount);
    (, uint256 liquidity, ) = oComptroller.getAccountLiquidity(charlie);
    assertAlmostEq(scaledLiquidity, liquidity, 5);
  }

  function test_fuzz_borrow_mint_amount_should_shortfall(
    uint256 amount
  ) public {
    test_fuzz_total_account_liquidity_after_supplying_amount(amount);
    amount += 1e18;
    (, uint256 liquidity, uint256 shortfall) = oComptroller
      .getHypotheticalAccountLiquidity(charlie, address(fDAI), 0, amount);

    (, uint256 collateralFactor) = oComptroller.markets(address(fDAI));
    uint256 scaledLiqidity = _getScaledLiquidity(address(fDAI), amount);

    // CollateralFactor = 75e18, which gives us 25e18 in leftover liquidity
    // 75e18/(1e18 - 75e18) = 3 (3x the amount of leftover)
    // NOTE: Math below only works if collateralFactor > 50%
    uint256 liquidityDivisor = collateralFactor / (1e18 - collateralFactor);
    uint256 scaledShortfall = scaledLiqidity / liquidityDivisor;
    assertEq(liquidity, 0);
    assertAlmostEq(shortfall, scaledShortfall, 5);
  }

  function test_fuzz_redeem_total_liquidity_should_be_0(uint256 amount) public {
    test_fuzz_total_account_liquidity_after_supplying_amount(amount);
    (, uint256 liquidity, uint256 shortfall) = oComptroller
      .getHypotheticalAccountLiquidity(
        charlie,
        address(fDAI),
        fDAI.balanceOf(charlie),
        0
      );
    assertEq(liquidity, 0);
    assertEq(shortfall, 0);
  }

  /// @dev Assumed 18 decimals underlying
  function _getScaledLiquidity(
    address oToken,
    uint256 amount
  ) internal returns (uint256) {
    uint256 price = ondoOracle.getUnderlyingPrice(oToken);
    (, uint256 collateralFactor) = oComptroller.markets(oToken);
    uint256 scaledLiquidityWithCF = (amount * collateralFactor) / 1e18;
    uint256 scaledLiquidityWithPrice = (scaledLiquidityWithCF * price) / 1e18;
    return scaledLiquidityWithPrice;
  }
}
