pragma solidity 0.8.16;

import "forge-tests/lending/fToken/fToken.base.modified.t.sol";

contract Test_fToken_fUSDC is Test_fTokenModified {
  function setUp() public override {
    super.setUp();
    _setfToken(address(fUSDC));
    _setCollateralFactorForToken(85);
  }

  function test_name() public {
    string memory name = fUSDC.name();
    assertEq(name, "Flux USDC Token");
  }

  function test_symbol() public {
    string memory symbol = fUSDC.symbol();
    assertEq(symbol, "fUSDC");
  }
}
