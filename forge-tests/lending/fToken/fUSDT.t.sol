pragma solidity 0.8.16;

import "forge-tests/lending/fToken/fToken.base.noCollateral.t.sol";
import "contracts/lending/IOndoPriceOracleV2.sol";

contract Test_fToken_fUSDT is Test_fTokenNonCollateral {
  function setUp() public override {
    super.setUp();
    _setfToken(address(fUSDT));
  }

  function test_name() public {
    string memory name = fUSDT.name();
    assertEq(name, "Flux USDT Token");
  }

  function test_symbol() public {
    string memory symbol = fUSDT.symbol();
    assertEq(symbol, "fUSDT");
  }
}
