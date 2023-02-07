/// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface IGovernorBravoDelegate {
  // State variable getters
  function name() external view returns (string memory);

  function MIN_PROPOSAL_THRESHOLD() external view returns (uint);

  function MAX_PROPOSAL_THRESHOLD() external view returns (uint);

  function MIN_VOTING_PERIOD() external view returns (uint);

  function MAX_VOTING_PERIOD() external view returns (uint);

  function MIN_VOTING_DELAY() external view returns (uint);

  function MAX_VOTING_DELAY() external view returns (uint);

  function quorumVotes() external view returns (uint);

  function proposalMaxOperations() external view returns (uint);

  function DOMAIN_TYPEHASH() external view returns (bytes32);

  function BALLOT_TYPEHASH() external view returns (bytes32);

  function pendingAdmin() external view returns (address);

  function votingPeriod() external view returns (uint256);

  /**
   * @notice Used to initialize the contract during delegator contructor
   * @param timelock_ The address of the Timelock
   * @param comp_ The address of the COMP token
   * @param votingPeriod_ The initial voting period
   * @param votingDelay_ The initial voting delay
   * @param proposalThreshold_ The initial proposal threshold
   */
  function intialize(
    address timelock_,
    address comp_,
    uint votingPeriod_,
    uint votingDelay_,
    uint proposalThreshold_
  ) external;

  function getForVotes(uint) external returns (uint);

  function getConVotes(uint) external returns (uint);

  /**
   * @notice Function used to propose a new proposal. Sender must have delegates above the proposal threshold
   * @param targets Target addresses for proposal calls
   * @param values Eth values for proposal calls
   * @param signatures Function signatures for proposal calls
   * @param calldatas Calldatas for proposal calls
   * @param description String description of the proposal
   * @return Proposal id of new proposal
   */
  function propose(
    address[] memory targets,
    uint[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    string memory description
  ) external returns (uint);

  /**
   * @notice Queues a proposal of state succeeded
   * @param proposalId The id of the proposal to queue
   */
  function queue(uint proposalId) external;

  /**
   * @notice Executes a queued proposal if eta has passed
   * @param proposalId The id of the proposal to execute
   */
  function execute(uint proposalId) external;

  /**
   * @notice Cancels a proposal only if sender is the proposer, or proposer delegates dropped below proposal threshold
   * @param proposalId The id of the proposal to cancel
   */
  function cancel(uint proposalId) external;

  /**
   * @notice Gets actions of a proposal
   * @param proposalId the id of the proposal
   */
  function getActions(
    uint proposalId
  )
    external
    view
    returns (
      address[] memory targets,
      uint[] memory values,
      string[] memory signatures,
      bytes[] memory calldatas
    );

  /**
   * @notice Gets the receipt for a voter on a given proposal
   * @param proposalId the id of proposal
   * @param voter The address of the voter
   * @return The voting receipt
   */
  function getReceipt(
    uint proposalId,
    address voter
  ) external view returns (Receipt memory);

  /**
   * @notice Gets the state of a proposal
   * @param proposalId The id of the proposal
   * @return Proposal state
   */
  function state(uint proposalId) external view returns (uint);

  function latestProposalIds(address) external view returns (uint);

  /**
   * @notice Cast a vote for a proposal
   * @param proposalId The id of the proposal to vote on
   * @param support The support value for the vote. 0=against, 1=for, 2=abstain
   */
  function castVote(uint proposalId, uint8 support) external;

  /**
   * @notice Cast a vote for a proposal with a reason
   * @param proposalId The id of the proposal to vote on
   * @param support The support value for the vote. 0=against, 1=for, 2=abstain
   * @param reason The reason given for the vote by the voter
   */
  function castVoteWithReason(
    uint proposalId,
    uint8 support,
    string calldata reason
  ) external;

  /**
   * @notice Cast a vote for a proposal by signature
   * @dev External function that accepts EIP-712 signatures for voting on proposals.
   */
  function castVoteBySig(
    uint proposalId,
    uint8 support,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @notice View function which returns if an account is whitelisted
   * @param account Account to check white list status of
   * @return If the account is whitelisted
   */
  function isWhitelisted(address account) external view returns (bool);

  /**
   * @notice Admin function for setting the voting delay
   * @param newVotingDelay new voting delay, in blocks
   */
  function _setVotingDelay(uint newVotingDelay) external;

  /**
   * @notice Admin function for setting the voting period
   * @param newVotingPeriod new voting period, in blocks
   */
  function _setVotingPeriod(uint newVotingPeriod) external;

  /**
   * @notice Admin function for setting the proposal threshold
   * @dev newProposalThreshold must be greater than the hardcoded min
   * @param newProposalThreshold new proposal threshold
   */
  function _setProposalThreshold(uint newProposalThreshold) external;

  /**
   * @notice Admin function for setting the whitelist expiration as a timestamp for an account. Whitelist status allows accounts to propose without meeting threshold
   * @param account Account address to set whitelist expiration for
   * @param expiration Expiration for account whitelist status as timestamp (if now < expiration, whitelisted)
   */
  function _setWhitelistAccountExpiration(
    address account,
    uint expiration
  ) external;

  /**
   * @notice Admin function for setting the whitelistGuardian. WhitelistGuardian can cancel proposals from whitelisted addresses
   * @param account Account to set whitelistGuardian to (0x0 to remove whitelistGuardian)
   */
  function _setWhitelistGuardian(address account) external;

  function _initiate() external;

  /**
   * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
   * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
   * @param newPendingAdmin New pending admin.
   */
  function _setPendingAdmin(address newPendingAdmin) external;

  /**
   * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
   * @dev Admin function for pending admin to accept role and update admin
   */
  function _acceptAdmin() external;

  /**
   * Data types TODO: Add breaker
   */

  /// @notice Ballot receipt record for a voter
  struct Receipt {
    /// @notice Whether or not a vote has been cast
    bool hasVoted;
    /// @notice Whether or not the voter supports the proposal or abstains
    uint8 support;
    /// @notice The number of votes the voter had, which were cast
    uint96 votes;
  }

  /// @notice Possible states that a proposal may be in
  enum ProposalState {
    Pending,
    Active,
    Canceled,
    Defeated,
    Succeeded,
    Queued,
    Expired,
    Executed
  }

  function proposalCount() external view returns (uint);

  function getProposer(uint proposalId) external view returns (address);

  function getProposalStartBlock(uint proposalId) external view returns (uint);

  function getProposalEndBlock(uint proposalId) external view returns (uint);

  function getProposalExecuteFlag(uint proposalId) external view returns (bool);

  function getProposalCanceledFlag(
    uint proposalId
  ) external view returns (bool);

  function getProposalEta(uint proposalId) external view returns (uint);

  function proposalThreshold() external view returns (uint);
}
