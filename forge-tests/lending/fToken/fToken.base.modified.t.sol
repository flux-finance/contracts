pragma solidity 0.8.16;

import "forge-tests/lending/fToken/fToken.base.t.sol";

/// @notice fToken tests for fTokens that inherit from cTokenModified
///         and can be used as collateral
abstract contract Test_fTokenModified is Test_fToken_Basic {
  using SafeERC20 for IERC20;
  uint256 collateralFactor;

  // Sets generic fToken for tests that inherits from
  // contracts/lending/tokens/cToken/CTokenModified.sol
  function _setfToken(address _fToken) internal override {
    super._setfToken(_fToken);
  }

  // Set collateral factor in %
  // If CF is 85%, pass in 85
  function _setCollateralFactorForToken(uint256 _collateralFactor) internal {
    collateralFactor = _collateralFactor;
  }

  // Basic Param Checks
  function test_fToken_protocolSeizeShare() public {
    uint256 protocolSeizeShare = fToken.protocolSeizeShareMantissa();
    assertEq(protocolSeizeShare, 1.75e16);
  }

  function test_fToken_collateralFactor() public {
    (, uint collateralFactorMantissa) = oComptroller.markets(address(fToken));
    assertGt(collateralFactorMantissa, 0);
  }

  // Basic Borrow Checks
  function test_borrowRatePerBlock_on_init() public {
    // y-intercept is zero on IR model that DAI uses
    uint256 defaultBorrowRate = fToken.borrowRatePerBlock();
    assertEq(defaultBorrowRate, 0);
  }

  function test_supplyRatePerBlock_after_borrow() public {
    _addAddressToKYC(kycRequirementGroup, charlie);
    enterMarkets(charlie, address(fToken), _units(100));
    vm.prank(charlie);
    fToken.borrow(_units(50));
    uint256 supplyRate = fToken.supplyRatePerBlock();
    assertGt(supplyRate, 0);
  }

  /// fTokenModified Access Control Checks
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
    fToken.borrow(_units(50));
    _removeAddressFromKYC(kycRequirementGroup, charlie);
    vm.expectRevert("Payer not KYC'd");
    vm.prank(charlie);
    fToken.repayBorrow(_units(50));
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
    enterMarkets(charlie, address(fCASH), 1e18);
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
    fToken.borrow(_units(50));
    _removeAddressFromKYC(kycRequirementGroup, address(this));
    vm.expectRevert("Payer not KYC'd");
    fToken.repayBorrowBehalf(charlie, _units(50));
  }

  function test_repayBorrowBehalf_fail_KYC_borrower_fTokenUnderlyingCollateral()
    public
  {
    enterMarkets(charlie, address(fToken), _units(100));
    _addAddressToKYC(kycRequirementGroup, charlie);
    vm.prank(charlie);
    fToken.borrow(_units(50));
    _removeAddressFromKYC(kycRequirementGroup, charlie);
    vm.expectRevert("Borrower not KYC'd");
    fToken.repayBorrowBehalf(charlie, _units(50));
  }

  function test_seize_fail_sanction_borrower() public {
    enterMarkets(charlie, address(fToken), _units(100));
    _addAddressToKYC(kycRequirementGroup, charlie);
    vm.prank(charlie);
    fToken.borrow(_units(collateralFactor)); //borrow max collateralFactor
    // Seed the liquidator with some USDC and approve
    vm.prank(DAI_WHALE);
    underlying.safeTransfer(address(this), _units(30));
    underlying.safeApprove(address(fToken), _units(30));
    // Sanction borrower
    _addAddressToSanctionsList(charlie);
    //Roll blocks to become underwater
    vm.roll(block.number + 10000);
    // Expect revert on liquidate
    vm.expectRevert("Borrower not KYC'd");
    fToken.liquidateBorrow(charlie, _units(30), CTokenInterface(fToken));
  }

  function test_seize_fail_sanction_liquidator() public {
    enterMarkets(charlie, address(fToken), _units(100));
    _addAddressToKYC(kycRequirementGroup, charlie);
    vm.prank(charlie);
    fToken.borrow(_units(collateralFactor)); //borrow max collateralFactor
    // Seed the liquidator with some USDC and approve
    vm.prank(DAI_WHALE);
    underlying.safeTransfer(address(this), _units(30));
    underlying.safeApprove(address(fToken), _units(30));
    // Sanction liquidator
    _addAddressToSanctionsList(address(this));
    // Roll blocks to become underwater
    vm.roll(block.number + 10000);
    // Expect revert on liquidate
    vm.expectRevert("Payer not KYC'd"); //Will have KYC error given that KYC checks sanctions
    fToken.liquidateBorrow(charlie, _units(30), CTokenInterface(fToken));
  }

  function test_seize_fCASH_fail_KYC_borrower() public {
    enterMarkets(charlie, address(fCASH), 1e18);
    seedLendingPool(address(fToken));
    vm.prank(charlie);
    fToken.borrow(_units(90)); // borrow max collateralFactor
    // Seed the liquidator with some USDC and approve
    vm.prank(DAI_WHALE);
    underlying.safeTransfer(address(this), _units(30));
    underlying.safeApprove(address(fToken), _units(30));
    // Roll blocks to become underwater
    vm.roll(block.number + 1e9);
    // Expect revert on liquidate
    _removeAddressFromKYC(kycRequirementGroup, charlie);
    vm.expectRevert("Borrower not KYC'd");
    fToken.liquidateBorrow(charlie, _units(30), CTokenInterface(fCASH));
  }

  function test_seize_fCASH_fail_KYC_liquidator() public {
    enterMarkets(charlie, address(fCASH), 1e18);
    seedLendingPool(address(fToken));
    vm.prank(charlie);
    fToken.borrow(_units(90)); // borrow max collateralFactor
    // Seed the liquidator with some USDC and approve
    vm.prank(DAI_WHALE);
    underlying.safeTransfer(address(this), _units(30));
    underlying.safeApprove(address(fToken), _units(30));
    // Roll blocks to become underwater
    vm.roll(block.number + 1e9);
    // Expect revert on liquidate
    _removeAddressFromKYC(kycRequirementGroup, address(this));
    vm.expectRevert("Payer not KYC'd"); // Won't have Borrower revert message since call repayBorrowFresh before seize
    fToken.liquidateBorrow(charlie, _units(30), CTokenInterface(fCASH));
  }

  function test_seize_fCASH_success() public {
    enterMarkets(charlie, address(fCASH), 1e18);
    seedLendingPool(address(fToken));
    vm.prank(charlie);
    fToken.borrow(_units(90)); // borrow max collateralFactor
    // Seed the liquidator with some USDC and approve
    vm.prank(DAI_WHALE);
    underlying.safeTransfer(address(this), _units(30));
    underlying.safeApprove(address(fToken), _units(30));
    // Roll blocks to become underwater
    vm.roll(block.number + 1e9);
    // Cache Variables for Checks
    fToken.accrueInterest();
    uint256 borrows = fToken.totalBorrows();
    uint256 borrowerfCASHBalanceBefore = fCASH.balanceOf(charlie);
    // Liquidate
    fToken.liquidateBorrow(charlie, _units(30), CTokenInterface(fCASH));
    // Checks
    assertGt(fCASH.balanceOf(address(this)), 0);
    assertLt(fCASH.balanceOf(charlie), borrowerfCASHBalanceBefore);
    assertEq(fToken.totalBorrows(), borrows - _units(30));
  }

  // Collateral Token Tests
  function test_getAccountLiquidity() public {
    enterMarkets(bob, address(fToken), _units(100));
    vm.roll(block.number + 10);
    (, uint liquidity, uint shortfall) = oComptroller.getAccountLiquidity(bob);
    uint256 fTokenBal = fToken.balanceOf(bob);
    uint256 price = ondoOracle.getUnderlyingPrice(address(fToken));
    if (address(fToken) == address(fUSDC)) {
      assertEq(liquidity, collateralFactor * 1e18);
    } else {
      price = ondoOracle.getUnderlyingPrice(address(fToken));
      assertEq(liquidity, (collateralFactor * 1e18 * price) / 1e18);
    }
    assertEq(shortfall, 0);
    assertGt(fTokenBal, 0);
  }
}

interface ProtocolSeizeShareCheck {
  function protocolSeizeShareMantissa() external view returns (uint);
}
