// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract PayPalUSDMinter {
    string public name = "Mock PayPal USD";
    string public symbol = "PYUSD";
    uint8 public decimals = 18;
    
    mapping(address => uint256) public balances;
    mapping(address => uint256) public stakedCollateral;
    mapping(address => uint256) public borrowedAmount;
    mapping(address => bool) public hasBorrowed;
    
    uint256 public totalSupply;
    uint256 public btcPrice = 65000 * 10**18; // Default BTC price in USD (with 18 decimals)
    uint256 public constant COLLATERAL_RATIO_MIN = 70; // 70%
    uint256 public constant COLLATERAL_RATIO_MAX = 80; // 80%
    
    address public owner;
    
    // PayPal USD contract address on mainnet (for reference only)
    address public constant PAYPAL_USD_MAINNET = 0x6c3ea9036406852006290770BEdFcAbA0e23A0e8;
    
    event TokensMinted(address indexed user, uint256 rBTCAmount, uint256 pyUSDAmount);
    event LoanCreated(address indexed user, uint256 collateralAmount, uint256 loanAmount);
    event PriceUpdated(uint256 newPrice);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    // Update BTC price (only owner)
    function updateBTCPrice(uint256 _newPrice) external onlyOwner {
        btcPrice = _newPrice;
        emit PriceUpdated(_newPrice);
    }
    
    // Mint PayPal USD based on rBTC deposit and current BTC rate
    function mintPayPalUSD() external payable {
        require(msg.value > 0, "Must deposit rBTC");
        
        // Calculate PayPal USD amount based on BTC price
        // msg.value is in wei (rBTC), btcPrice is in USD with 18 decimals
        uint256 pyUSDAmount = (msg.value * btcPrice) / 10**18;
        
        // Update user's staked collateral
        stakedCollateral[msg.sender] += msg.value;
        
        // Mint PayPal USD tokens
        balances[msg.sender] += pyUSDAmount;
        totalSupply += pyUSDAmount;
        
        emit TokensMinted(msg.sender, msg.value, pyUSDAmount);
    }
    
    // Create loan based on staked collateral
    function createLoan(uint256 _loanAmount) external {
        require(stakedCollateral[msg.sender] > 0, "No collateral staked");
        require(_loanAmount > 0, "Loan amount must be greater than 0");
        
        // Generate random collateral ratio between 70-80%
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.difficulty))) % 11;
        uint256 collateralRatio = COLLATERAL_RATIO_MIN + randomSeed; // 70-80%
        
        // Calculate maximum loan amount based on staked collateral and BTC price
        uint256 collateralValueUSD = (stakedCollateral[msg.sender] * btcPrice) / 10**18;
        uint256 maxLoanAmount = (collateralValueUSD * collateralRatio) / 100;
        
        require(_loanAmount <= maxLoanAmount, "Loan amount exceeds maximum allowed");
        require(borrowedAmount[msg.sender] + _loanAmount <= maxLoanAmount, "Total borrowed would exceed limit");
        
        // Update borrowed amount
        borrowedAmount[msg.sender] += _loanAmount;
        hasBorrowed[msg.sender] = true;
        
        // Mint PayPal USD tokens as loan
        balances[msg.sender] += _loanAmount;
        totalSupply += _loanAmount;
        
        emit LoanCreated(msg.sender, stakedCollateral[msg.sender], _loanAmount);
    }
    
    // Get user's PayPal USD balance
    function getBalance(address _user) external view returns (uint256) {
        return balances[_user];
    }
    
    // Get user's staked collateral
    function getStakedCollateral(address _user) external view returns (uint256) {
        return stakedCollateral[_user];
    }
    
    // Get user's borrowed amount
    function getBorrowedAmount(address _user) external view returns (uint256) {
        return borrowedAmount[_user];
    }
    
    // Get maximum loan amount for user
    function getMaxLoanAmount(address _user) external view returns (uint256) {
        if (stakedCollateral[_user] == 0) return 0;
        
        // Use average of min and max ratio for display purposes
        uint256 avgRatio = (COLLATERAL_RATIO_MIN + COLLATERAL_RATIO_MAX) / 2; // 75%
        uint256 collateralValueUSD = (stakedCollateral[_user] * btcPrice) / 10**18;
        return (collateralValueUSD * avgRatio) / 100;
    }
    
    // Get current BTC price
    function getBTCPrice() external view returns (uint256) {
        return btcPrice;
    }
    
    // Emergency withdraw (only owner)
    function emergencyWithdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
    
    // Transfer ownership
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        owner = _newOwner;
    }
    
    // Get contract balance
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
