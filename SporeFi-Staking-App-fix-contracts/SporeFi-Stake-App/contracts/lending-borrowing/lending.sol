// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleLending {
    address public TRBTC_ADDRESS; // TrBTC contract address (to be set later)
    address public PAYPAL_USD_ADDRESS; // PayPal USD contract address (to be set later)
    address public USDRIF_ADDRESS; // USD RIF contract address (to be set later)
    
    enum RiskTier { LOW, MID, HIGH }
    
    struct Loan {
        uint256 collateralAmount;
        uint256 loanAmount;
        uint256 interestRate; // in basis points (100 = 1%)
        uint256 maturityTime;
        RiskTier riskTier;
        address loanToken; // PAYPAL_USD or USDRIF
        bool active;
    }
    
    mapping(address => Loan) public loans;
    
    // Risk tier parameters
    uint256[3] public borrowLimits = [30, 65, 90]; // 30%, 65%, 90%
    uint256[3] public interestRates = [300, 700, 1000]; // 3%, 7%, 10%
    uint256 public constant MATURITY_PERIOD = 30 days;
    
    function depositAndBorrow(
        uint256 collateralAmount,
        RiskTier riskTier,
        address loanToken
    ) external {
        require(!loans[msg.sender].active, "Active loan exists");
        require(loanToken == PAYPAL_USD_ADDRESS || loanToken == USDRIF_ADDRESS, "Invalid loan token");
        
        // Transfer collateral from user
        (bool success1,) = TRBTC_ADDRESS.call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), collateralAmount)
        );
        require(success1, "Collateral transfer failed");
        
        // Calculate loan amount based on risk tier
        uint256 loanAmount = (collateralAmount * borrowLimits[uint256(riskTier)]) / 100;
        
        // Create loan
        loans[msg.sender] = Loan({
            collateralAmount: collateralAmount,
            loanAmount: loanAmount,
            interestRate: interestRates[uint256(riskTier)],
            maturityTime: block.timestamp + MATURITY_PERIOD,
            riskTier: riskTier,
            loanToken: loanToken,
            active: true
        });
        
        // Transfer loan tokens to user
        (bool success2,) = loanToken.call(
            abi.encodeWithSignature("transfer(address,uint256)", msg.sender, loanAmount)
        );
        require(success2, "Loan transfer failed");
    }
    
    function repayLoan() external {
        Loan storage loan = loans[msg.sender];
        require(loan.active, "No active loan");
        
        // Calculate total repayment (principal + interest)
        uint256 interest = (loan.loanAmount * loan.interestRate) / 10000;
        uint256 totalRepayment = loan.loanAmount + interest;
        
        if (block.timestamp <= loan.maturityTime) {
            // Early repayment - user pays back loan tokens
            (bool success1,) = loan.loanToken.call(
                abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), totalRepayment)
            );
            require(success1, "Repayment failed");
            
            // Return full collateral
            (bool success2,) = TRBTC_ADDRESS.call(
                abi.encodeWithSignature("transfer(address,uint256)", msg.sender, loan.collateralAmount)
            );
            require(success2, "Collateral return failed");
        } else {
            // Maturity reached - deduct from collateral
            uint256 remainingCollateral = loan.collateralAmount > totalRepayment 
                ? loan.collateralAmount - totalRepayment 
                : 0;
            
            if (remainingCollateral > 0) {
                (bool success,) = TRBTC_ADDRESS.call(
                    abi.encodeWithSignature("transfer(address,uint256)", msg.sender, remainingCollateral)
                );
                require(success, "Collateral transfer failed");
            }
        }
        
        // Clear loan
        delete loans[msg.sender];
    }
    
    function getLoanDetails(address user) external view returns (
        uint256 collateral,
        uint256 loanAmount,
        uint256 interestRate,
        uint256 maturityTime,
        RiskTier riskTier,
        address loanToken,
        bool active
    ) {
        Loan memory loan = loans[user];
        return (
            loan.collateralAmount,
            loan.loanAmount,
            loan.interestRate,
            loan.maturityTime,
            loan.riskTier,
            loan.loanToken,
            loan.active
        );
    }
    
    // Admin function to set contract addresses
    function setAddresses(
        address _trbtc,
        address _paypalUsd,
        address _usdRif
    ) external {
        TRBTC_ADDRESS = _trbtc;
        PAYPAL_USD_ADDRESS = _paypalUsd;
        USDRIF_ADDRESS = _usdRif;
    }
}