pragma solidity 0.8.16;

import "forge-tests/lending/DeployBasicLendingMarket.t.sol";

contract Test_Lending_Additional_Auth_Specs is BasicLendingMarket {
  function test_borrow_at_98PointLTV() public {
    seedDaiPool();
    oComptroller._setCollateralFactor(address(fCASH), .98e18);
    enterMarkets(charlie, address(fCASH), 1e18);
    vm.startPrank(charlie);
    (uint err, uint liq, uint short) = oComptroller.getAccountLiquidity(
      charlie
    );
    console.log(err, liq, short);
    fDAI.borrow(98e18);
    vm.stopPrank();
    uint256 balDaiCharlie = DAI.balanceOf(charlie);
    assertEq(98e18, balDaiCharlie);
  }

  function test_liquidate_at_98LTV() public {
    test_borrow_at_98PointLTV();
    vm.roll(block.timestamp + 10000);
    fDAI.accrueInterest();
    console.log("Account snapshot before liquidation");
    (uint err, uint liq, uint short) = oComptroller.getAccountLiquidity(
      charlie
    );
    console.log(err, liq, short);
    assertGt(short, 0);
    _addAddressToKYC(kycRequirementGroup, address(DAI_WHALE));
    vm.startPrank(DAI_WHALE);
    DAI.approve(address(fDAI), 49e18);
    fDAI.liquidateBorrow(charlie, 49e18, CTokenInterface(fCASH));
    console.log(fCASH.balanceOfUnderlying(DAI_WHALE));

    (uint err_, uint liq_, uint shortAfterLiq) = oComptroller
      .getAccountLiquidity(charlie);
    console.log("Account snapshot after liquidation");
    console.log(err_, liq_, shortAfterLiq);
    assertGt(shortAfterLiq, short); // Assert that the shortfall increases w/ liquidation
  }

  function test_liq_at_90LTV() public {
    vm.expectEmit(true, true, true, true);
    emit NewCollateralFactor(address(fCASH), .92e18, .90e18);
    uint256 result = oComptroller._setCollateralFactor(address(fCASH), .90e18);
    assertEq(result, 0); // Assert no error was thrown

    seedDaiPool();
    enterMarkets(charlie, address(fCASH), 1e18);
    vm.startPrank(charlie);

    fDAI.borrow(90e18);
    vm.stopPrank();
    uint256 balDaiCharlie = DAI.balanceOf(charlie);
    assertEq(90e18, balDaiCharlie);

    vm.roll(block.timestamp + 10000);
    fDAI.accrueInterest();
    console.log("Account Snapshot before liquidation");
    (uint err, uint liq, uint short) = oComptroller.getAccountLiquidity(
      charlie
    );
    console.log(err, liq, short);
    assertGt(short, 0);
    _addAddressToKYC(kycRequirementGroup, address(DAI_WHALE));
    vm.startPrank(DAI_WHALE);
    DAI.approve(address(fDAI), 49e18);
    fDAI.liquidateBorrow(charlie, 49e18, CTokenInterface(fCASH));
    console.log(fCASH.balanceOfUnderlying(DAI_WHALE));

    (uint err_, uint liq_, uint shortAfterLiq) = oComptroller
      .getAccountLiquidity(charlie);
    console.log("Account snapshot after liquidation");
    console.log(err_, liq_, shortAfterLiq);
    assertLt(shortAfterLiq, short); // Assert that the shortfall decreases as a result of the liquidation
  }

  function test_liq_at_91LTV() public {
    oComptroller._setLiquidationIncentive(1.1e18);
    vm.expectEmit(true, true, true, true);
    emit NewCollateralFactor(address(fCASH), .92e18, .91e18);
    uint256 result = oComptroller._setCollateralFactor(address(fCASH), .91e18);
    assertEq(result, 0); // Assert no error was thrown

    seedDaiPool();
    enterMarkets(charlie, address(fCASH), 1e18);
    vm.startPrank(charlie);

    fDAI.borrow(90e18);
    vm.stopPrank();
    uint256 balDaiCharlie = DAI.balanceOf(charlie);
    assertEq(90e18, balDaiCharlie);

    vm.roll(block.timestamp + 10000);
    fDAI.accrueInterest();
    (uint err, uint liq, uint short) = oComptroller.getAccountLiquidity(
      charlie
    );
    console.log("Account snapshot before liquidation");
    console.log(err, liq, short);
    assertGt(short, 0);
    _addAddressToKYC(kycRequirementGroup, address(DAI_WHALE));
    vm.startPrank(DAI_WHALE);
    DAI.approve(address(fDAI), 49e18);
    fDAI.liquidateBorrow(charlie, 49e18, CTokenInterface(fCASH));
    console.log(fCASH.balanceOfUnderlying(DAI_WHALE));

    (uint err_, uint liq_, uint shortAfterLiq) = oComptroller
      .getAccountLiquidity(charlie);
    console.log("Account snapshot after liquidation");
    console.log(err_, liq_, shortAfterLiq);
    assertGt(shortAfterLiq, short); // Assert that the account shortfall is gt post liq
  }

  function seedDaiPool() public {
    vm.startPrank(DAI_WHALE);
    DAI.approve(address(fDAI), 5000e18);
    fDAI.mint(5000e18);
    vm.stopPrank();
  }

  event NewCollateralFactor(
    address oToken,
    uint256 oldCollateralFactorMantissa,
    uint256 newLiquidationIncentiveMantissa
  );
}
