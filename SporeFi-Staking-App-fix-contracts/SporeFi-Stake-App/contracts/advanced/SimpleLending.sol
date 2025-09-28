// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract RBTCStakingSystem {
    // Token storage
    mapping(address => uint256) public rBTCBalances;
    mapping(address => uint256) public ptBalances;
    mapping(address => uint256) public ytBalances;
    mapping(address => uint256) public paypalUSDBalances;
    
    // Token supplies
    uint256 public rBTCSupply;
    uint256 public ptSupply;
    uint256 public ytSupply;
    uint256 public paypalUSDSupply;
    
    address public owner;
    address public constant TEST_RIF_TOKEN = 0x19F64674D8A5B4E652319F5e239eFd3bc969A1fE;
    uint256 public btcPrice = 109549.70e18; // Initial price in wei
    uint256 public constant LIQUIDATION_THRESHOLD = 87000e18; // $87,000 in wei
    uint256 public constant FAUCET_AMOUNT = 10e18; // 10 rBTC
    
    struct Stake {
        uint256 rBTCAmount;
        uint256 testRIFAmount;
        uint256 ptAmount;
        uint256 ytAmount;
        bool active;
    }
    
    mapping(address => Stake) public stakes;
    mapping(address => bool) public hasClaimed;
    address[] public stakers;
    
    event Staked(address indexed user, uint256 rBTCAmount, uint256 testRIFAmount, uint256 ptAmount, uint256 ytAmount);
    event Unstaked(address indexed user, uint256 rBTCAmount, uint256 testRIFAmount);
    event PriceUpdated(uint256 newPrice);
    event CollateralLiquidated(address indexed user, uint256 rBTCAmount, uint256 testRIFAmount, uint256 paypalUSDAmount);
    event FaucetClaimed(address indexed user, uint256 amount);
    event Transfer(string indexed tokenType, address indexed from, address indexed to, uint256 value);
    
    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }
    
    constructor() {
        owner = msg.sender;
    }
    
    // Internal token functions
    function _mint(string memory tokenType, address to, uint256 amount) internal {
        if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("rBTC"))) {
            rBTCBalances[to] += amount;
            rBTCSupply += amount;
        } else if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("PT"))) {
            ptBalances[to] += amount;
            ptSupply += amount;
        } else if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("YT"))) {
            ytBalances[to] += amount;
            ytSupply += amount;
        } else if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("PYUSD"))) {
            paypalUSDBalances[to] += amount;
            paypalUSDSupply += amount;
        }
        emit Transfer(tokenType, address(0), to, amount);
    }
    
    function _transfer(string memory tokenType, address from, address to, uint256 amount) internal {
        if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("rBTC"))) {
            require(rBTCBalances[from] >= amount, "Insufficient rBTC balance");
            rBTCBalances[from] -= amount;
            rBTCBalances[to] += amount;
        } else if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("PT"))) {
            require(ptBalances[from] >= amount, "Insufficient PT balance");
            ptBalances[from] -= amount;
            ptBalances[to] += amount;
        } else if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("YT"))) {
            require(ytBalances[from] >= amount, "Insufficient YT balance");
            ytBalances[from] -= amount;
            ytBalances[to] += amount;
        }
        emit Transfer(tokenType, from, to, amount);
    }
    
    // Faucet function - mint rBTC tokens
    function claimFromFaucet() external {
        require(!hasClaimed[msg.sender], "Already claimed");
        hasClaimed[msg.sender] = true;
        _mint("rBTC", msg.sender, FAUCET_AMOUNT);
        emit FaucetClaimed(msg.sender, FAUCET_AMOUNT);
    }
    
    // Legacy stake function for backward compatibility
    function stake(uint256 amount) external {
        _stakeRBTC(amount);
    }
    
    // Stake rBTC tokens and receive PT/YT tokens
    function stakeRBTC(uint256 amount) external {
        _stakeRBTC(amount);
    }
    
    // Internal function for rBTC staking
    function _stakeRBTC(uint256 amount) internal {
        require(amount > 0, "Amount must be > 0");
        require(!stakes[msg.sender].active, "Already staking");
        require(rBTCBalances[msg.sender] >= amount, "Insufficient rBTC balance");
        
        // Transfer rBTC to contract
        _transfer("rBTC", msg.sender, address(this), amount);
        
        // Calculate PT and YT amounts (1:1 ratio)
        uint256 ptAmount = amount;
        uint256 ytAmount = amount;
        
        // Mint PT and YT tokens to user
        _mint("PT", msg.sender, ptAmount);
        _mint("YT", msg.sender, ytAmount);
        
        stakes[msg.sender] = Stake({
            rBTCAmount: amount,
            testRIFAmount: 0,
            ptAmount: ptAmount,
            ytAmount: ytAmount,
            active: true
        });
        
        stakers.push(msg.sender);
        emit Staked(msg.sender, amount, 0, ptAmount, ytAmount);
    }
    
    // Stake testRIF tokens and receive PT/YT tokens
    function stakeTestRIF(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        require(!stakes[msg.sender].active, "Already staking");
        
        // Transfer testRIF tokens from user to contract using low-level call
        (bool success,) = TEST_RIF_TOKEN.call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), amount)
        );
        require(success, "testRIF transfer failed");
        
        // Calculate PT and YT amounts (1:1 ratio)
        uint256 ptAmount = amount;
        uint256 ytAmount = amount;
        
        // Mint PT and YT tokens to user
        _mint("PT", msg.sender, ptAmount);
        _mint("YT", msg.sender, ytAmount);
        
        stakes[msg.sender] = Stake({
            rBTCAmount: 0,
            testRIFAmount: amount,
            ptAmount: ptAmount,
            ytAmount: ytAmount,
            active: true
        });
        
        stakers.push(msg.sender);
        emit Staked(msg.sender, 0, amount, ptAmount, ytAmount);
    }
    
    // Unstake tokens
    function unstake() external {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.active, "No active stake");
        
        uint256 rBTCAmount = userStake.rBTCAmount;
        uint256 testRIFAmount = userStake.testRIFAmount;
        userStake.active = false;
        
        // Transfer tokens back to user
        if (rBTCAmount > 0) {
            _transfer("rBTC", address(this), msg.sender, rBTCAmount);
        }
        if (testRIFAmount > 0) {
            (bool success,) = TEST_RIF_TOKEN.call(
                abi.encodeWithSignature("transfer(address,uint256)", msg.sender, testRIFAmount)
            );
            require(success, "testRIF transfer failed");
        }
        
        emit Unstaked(msg.sender, rBTCAmount, testRIFAmount);
    }
    
    // Set BTC price (owner only)
    function setPrice(uint256 newPrice) external onlyOwner {
        btcPrice = newPrice;
        emit PriceUpdated(newPrice);
        
        // Check if price is below liquidation threshold
        if (newPrice < LIQUIDATION_THRESHOLD) {
            _liquidateAllCollateral();
        }
    }
    
    // Internal function to liquidate all collateral
    function _liquidateAllCollateral() internal {
        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            Stake storage userStake = stakes[staker];
            
            if (userStake.active) {
                uint256 rBTCAmount = userStake.rBTCAmount;
                uint256 testRIFAmount = userStake.testRIFAmount;
                uint256 totalValue = (rBTCAmount * btcPrice) / 1e18 + (testRIFAmount * btcPrice) / 1e18; // Using BTC price for testRIF too
                
                // Mint PayPal USD to the user
                _mint("PYUSD", staker, totalValue);
                
                // Deactivate stake
                userStake.active = false;
                
                emit CollateralLiquidated(staker, rBTCAmount, testRIFAmount, totalValue);
            }
        }
    }
    
    // Manual liquidation trigger (owner only)
    function liquidateAllCollateral() external onlyOwner {
        require(btcPrice < LIQUIDATION_THRESHOLD, "Price above threshold");
        _liquidateAllCollateral();
    }
    
    // View functions
    function getBalance(address user, string memory tokenType) external view returns (uint256) {
        if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("rBTC"))) {
            return rBTCBalances[user];
        } else if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("PT"))) {
            return ptBalances[user];
        } else if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("YT"))) {
            return ytBalances[user];
        } else if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("PYUSD"))) {
            return paypalUSDBalances[user];
        }
        return 0;
    }
    
    function getStake(address user) external view returns (uint256, uint256, uint256, uint256, bool) {
        Stake memory userStake = stakes[user];
        return (userStake.rBTCAmount, userStake.testRIFAmount, userStake.ptAmount, userStake.ytAmount, userStake.active);
    }
    
    function getCurrentPrice() external view returns (uint256) {
        return btcPrice;
    }
    
    function getTotalStakers() external view returns (uint256) {
        return stakers.length;
    }
    
    function getTestRIFAddress() external pure returns (address) {
        return TEST_RIF_TOKEN;
    }
    
    function getTotalSupply(string memory tokenType) external view returns (uint256) {
        if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("rBTC"))) {
            return rBTCSupply;
        } else if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("PT"))) {
            return ptSupply;
        } else if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("YT"))) {
            return ytSupply;
        } else if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("PYUSD"))) {
            return paypalUSDSupply;
        }
        return 0;
    }
    
    // Emergency functions (owner only)
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        // This would be for withdrawing any accidentally sent tokens
        // For now, we'll just allow owner to mint tokens for recovery
        _mint("rBTC", owner, amount);
    }
    
    function updateOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}
