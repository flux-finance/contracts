pragma solidity 0.8.16;

import "forge-tests/lending/DeployBasicLendingMarket.t.sol";
import "contracts/external/openzeppelin/contracts/token/IERC20Metadata.sol";

// Basic checks for all fTokens (fCASH and fToken)
abstract contract Test_fToken_Basic is BasicLendingMarket {
  ICToken fToken;
  IERC20 underlying;
  uint256 decimals;

  function _setfToken(address _fToken) internal virtual {
    fToken = ICToken(_fToken);
    underlying = IERC20(fToken.underlying());
    decimals = IERC20Metadata(address(underlying)).decimals();
  }

  function _units(uint256 value) internal view returns (uint256) {
    return value * 10 ** decimals;
  }

  function test_constructor_reverts_non_erc20_underlying() public {
    address implementation = deployCode("CTokenDelegate.sol:CTokenDelegate");
    vm.expectRevert();
    deployCode(
      "cErc20ModifiedDelegator.sol:CErc20DelegatorKYC",
      abi.encode(
        address(0), // Bad underlying address
        address(oComptroller),
        address(interestRateModel),
        200000000000000000000000000,
        "Flux Test Token",
        "fTest",
        8,
        address(this),
        implementation,
        address(registry),
        kycRequirementGroup,
        implementationData
      )
    );
  }

  function test_constructor_fail_0_initial_exchangeRate() public {
    address implementation = deployCode("CTokenDelegate.sol:CTokenDelegate");
    vm.expectRevert("initial exchange rate must be greater than zero.");
    deployCode(
      "cErc20ModifiedDelegator.sol:CErc20DelegatorKYC",
      abi.encode(
        address(underlying),
        address(oComptroller),
        address(interestRateModel),
        0, // Bad initial exchange rate
        "Flux Test Token",
        "fTest",
        8,
        address(this),
        implementation,
        address(registry),
        kycRequirementGroup,
        implementationData
      )
    );
  }

  function test_constructor() public {
    address implementation = deployCode("CTokenDelegate.sol:CTokenDelegate");
    address delegator = deployCode(
      "cErc20ModifiedDelegator.sol:CErc20DelegatorKYC",
      abi.encode(
        fToken.underlying(),
        address(oComptroller),
        address(interestRateModel),
        200000000000000000000000000,
        "Flux Test Token",
        "fTest",
        8,
        address(this),
        implementation,
        address(registry),
        kycRequirementGroup,
        implementationData
      )
    );
    assert(delegator != address(0));
  }

  function test_decimals() public {
    assertEq(fToken.decimals(), 8);
  }

  function test_balanceOfUnderlying() public {
    enterMarkets(charlie, address(fToken), _units(100));
    uint256 underlyingBalance = fToken.balanceOfUnderlying(charlie);
    assertEq(underlyingBalance, _units(100));
  }

  function test_getCash_on_init() public {
    uint256 cashPresent = fToken.getCash();
    assertEq(cashPresent, 0);
  }

  function test_getCash_after_deposit() public {
    enterMarkets(charlie, address(fToken), _units(100));
    uint256 cashPresent = fToken.getCash();
    assertEq(cashPresent, _units(100));
  }

  function test_setKYCRegistry_access_control() public {
    vm.expectRevert("Only admin can set KYC registry");
    vm.prank(charlie);
    fToken.setKYCRegistry(address(registry));
  }

  function test_setKYCRegistry_fail_zero_address() public {
    vm.expectRevert("KYC registry cannot be zero address");
    fToken.setKYCRegistry(address(0));
  }

  function test_fToken_kyc_kycRequirementGroup_fail_accessControl() public {
    vm.expectRevert("Only admin can set KYC requirement group");
    vm.prank(charlie);
    fToken.setKYCRequirementGroup(kycRequirementGroup + 1);
  }

  function test_fToken_kyc_kycRequirementGroup() public {
    fToken.setKYCRequirementGroup(kycRequirementGroup + 1);
  }
}
