pragma solidity 0.8.16;
import "contracts/external/openzeppelin/contracts/token/IERC20.sol";
import "contracts/lending/ondo/ondo-token/IOndo.sol";
import "forge-tests/helpers/ISanctionsOracle.sol";

// Known production mainnet addresses with large balances that we can impersonate for testing.
contract Whales {
  address public constant USDC_WHALE =
    0x0A59649758aa4d66E25f08Dd01271e891fe52199;
  address public constant DAI_WHALE =
    0x075e72a5eDf65F0A5f44699c7654C1a76941Ddc8;
  address public constant FRAX_WHALE =
    0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B;
  address public constant LUSD_WHALE =
    0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1;
  address public constant USDT_WHALE =
    0xF977814e90dA44bFA03b6295A0616a897441aceC;
  address public constant ONDO_WHALE =
    0x677FD4Ed8aE623f2f625DEB2D64F2070E46cA1A1;
}

// Known production mainnet token contracts.
contract Tokens {
  IERC20 public constant USDC =
    IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  IERC20 public constant DAI =
    IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  IERC20 public constant FRAX =
    IERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e);
  IERC20 public constant LUSD =
    IERC20(0x5f98805A4E8be255a32880FDeC7F6728C6568bA0);
  IERC20 public constant USDT =
    IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  IOndo ONDO_TOKEN = IOndo(0xfAbA6f8e4a5E8Ab82F62fe7C39859FA577269BE3);
}

// Known production mainnet CToken contracts.
contract CTokens {
  address public constant cDAI = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
  address public constant cUSDT = 0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9;
}

contract Oracles {
  // Chainalysis
  ISanctionsOracle public constant SANCTIONS_ORACLE =
    ISanctionsOracle(0x40C57923924B5c5c5455c48D93317139ADDaC8fb);
}
