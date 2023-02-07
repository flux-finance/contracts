pragma solidity 0.8.16;

import "forge-tests/cash/helpers/DSTestPlus.sol";
import "forge-tests/common/constants.sol";
import "forge-tests/lending/helpers/interfaces/IGovernorBravoHarness.sol";
import "forge-tests/lending/helpers/interfaces/ITimelock.sol";
import "forge-tests/lending/helpers/interfaces/ICompoundLens.sol";
import "forge-std/console.sol";

abstract contract BaseDAO is DSTestPlus, Whales, Tokens {
  uint256 delay;
  uint256 votingPeriod = 21600;
  IGovernorBravoDelegate dao =
    IGovernorBravoDelegate(0x336505EC1BcC1A020EeDe459f57581725D23465A);
  ITimelock timelock = ITimelock(0x2c5898da4DF1d45EAb2B7B192a361C3b9EB18d9c);

  address fluxMSig = address(0x118919e891D0205A7492650AD32E727617FA9452);

  address fluxTeam = address(0x1);

  address[] targets;
  uint[] values;
  string[] signatures;
  bytes[] calldatas;

  ICompoundLens lens;

  function setUp() public virtual {
    delay = timelock.delay();

    // Delegate votes to addresses
    vm.startPrank(ONDO_WHALE);
    ONDO_TOKEN.transfer(address(fluxTeam), 100_000_001e18);
    ONDO_TOKEN.transfer(address(fluxMSig), 100_000_001e18);
    vm.stopPrank();

    vm.prank(fluxMSig);
    ONDO_TOKEN.delegate(fluxMSig);

    vm.prank(fluxTeam);
    ONDO_TOKEN.delegate(fluxTeam);

    vm.roll(block.number + 10);
  }
}
