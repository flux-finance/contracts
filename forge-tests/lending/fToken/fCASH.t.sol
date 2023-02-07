pragma solidity 0.8.16;

import "forge-tests/lending/fToken/fToken.base.t.sol";

// Basic Tests on fCASH token. Tests Using fCASH as collateral and
// borrowing can be found in fToken.base.KYC.t.sol
contract Test_fToken_fCASH is Test_fToken_Basic {
  function setUp() public override {
    super.setUp();
    _setfToken(address(fCASH));
  }

  function test_name() public {
    string memory name = fCASH.name();
    assertEq(name, "Flux CASH Token");
  }

  function test_symbol() public {
    string memory symbol = fCASH.symbol();
    assertEq(symbol, "fCASH");
  }

  function test_fCASH_protocolSeizeShare() public {
    uint256 protocolSeizeShare = fCASH.protocolSeizeShareMantissa();
    assertEq(protocolSeizeShare, 0);
  }

  function test_fCASH_transfer_fail_KYC_spender() public {
    enterMarkets(charlie, address(fCASH), 100e18);
    _removeAddressFromKYC(kycRequirementGroup, charlie);
    vm.expectRevert("Spender not KYC'd");
    vm.prank(charlie);
    fCASH.transfer(alice, 100e18);
  }

  function test_fCASH_transfer_fail_KYC_source() public {
    enterMarkets(charlie, address(fCASH), 100e18);
    _removeAddressFromKYC(kycRequirementGroup, charlie);
    fCASH.approve(address(this), 100e18);
    vm.expectRevert("Source not KYC'd");
    fCASH.transferFrom(charlie, alice, 100e18);
  }

  function test_fCASH_transfer_fail_KYC_destination() public {
    enterMarkets(charlie, address(fCASH), 100e18);
    _removeAddressFromKYC(kycRequirementGroup, alice);
    vm.expectRevert("Destination not KYC'd");
    vm.prank(charlie);
    fCASH.transfer(alice, 100e18);
  }

  function test_fCASH_mint_fail_sanction() public {
    _addAddressToSanctionsList(charlie);
    _addAddressToKYC(kycRequirementGroup, charlie);
    // KYCRegistry also checks sanctions list.
    vm.expectRevert("Minter not KYC'd");
    vm.prank(charlie);
    fCASH.mint(100e18);
  }

  function test_fCASH_mint_fail_KYC() public {
    vm.expectRevert("Minter not KYC'd");
    vm.prank(charlie);
    fCASH.mint(100e18);
  }

  function test_fCASH_redeem_fail_sanction() public {
    enterMarkets(charlie, address(fCASH), 100e18);
    _addAddressToSanctionsList(charlie);
    _addAddressToKYC(kycRequirementGroup, charlie);
    vm.expectRevert("Redeemer not KYC'd");
    vm.prank(charlie);
    fCASH.redeem(100e18);
  }

  function test_fCASH_redeem_fail_KYC() public {
    enterMarkets(charlie, address(fCASH), 100e18);
    _removeAddressFromKYC(kycRequirementGroup, charlie);
    vm.expectRevert("Redeemer not KYC'd");
    vm.prank(charlie);
    fCASH.redeem(100e18);
  }
}
