// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-tests/lending/DeployBasicLendingMarket.t.sol";

contract Test_CompoundLens is BasicLendingMarket {
  ICToken[] tokens;

  function setUp() public override {
    super.setUp();
  }

  function test_get_account_limits_unused() public {
    ICompoundLens.AccountLimits memory limit = lens.getAccountLimits(
      ComptrollerLensInterface(address(oComptroller)),
      charlie
    );
    assertEq(limit.liquidity, 0);
    assertEq(limit.shortfall, 0);
    assertEq(limit.markets.length, 0);
  }

  function test_get_account_two_markets_supplied() public {
    enterMarkets(charlie, address(fCASH), 100e18);
    enterMarkets(charlie, address(fDAI), 100e18);
    ICompoundLens.AccountLimits memory limit = lens.getAccountLimits(
      ComptrollerLensInterface(address(oComptroller)),
      charlie
    );
    (, uint256 liquidity, ) = oComptroller.getAccountLiquidity(charlie);
    assertEq(limit.liquidity, liquidity);
    assertEq(limit.shortfall, 0);
    assertEq(limit.markets.length, 2);
    assertEq(address(limit.markets[0]), address(fCASH));
    assertEq(address(limit.markets[1]), address(fDAI));
  }

  function test_get_account_with_shortfall() public {
    _addAddressToKYC(kycRequirementGroup, charlie);
    seedDAILendingPool();
    enterMarkets(charlie, address(fUSDC), 100e6);
    vm.prank(charlie);
    fDAI.borrow(80e18);
    vm.roll(block.number + 1e9);
    fDAI.accrueInterest();
    ICompoundLens.AccountLimits memory limit = lens.getAccountLimits(
      ComptrollerLensInterface(address(oComptroller)),
      charlie
    );
    assertEq(limit.liquidity, 0);
    assertGt(limit.shortfall, 0);
    assertEq(limit.markets.length, 2);
    assertEq(address(limit.markets[1]), address(fDAI));
  }

  function assertCTokenBalance(
    ICompoundLens.CTokenBalances memory balance,
    address cToken,
    uint256 cTokenBalance,
    uint256 borrowBalance,
    uint256 balanceOfUnderlying,
    uint256 tokenBalance,
    uint256 tokenAllowance
  ) public {
    assertEq(balance.cToken, cToken);
    assertEq(balance.balanceOf, cTokenBalance);
    // Amount borrowed
    assertEq(balance.borrowBalanceCurrent, borrowBalance);
    // Deposited amount
    assertEq(balance.balanceOfUnderlying, balanceOfUnderlying);
    // Also the same as amount borrowed
    assertEq(balance.tokenBalance, tokenBalance);
    assertEq(balance.tokenAllowance, tokenAllowance);
  }

  function test_cToken_balances() public {
    _addAddressToKYC(kycRequirementGroup, charlie);
    // Sanity check
    assertEq(DAI.balanceOf(charlie), 0);

    enterMarkets(charlie, address(fCASH), 100e18);
    enterMarkets(charlie, address(fDAI), 100e18);
    vm.prank(charlie);
    fDAI.borrow(75e18);
    vm.prank(charlie);
    DAI.approve(address(fDAI), 25e18);
    tokens.push(ICToken(address(fDAI)));
    tokens.push(ICToken(address(fCASH)));
    ICompoundLens.CTokenBalances[] memory balances = lens.cTokenBalancesAll(
      tokens,
      payable(address(charlie))
    );

    assertEq(balances.length, 2);

    assertCTokenBalance(
      balances[0],
      address(fDAI),
      5000e8,
      75e18,
      100e18,
      75e18,
      25e18
    );

    assertCTokenBalance(balances[1], address(fCASH), 5000e8, 0, 100e18, 0, 0);
    delete tokens;
  }

  // Really just for verifying interfaces through compilation.
  function test_token_metadata() public {
    enterMarkets(charlie, address(fCASH), 100e18);
    enterMarkets(charlie, address(fDAI), 100e18);
    tokens.push(ICToken(address(fDAI)));
    tokens.push(ICToken(address(fCASH)));
    ICompoundLens.CTokenMetadata[] memory metadata = lens.cTokenMetadataAll(
      tokens
    );
    assertEq(metadata.length, 2);
  }
}
