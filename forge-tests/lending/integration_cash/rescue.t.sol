pragma solidity 0.8.16;

import "forge-tests/lending/DeployBasicLendingMarket.t.sol";

contract Test_Lending_Oracle is BasicLendingMarket {
  IMulticall.ExCallData[] payload;

  function test_can_upgrade_and_rescue_funds() public {
    strandUSDC(address(fDAI));
    address newImpl = deployCode(
      "CTokenDelegateUpgrade.sol:CTokenDelegateUpgrade"
    );
    fDAI._setImplementation(newImpl, true, "");
    address result = fDAI.implementation();
    assertEq(result, newImpl);
    bytes memory data = abi.encodeWithSelector(
      USDC.transfer.selector,
      alice,
      5000e6
    );
    payload.push(IMulticall.ExCallData(address(USDC), data, 0));
    IMulticall(address(fDAI)).multiexcall(payload);
    uint256 balAlice = USDC.balanceOf(alice);
    assertEq(balAlice, 5000e6);
  }

  function test_can_upgrade_and_rescue_funds_fCASH() public {
    strandUSDC(address(fCASH));
    address newImpl = deployCode(
      "CCashDelegateUpgrade.sol:CCashDelegateUpgrade"
    );
    fCASH._setImplementation(newImpl, true, "");
    address result = fCASH.implementation();
    assertEq(result, newImpl);
    bytes memory data = abi.encodeWithSelector(
      USDC.transfer.selector,
      alice,
      5000e6
    );
    payload.push(IMulticall.ExCallData(address(USDC), data, 0));
    IMulticall(address(fCASH)).multiexcall(payload);
    uint256 balAlice = USDC.balanceOf(alice);
    assertEq(balAlice, 5000e6);
  }

  function strandUSDC(address target) public {
    vm.prank(USDC_WHALE);
    USDC.transfer(target, 5000e6);
    console.log("The USDC val of the target is:", USDC.balanceOf(target));
  }
}
