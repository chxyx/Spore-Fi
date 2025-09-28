SporeFi
Introduction

SporeFi is a Fullstack Web3 + AI application built on Rootstock (RSK). Our platform introduces an innovative yield tokenization protocol that allows users to separate their staked positions into Principal Tokens (PT) and Yield Tokens (YT). By integrating AI-powered strategies, we optimize yield management and trading strategies, enabling users to maximize their returns efficiently.

📺 Project Flow

(Insert your YouTube demo link here if needed)

🛠 Tech Stack
Frontend:

ReactJS

TailwindCSS

HTML, CSS

Backend:

FastAPI

Python

Smart Contracts:

Solidity

Contracts Deployed on: Rootstock Testnet

Stablecoin Integration: PayPal USD for smooth loan transfers and off-ramping

Wallet Used: MetaMask

APIs Used:

DefiLlama

Coingecko

🌟 Features
🔹 Yield Tokenization on Rootstock

Staking Tokens: Users stake supported assets on Rootstock and earn staking rewards over time.

Standardized Yield (SY) Tokens: Wrapped staked positions into SY tokens representing principal + future yield.

Token Separation:

Principal Tokens (PT): Right to redeem the original staked amount at maturity.

Yield Tokens (YT): Capture all future yield until maturity.

Automated Market Maker (AMM): A simple AMM for trading PT and YT tokens seamlessly.

🔹 Use Cases

Liquidity Access: Users can trade YT tokens without unstaking their original assets.

Guaranteed Returns: Sell YT for immediate value while holding PT until maturity.

Yield Speculation: Traders can buy YT tokens to speculate on yield rates.

PayPal USD Integration: Enables seamless off-ramping and cross-platform transfers.

 AI-Powered Yield Optimization

Our AI-driven strategies enhance decision-making for staking, token splits, and trading strategies.

1️⃣ Predictive Yield Model (LSTM)

Long Short-Term Memory (LSTM) models predict staking yield rates by analyzing past trends and market conditions.

Input Data: Historical yield rates, staking trends, and market volatility.

Output: Predicted yield rates for the next 30 days.

Impact: Helps users anticipate yield fluctuations for optimized staking strategies.

2️⃣ Reinforcement Learning Model (PPO)

Proximal Policy Optimization (PPO) dynamically learns optimal PT/YT split strategies based on forecasts and AMM data.

Goal: Maximize staking efficiency and liquidity access.

Decision-making:

If yield is high → Favor PT.

If yield is volatile → Favor YT for speculative gains.

Implementation: Uses real-time AMM data for dynamic decision-making.

3️⃣ Risk-Aware Portfolio Model (Kelly Criterion)

The Kelly Criterion ensures that the strategy remains within an acceptable risk threshold.

Risk Assessment: Ensures YT allocation does not exceed a certain volatility level.

Portfolio Balance: Adjusts positions based on market conditions to minimize risk.

 Example AI Strategy:

LSTM predicts yield rate for the next 30 days.

PPO agent learns the best PT/YT split ratio (e.g., 70% PT, 30% YT).

Risk Model ensures the YT portion stays below a volatility threshold.

 Installation & Usage
1. Clone the Repository
 git clone https://github.com/your-repo/SporeFi.git
 cd SporeFi

2. Backend Setup (FastAPI)
 cd backend
 python -m venv venv
 source venv/bin/activate  # On Windows use `venv\Scripts\activate`
 pip install -r requirements.txt
 uvicorn main:app --reload

3. Frontend Setup (ReactJS)
 cd frontend
 npm install
 npm start

4. Smart Contract Deployment

(Though contracts are already deployed, if someone wants to deploy their own:)

 cd contracts
 npx hardhat compile
 npx hardhat test
 npx hardhat deploy --network rsk-testnet

Future Enhancements

Cross-Chain Support: Expanding the protocol beyond Rootstock.

AI-Enhanced AMM: Dynamic yield-based AMM pricing & AI Aggregators.

Multi-Asset Support: Extending beyond initial tokens & automated security.

Advanced Risk Management Models.
