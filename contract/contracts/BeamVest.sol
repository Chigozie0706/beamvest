// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title BeamVest
 * @notice A decentralized lending and borrowing protocol for the Beam Network.
 * @dev Uses native $BEAM token.
 *      Uses ReentrancyGuard and checks-effects-interactions for security.
 */
contract BeamVest is ReentrancyGuard {
    //  State

    address public owner;

    uint256 public totalDeposits;
    uint256 public totalBorrowed;

    uint256 public constant COLLATERAL_RATIO = 150; // 150% collateral required
    uint256 public constant LIQUIDATION_RATIO = 125; // liquidate below 125%
    uint256 public constant BASE_INTEREST_RATE = 5; // 5% base APY
    uint256 public constant LIQUIDATION_BONUS = 5; // 5% bonus for liquidators

    struct Deposit {
        uint256 amount;
        uint256 depositedAt;
    }

    struct Loan {
        uint256 collateral;
        uint256 borrowed;
        uint256 borrowedAt;
    }

    mapping(address => Deposit) public deposits;
    mapping(address => Loan) public loans;

    //  Events

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 collateral, uint256 amount);
    event Repaid(address indexed user, uint256 amount);
    event Liquidated(
        address indexed borrower,
        address indexed liquidator,
        uint256 payout
    );

    //  Errors

    error ZeroAmount();
    error InsufficientBalance();
    error InsufficientLiquidity();
    error InsufficientCollateral();
    error ActiveLoanExists();
    error NoActiveLoan();
    error PositionIsHealthy();
    error InsufficientRepayment();
    error TransferFailed();

    //  Constructor

    constructor() {
        owner = msg.sender;
    }

    //  Lender Actions

    /**
     * @notice Deposit native $BEAM to earn yield.
     * @dev Send BEAM as msg.value.
     */
    function deposit() external payable nonReentrant {
        if (msg.value == 0) revert ZeroAmount();

        deposits[msg.sender].amount += msg.value;
        deposits[msg.sender].depositedAt = block.timestamp;
        totalDeposits += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw deposited $BEAM plus accrued interest.
     * @param amount Amount of $BEAM to withdraw (in wei).
     */
    function withdraw(uint256 amount) external nonReentrant {
        Deposit storage d = deposits[msg.sender];
        if (d.amount < amount) revert InsufficientBalance();

        uint256 interest = _calculateInterest(d.amount, d.depositedAt);
        uint256 payout = amount + interest;

        if (address(this).balance < payout) revert InsufficientLiquidity();

        // Update state BEFORE transfer (checks-effects-interactions)
        d.amount -= amount;
        totalDeposits -= amount;

        _safeTransfer(msg.sender, payout);

        emit Withdrawn(msg.sender, payout);
    }

    //  Borrower Actions

    /**
     * @notice Borrow $BEAM by posting native $BEAM as collateral.
     * @dev Send collateral as msg.value. Minimum 150% collateral ratio.
     * @param borrowAmount Amount of $BEAM to borrow (in wei).
     */
    function borrow(uint256 borrowAmount) external payable nonReentrant {
        if (loans[msg.sender].borrowed != 0) revert ActiveLoanExists();
        if (borrowAmount == 0) revert ZeroAmount();

        uint256 requiredCollateral = (borrowAmount * COLLATERAL_RATIO) / 100;
        if (msg.value < requiredCollateral) revert InsufficientCollateral();

        if (address(this).balance - msg.value < borrowAmount)
            revert InsufficientLiquidity();

        // Update state BEFORE transfer (checks-effects-interactions)
        loans[msg.sender] = Loan({
            collateral: msg.value,
            borrowed: borrowAmount,
            borrowedAt: block.timestamp
        });
        totalBorrowed += borrowAmount;

        _safeTransfer(msg.sender, borrowAmount);

        emit Borrowed(msg.sender, msg.value, borrowAmount);
    }

    /**
     * @notice Repay your loan and recover collateral.
     * @dev Send repayment amount as msg.value (principal + interest).
     */
    function repay() external payable nonReentrant {
        Loan storage loan = loans[msg.sender];
        if (loan.borrowed == 0) revert NoActiveLoan();

        uint256 interest = _calculateInterest(loan.borrowed, loan.borrowedAt);
        uint256 totalDue = loan.borrowed + interest;
        if (msg.value < totalDue) revert InsufficientRepayment();

        uint256 collateralToReturn = loan.collateral;

        // Update state BEFORE transfer (checks-effects-interactions)
        totalBorrowed -= loan.borrowed;
        delete loans[msg.sender];

        _safeTransfer(msg.sender, collateralToReturn);

        emit Repaid(msg.sender, msg.value);
    }

    //  Liquidation

    /**
     * @notice Liquidate an undercollateralised position.
     * @dev Send the borrower's debt amount as msg.value.
     * @param borrower Address of the borrower to liquidate.
     */
    function liquidate(address borrower) external payable nonReentrant {
        Loan storage loan = loans[borrower];
        if (loan.borrowed == 0) revert NoActiveLoan();

        uint256 colRatio = (loan.collateral * 100) / loan.borrowed;
        if (colRatio >= LIQUIDATION_RATIO) revert PositionIsHealthy();

        if (msg.value < loan.borrowed) revert InsufficientRepayment();

        uint256 bonus = (loan.collateral * LIQUIDATION_BONUS) / 100;
        uint256 payout = loan.collateral + bonus;

        // Update state BEFORE transfer (checks-effects-interactions)
        totalBorrowed -= loan.borrowed;
        delete loans[borrower];

        _safeTransfer(msg.sender, payout);

        emit Liquidated(borrower, msg.sender, payout);
    }

    //  Views

    /**
     * @notice Returns the current utilization rate of the pool (0–100).
     */
    function utilizationRate() public view returns (uint256) {
        if (totalDeposits == 0) return 0;
        return (totalBorrowed * 100) / totalDeposits;
    }

    /**
     * @notice Returns the current borrow APY based on utilization.
     */
    function currentAPY() public view returns (uint256) {
        return BASE_INTEREST_RATE + utilizationRate() / 10;
    }

    /**
     * @notice Returns the health factor of a borrower's position.
     * @dev >125 = healthy, <125 = liquidatable, 999 = no active loan.
     */
    function healthFactor(address borrower) public view returns (uint256) {
        Loan memory loan = loans[borrower];
        if (loan.borrowed == 0) return 999;
        return (loan.collateral * 100) / loan.borrowed;
    }

    /**
     * @notice Returns the total amount owed on an active loan (principal + interest).
     */
    function amountOwed(address borrower) public view returns (uint256) {
        Loan memory loan = loans[borrower];
        if (loan.borrowed == 0) return 0;
        return
            loan.borrowed + _calculateInterest(loan.borrowed, loan.borrowedAt);
    }

    //  Internal

    /**
     * @dev Safe native token transfer using low-level call.
     */
    function _safeTransfer(address to, uint256 amount) internal {
        (bool success, ) = payable(to).call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    /**
     * @dev Calculates simple interest accrued over time.
     */
    function _calculateInterest(
        uint256 principal,
        uint256 since
    ) internal view returns (uint256) {
        uint256 elapsed = block.timestamp - since;
        uint256 apy = currentAPY();
        return (principal * apy * elapsed) / (365 days * 100);
    }

    //  Fallback

    receive() external payable {}
}
