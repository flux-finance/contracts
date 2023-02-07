pragma solidity 0.8.16;

import "contracts/lending/tokens/cErc20Delegate/ErrorReporter.sol";
import "forge-tests/lending/fToken/fToken.base.t.sol";
import "contracts/lending/IOndoPriceOracleV2.sol";

/// @notice fToken tests for fTokens that inherit from cTokenModified
///         and can be used as collateral
/// @dev CollateralFactor for fTokens that inherit this testing suite
///      should be 0
abstract contract Test_fTokenNonCollateral is Test_fToken_Basic {
  using SafeERC20 for IERC20;

  // Sets generic fToken for tests that inherits from
  // contracts/lending/tokens/cToken/CTokenModified.sol
  // and can not be used as collateral
  function _setfToken(address _fToken) internal override {
    super._setfToken(_fToken);
  }

  function test_borrowRatePerBlock_on_init() public {
    // y-intercept is zero on IR model that DAI uses
    uint256 defaultBorrowRate = fToken.borrowRatePerBlock();
    assertEq(defaultBorrowRate, 0);
  }

  // Basic Param Checks
  function test_fToken_protocolSeizeShare() public {
    uint256 protocolSeizeShare = fToken.protocolSeizeShareMantissa();
    assertEq(protocolSeizeShare, 1.75e16);
  }

  function test_fToken_noCollateralFactor() public {
    (, uint collateralFactorMantissa) = oComptroller.markets(address(fToken));
    assertEq(collateralFactorMantissa, 0);
  }

  function test_borrow_fail_not_supported() public {
    _addAddressToKYC(kycRequirementGroup, charlie);
    enterMarkets(charlie, address(fToken), _units(100));
    vm.prank(charlie);
    vm.expectRevert(
      abi.encodeWithSelector(
        TokenErrorReporter.BorrowComptrollerRejection.selector,
        4
      )
    );
    fToken.borrow(_units(50));
  }

  /// fTokenModified Access Control Checks ///
  function test_transfer_fail_sanction_spender() public {
    enterMarkets(charlie, address(fToken), _units(100));
    _addAddressToSanctionsList(charlie);
    vm.expectRevert("Spender is sanctioned");
    vm.prank(charlie);
    fToken.transfer(alice, _units(100));
  }

  function test_transfer_fail_sanction_source() public {
    enterMarkets(charlie, address(fToken), _units(100));
    _addAddressToSanctionsList(charlie);
    fToken.approve(address(this), _units(100));
    vm.expectRevert("Source is sanctioned");
    fToken.transferFrom(charlie, alice, _units(100));
  }

  function test_transfer_fail_sanction_destination() public {
    enterMarkets(charlie, address(fToken), _units(100));
    _addAddressToSanctionsList(alice);
    vm.expectRevert("Destination is sanctioned");
    vm.prank(charlie);
    fToken.transfer(alice, _units(100));
  }

  function test_mint_fail_sanction() public {
    _addAddressToSanctionsList(charlie);
    vm.expectRevert("Minter is sanctioned");
    vm.prank(charlie);
    fToken.mint(_units(100));
  }

  function test_redeem_fail_sanction() public {
    enterMarkets(charlie, address(fToken), _units(100));
    _addAddressToSanctionsList(charlie);
    vm.expectRevert("Redeemer is sanctioned");
    vm.prank(charlie);
    fToken.redeem(_units(100));
  }

  function test_borrow_fail_KYC_cashCollateral() public {
    enterMarkets(charlie, address(fCASH), 100e18);
    seedLendingPool(address(fToken));
    _removeAddressFromKYC(kycRequirementGroup, charlie);
    vm.expectRevert("Borrower not KYC'd");
    vm.prank(charlie);
    fToken.borrow(_units(50));
  }

  function test_borrow_fail_KYC_fTokenUnderlyingCollateral() public {
    enterMarkets(charlie, address(fToken), _units(100));
    vm.expectRevert("Borrower not KYC'd");
    vm.prank(charlie);
    fToken.borrow(_units(50));
  }

  function test_repayBorrow_fail_KYC_cashCollateral() public {
    enterMarkets(charlie, address(fCASH), 100e18);
    seedLendingPool(address(fToken));
    vm.prank(charlie);
    fToken.borrow(_units(50));
    _removeAddressFromKYC(kycRequirementGroup, charlie);
    vm.expectRevert("Payer not KYC'd");
    vm.prank(charlie);
    fToken.repayBorrow(_units(50));
  }

  function test_repayBorrow_fail_KYC_fTokenUnderlyingCollateral() public {
    enterMarkets(charlie, address(fToken), _units(100));
    _addAddressToKYC(kycRequirementGroup, charlie);
    vm.prank(charlie);
    vm.expectRevert(
      abi.encodeWithSelector(
        TokenErrorReporter.BorrowComptrollerRejection.selector,
        4
      )
    );
    fToken.borrow(_units(50));
  }

  function test_repayBorrowBehalf_fail_KYC_payer_cashCollateral() public {
    enterMarkets(charlie, address(fCASH), 100e18);
    seedLendingPool(address(fToken));
    vm.prank(charlie);
    fToken.borrow(_units(50));
    _removeAddressFromKYC(kycRequirementGroup, address(this));
    vm.expectRevert("Payer not KYC'd");
    fToken.repayBorrowBehalf(charlie, _units(50));
  }

  function test_repayBorrowBehalf_fail_KYC_borrower_cashCollateral() public {
    enterMarkets(charlie, address(fCASH), 100e18);
    seedLendingPool(address(fToken));
    _addAddressToKYC(kycRequirementGroup, charlie);
    vm.prank(charlie);
    fToken.borrow(_units(50));
    _removeAddressFromKYC(kycRequirementGroup, charlie);
    vm.expectRevert("Borrower not KYC'd");
    fToken.repayBorrowBehalf(charlie, _units(50));
  }

  function test_repayBorrowBehalf_fail_KYC_payer_fTokenUnderlyingCollateral()
    public
  {
    enterMarkets(charlie, address(fToken), _units(100));
    _addAddressToKYC(kycRequirementGroup, charlie);
    vm.prank(charlie);
    vm.expectRevert();
    fToken.borrow(_units(50));
  }

  function test_repayBorrowBehalf_fail_KYC_borrower_fTokenUnderlyingCollateral()
    public
  {
    enterMarkets(charlie, address(fToken), _units(100));
    _addAddressToKYC(kycRequirementGroup, charlie);
    vm.prank(charlie);
    vm.expectRevert(
      abi.encodeWithSelector(
        TokenErrorReporter.BorrowComptrollerRejection.selector,
        4
      )
    );
    fToken.borrow(_units(50));
  }

  function test_seize_fail_sanction_borrower() public {
    enterMarkets(charlie, address(fToken), _units(100));
    _addAddressToKYC(kycRequirementGroup, charlie);
    vm.prank(charlie);
    vm.expectRevert(
      abi.encodeWithSelector(
        TokenErrorReporter.BorrowComptrollerRejection.selector,
        4
      )
    );
    fToken.borrow(_units(75));
  }

  function test_seize_fail_sanction_liquidator() public {
    enterMarkets(charlie, address(fToken), _units(100));
    _addAddressToKYC(kycRequirementGroup, charlie);
    vm.prank(charlie);
    vm.expectRevert(
      abi.encodeWithSelector(
        TokenErrorReporter.BorrowComptrollerRejection.selector,
        4
      )
    );
    fToken.borrow(_units(75));
  }

  function test_fCASH_seize_fail_KYC_borrower() public {
    enterMarkets(charlie, address(fCASH), 1e18);
    seedLendingPool(address(fToken));
    vm.prank(charlie);
    fToken.borrow(_units(90)); // borrow max collateralFactor
    // Seed the liquidator with some USDC and approve
    vm.prank(getWhale(address(fToken)));
    underlying.safeTransfer(address(this), _units(30));
    underlying.safeApprove(address(fToken), _units(30));
    // Roll blocks to become underwater
    vm.roll(block.number + 1e9);
    // Expect revert on liquidate
    _removeAddressFromKYC(kycRequirementGroup, charlie);
    vm.expectRevert("Borrower not KYC'd");
    fToken.liquidateBorrow(charlie, _units(30), CTokenInterface(fCASH));
  }

  function test_fCASH_seize_fail_KYC_liquidator() public {
    enterMarkets(charlie, address(fCASH), 1e18);
    seedLendingPool(address(fToken));
    vm.prank(charlie);
    fToken.borrow(_units(90));
    // Seed the liquidator with some underlying and approve
    vm.prank(getWhale(address(fToken)));
    underlying.safeTransfer(address(this), _units(30));
    underlying.safeApprove(address(fToken), _units(30));
    // Roll blocks to become underwater
    vm.roll(block.number + 1e9);
    // Expect revert on liquidate
    _removeAddressFromKYC(kycRequirementGroup, address(this));
    vm.expectRevert("Payer not KYC'd"); // Won't have Borrower revert message since call repayBorrowFresh before seize
    fToken.liquidateBorrow(charlie, _units(30), CTokenInterface(fCASH));
  }

  // No-Collateral Token Tests
  function test_noCollateral_noBorrowPower() public {
    enterMarkets(bob, address(fToken), _units(100));
    (, uint liquidity, uint shortfall) = oComptroller.getAccountLiquidity(bob);
    uint256 fTokenBal = fToken.balanceOf(bob);
    assertEq(liquidity, 0);
    assertGt(fTokenBal, 0);
  }

  function test_canBorrowAgainstUSDC() public {
    seedLendingPool(address(fToken));
    enterMarkets(bob, address(fUSDC), 100e6);
    vm.roll(block.number + 10);
    vm.prank(bob);
    fToken.borrow(_units(83));
    uint256 underlyingBal = underlying.balanceOf(bob);
    uint256 supplyRatefToken = fToken.supplyRatePerBlock();
    assertEq(underlyingBal, _units(83));
    assertGt(supplyRatefToken, 0);
  }

  function test_noCollateral_borrow_fail_usdcAgainstFToken() public {
    test_noCollateral_noBorrowPower();
    seedUSDCLendingPool();
    vm.startPrank(bob);
    vm.expectRevert();
    fUSDC.borrow(10e6);
    vm.stopPrank();
  }

  function test_noCollateral_liquidateBorrows() public {
    test_canBorrowAgainstUSDC();
    vm.roll(block.timestamp + 100);
    fToken.accrueInterest();
    (, uint liquidity, uint shortfall) = oComptroller.getAccountLiquidity(bob);
    assertGt(shortfall, 0);
    vm.prank(getWhale(address(fToken)));
    underlying.safeTransfer(guardian, _units(25));
    vm.startPrank(guardian);
    underlying.safeApprove(address(fToken), _units(25));
    fToken.liquidateBorrow(bob, _units(25), CTokenInterface(fUSDC));
    uint256 usdcGiven = fUSDC.balanceOfUnderlying(guardian);
    assertGt(usdcGiven, 25e6);
  }

  // Helper to setupV2Oracle in Inherited Contracts
  IOndoPriceOracleV2 oracleV2;

  function setUp_V2_Oracle() internal {
    address v2Oracle = deployCode("OndoPriceOracleV2.sol:OndoPriceOracleV2");
    oracleV2 = IOndoPriceOracleV2(v2Oracle);

    oracleV2.setFTokenToOracleType(
      address(fFRAX),
      IOndoPriceOracleV2.OracleType.CHAINLINK
    );
    oracleV2.setFTokenToChainlinkOracle(
      address(fFRAX),
      0xB9E1E3A9feFf48998E45Fa90847ed4D467E8BcfD,
      3600
    );

    oracleV2.setFTokenToOracleType(
      address(fUSDT),
      IOndoPriceOracleV2.OracleType.COMPOUND
    );
    oracleV2.setFTokenToCToken(address(fUSDT), cUSDT);

    oracleV2.setFTokenToOracleType(
      address(fLUSD),
      IOndoPriceOracleV2.OracleType.CHAINLINK
    );
    oracleV2.setFTokenToChainlinkOracle(
      address(fLUSD),
      0x3D7aE7E594f2f2091Ad8798313450130d0Aba3a0,
      3600
    );

    oracleV2.setFTokenToOracleType(
      address(fUSDC),
      IOndoPriceOracleV2.OracleType.COMPOUND
    );
    oracleV2.setFTokenToCToken(
      address(fUSDC),
      address(0x39AA39c021dfbaE8faC545936693aC917d5E7563)
    );
    oracleV2.setFTokenToOracleType(
      address(fCASH),
      IOndoPriceOracleV2.OracleType.MANUAL
    );
    oracleV2.setPrice(address(fCASH), 100e18);

    // Update Oracle on Comptroller
    oComptroller._setPriceOracle(address(oracleV2));
  }
}
