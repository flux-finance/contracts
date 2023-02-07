pragma solidity 0.8.16;

import "forge-tests/lending/DeployBasicLendingMarket.t.sol";

contract Test_Lending_Market_Interest_Accrual is BasicLendingMarket {
  function setUp() public override {
    /// @dev DAI is not used as collateral in the production deployment, but we are testing account liquidity using DAI here
    super.setUp();
    oComptroller._setCollateralFactor(address(fDAI), 75 * 1e16);
  }

  function test_interest_accrues_to_supplier() public {
    _addAddressToKYC(kycRequirementGroup, charlie);
    enterMarkets(charlie, address(fDAI), 100_000_000e18);
    vm.prank(charlie);
    fDAI.borrow(100e18);

    uint256 util = getExpectedUtilizationRate(
      100e18,
      fDAI.getCash(),
      fDAI.totalReserves()
    );

    uint256 borrowRate = getExpectedBorrowRate(
      util,
      interestRateModel.kink(),
      interestRateModel.multiplierPerBlock(),
      interestRateModel.jumpMultiplierPerBlock(),
      interestRateModel.baseRatePerBlock()
    );
    console.log(borrowRate);
    console.log(fDAI.reserveFactorMantissa());

    console.log("The calculated supply rate is");
    uint256 supplyRate = getSupplyRateCheck(util, borrowRate, 0);
    console.log(supplyRate);
    console.log("The borrow bal current", fDAI.borrowBalanceCurrent(charlie));
    vm.roll(block.number + 2102400);
    console.log("The borrow bal current", fDAI.borrowBalanceCurrent(charlie));
    console.log(getBorrowedAmount(100e18, borrowRate, 2102400));
  }

  function test_fuzz_supply_interest_accrual(
    uint256 supplyAmount,
    uint256 blocks
  ) public {
    vm.assume(supplyAmount < 200_000_000e18);
    vm.assume(blocks < 2102400 * 6);
    supplyAmount += 50e18;
    _addAddressToKYC(kycRequirementGroup, charlie);
    enterMarkets(charlie, address(fDAI), supplyAmount);
    vm.prank(charlie);
    fDAI.borrow(10e18);

    uint256 util = getExpectedUtilizationRate(
      10e18,
      fDAI.getCash(),
      fDAI.totalReserves()
    );
    uint256 borrowRate = getExpectedBorrowRate(
      util,
      interestRateModel.kink(),
      interestRateModel.multiplierPerBlock(),
      interestRateModel.jumpMultiplierPerBlock(),
      interestRateModel.baseRatePerBlock()
    );
    uint256 supplyRate = getSupplyRateCheck(util, borrowRate, 0);

    vm.roll(block.number + blocks);
    console.log(fDAI.balanceOfUnderlying(charlie));
    console.log(getSupplyAmount(supplyAmount, supplyRate, blocks));

    assertAlmostEq(
      fDAI.balanceOfUnderlying(charlie),
      getSupplyAmount(supplyAmount, supplyRate, blocks),
      5e16
    );
  }

  function test_fuzz_borrow_interest_accrual(
    uint256 borrowAmount,
    uint256 blocks
  ) public {
    vm.assume(borrowAmount < 70_000_000e18);
    vm.assume(blocks < 2102400 * 8);
    borrowAmount += 1e18;
    _addAddressToKYC(kycRequirementGroup, charlie);

    enterMarkets(charlie, address(fDAI), 100_000_000e18);

    vm.prank(charlie);
    fDAI.borrow(borrowAmount);

    uint256 util = getExpectedUtilizationRate(
      borrowAmount,
      fDAI.getCash(),
      fDAI.totalReserves()
    );
    uint256 borrowRate = getExpectedBorrowRate(
      util,
      interestRateModel.kink(),
      interestRateModel.multiplierPerBlock(),
      interestRateModel.jumpMultiplierPerBlock(),
      interestRateModel.baseRatePerBlock()
    );

    vm.roll(block.number + blocks);

    assertEq(
      fDAI.borrowBalanceCurrent(charlie),
      getBorrowedAmount(borrowAmount, borrowRate, blocks)
    );
  }

  function test_initial_rate_is_0() public {
    _addAddressToKYC(kycRequirementGroup, charlie);
    enterMarkets(charlie, address(fDAI), 1000e18);
    vm.prank(charlie);
    fDAI.borrow(100e18);
  }
}
