// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title SimpleFundraiser
 * A contract for managing a simple fundraising campaign without external oracles.
 */
contract SimpleFundraiser {
    // Mapping to track each contributor's balance in wei
    mapping(address => uint256) public contributorBalances;

    // Fundraising parameters in USD (scaled by 1e18)
    // 1e18 (or 1 * 10^18) is used for decimal precision in Ethereum
    // 1 Ether = 10^18 Wei
    // Example:
    // - 50 * 1e18 = 50_000_000_000_000_000_000 (50 with 18 decimal places)
    // - 50000 * 1e18 = 50000_000_000_000_000_000_000 (50000 with 18 decimal places)

    /**
     * Minimum contribution required from each donor (50 USD)
     * Set to 50 USD scaled by 1e18 for precision.
     */
    uint256 public constant MIN_CONTRIBUTION_USD = 50 * 1e18;

    /**
     * Total funding target for the fundraiser (50,000 USD)
     * Set to 50,000 USD scaled by 1e18 for precision.
     */
    uint256 public constant FUNDING_GOAL_USD = 50000 * 1e18;

    // State variables
    address public ownerAddress;         // Address of the contract owner
    uint256 public deploymentTime;       // Timestamp when the contract was deployed
    uint256 public fundraisingDuration;  // Duration of the fundraising period in seconds
    address public erc20TokenAddress;     // Address of an associated ERC20 token contract
    bool public fundsWithdrawn = false;  // Flag indicating if funds have been withdrawn

    uint256 public ethPrice; // Current ETH price in USD, scaled by 1e18

    // Events
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event RefundClaimed(address indexed contributor, uint256 amount);
    event ContributorBalanceUpdated(address indexed contributor, uint256 newBalance);
    event EthPriceUpdated(uint256 newPrice);

    /**
     * Initializes the contract with a fundraising duration and initial ETH price.
     * @param _fundraisingDuration Duration of the fundraising in seconds.
     * @param _initialEthPrice Initial ETH price in USD (18 decimals).
     */
    constructor(uint256 _fundraisingDuration, uint256 _initialEthPrice) {
        ownerAddress = msg.sender; // Sets the deployer as the owner
        deploymentTime = block.timestamp; // Records the deployment time
        fundraisingDuration = _fundraisingDuration; // Sets the fundraising duration
        ethPrice = _initialEthPrice; // Sets the initial ETH price
    }
 
 
    // Modifiers
    // Basic Structure of a Modifier
    // modifier modifierName(parameters) {
    //     // Pre-function execution code
    //     _;
    //     // Post-function execution code
    // }
    // modifierName: The name of the modifier.
    // parameters: Optional parameters that can be passed to the modifier.
    // _ (underscore): A special placeholder that represents the function body where the modifier is applied.

    /**
     * Ensures that the fundraising period has ended.
     */
    modifier fundraisingEnded() {
        require(
            block.timestamp >= deploymentTime + fundraisingDuration,
            "Fundraising period is still active."
        ); // Checks if the current time is past the fundraising end time
        _; // Continues execution of the function
    }
    /**
     * Restricts function access to the contract owner.
     */
    modifier requireOwner() {
        require(
            msg.sender == ownerAddress, 
            "Only the contract owner can perform this action."); // Ensures the caller is the owner
        _; // Continues execution of the function
    }   

    /**
     * Update the ETH price in USD.
     * @param _newPrice New ETH price in USD (18 decimals).
     */
    function updateEthPrice(uint256 _newPrice) external requireOwner {
        require(_newPrice > 0, "Price must be greater than zero."); // Ensures the new price is positive
        ethPrice = _newPrice; // Updates the ETH price
        emit EthPriceUpdated(_newPrice); // Emits an event for the price update
    }

    /**
     * Contribute ETH to the fundraiser.
     * Ensures the contribution meets the minimum USD requirement and is within the fundraising period.
     */
    function contribute() external payable {
        // Converts the contributed ETH to USD and checks if it meets the minimum requirement
        require(
            convertEthToUsd(msg.value) >= MIN_CONTRIBUTION_USD,
            "Minimum contribution is 50 USD worth of ETH."
        );
        // Checks if the fundraising period is still active
        require(
            block.timestamp < deploymentTime + fundraisingDuration,
            "Fundraising period has ended."
        );
        contributorBalances[msg.sender] += msg.value; // Updates the contributor's balance
    }

    /**
     * Convert ETH amount to USD.
     * @param ethAmount Amount in wei.
     * @return usdAmount Equivalent USD value.
     */
    function convertEthToUsd(uint256 ethAmount) public view returns (uint256 usdAmount) {
        usdAmount = (ethAmount * ethPrice) / 1e18; // Converts wei to USD based on current ETH price
    }

    /**
     * Transfer ownership to a new owner.
     * @param newOwnerAddress Address of the new owner.
     */
    function transferOwnership(address newOwnerAddress) public requireOwner {
        require(newOwnerAddress != address(0), "New owner cannot be the zero address."); // Ensures the new owner address is valid
        ownerAddress = newOwnerAddress; // Transfers ownership
    }

    /**
     * Withdraw funds if funding goal is met.
     * Only the owner can call this after the fundraising period has ended and the goal is reached.
     */
    function withdrawFunds() external fundraisingEnded requireOwner {
        // Checks if the funding goal has been reached based on current ETH price
        require(
            convertEthToUsd(address(this).balance) >= FUNDING_GOAL_USD,
            "Funding goal has not been reached."
        );

        // Transfers the entire contract balance to the owner
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "ETH transfer failed."); // Ensures the transfer was successful

        fundsWithdrawn = true; // Sets the flag indicating funds have been withdrawn
        emit FundsWithdrawn(msg.sender, address(this).balance); // Emits an event for the withdrawal
    }

    /**
     * Claim refund if funding goal is not met.
     * Contributors can claim their contributions back if the funding goal wasn't reached after the fundraising period.
     */
    function claimRefund() external fundraisingEnded {
        // Checks if the funding goal was not met
        require(
            convertEthToUsd(address(this).balance) < FUNDING_GOAL_USD,
            "Funding goal was met; refunds are not available."
        );
        // Ensures the contributor has a balance to refund
        require(contributorBalances[msg.sender] > 0, "No contributions to refund.");

        uint256 contributedAmount = contributorBalances[msg.sender]; // Retrieves the contributed amount
        contributorBalances[msg.sender] = 0; // Resets the contributor's balance

        // Transfers the contributed amount back to the contributor
        (bool success, ) = payable(msg.sender).call{value: contributedAmount}("");
        require(success, "ETH refund failed."); // Ensures the refund was successful

        emit RefundClaimed(msg.sender, contributedAmount); // Emits an event for the refund
    }

    /**
     * Update a contributor's balance (authorized ERC20 contract only).
     * @param contributor Address of the contributor.
     * @param newBalance New contribution balance.
     */
    function updateContributorBalance(address contributor, uint256 newBalance) external {
        require(
            msg.sender == erc20TokenAddress,
            "Only the authorized ERC20 contract can update balances."
        ); // Ensures only the authorized ERC20 contract can update balances
        contributorBalances[contributor] = newBalance; // Updates the contributor's balance

        emit ContributorBalanceUpdated(contributor, newBalance); // Emits an event for the balance update
    }

}
