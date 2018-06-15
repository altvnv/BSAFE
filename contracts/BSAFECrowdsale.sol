pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "./KrakenPriceTicker.sol";
import "./DateTime.sol";

contract token {
    function transfer(address receiver, uint amount);
}

contract BSAFECrowdsale is KrakenPriceTicker, DateTime {

    using SafeMath for uint;

    enum Status {
        CREATED, 
        PRESALE,
        PRESALE_FINISHED,
        SALE,
        SALE_FINISHED
    }

    // Wallet where ETH collects
    address wallet;
    // Example of token to transfer tokens
    token public tokenReward;
    // Kraken USD oracle
    KrakenPriceTicker usdOracle;

    // Rate in cents
    // Price starts at 
    uint public baseRate = 50;

    // Presale max amount of tokens can be sold
    uint256 public presaleSupply = 32500000;

    // Status of crowdsale
    Status crowdsaleStatus;

    // Presale start timestamp
    uint256 public presaleStart;
    // Presale end timestamp
    uint256 public presaleEnd;
    // Sale start timestamp
    uint256 public saleStart;
    // Sale finish timestamp
    uint256 public saleEnd;

    uint presaleBonus = 25;
    uint juneBonus = 15;
    uint julyBonus = 10;
    uint lastBonus = 5;

    // Emits when presale is finished
    event PresaleFinished();
    // Emits when presale is started
    event PresaleStarted();
    // Emits when sale is finished
    event SaleFinished();
    // Emits when sale is started
    event SaleStarted();

    modifier onlyOwner() {
    	require(msg.sender == wallet);
    	_;
    }

    /**
    * @param _wallet Address of wallet where ETH stored
    * @param _usdOracle Address of oracle which returns USD Rate
    */
    function BSAFECrowdsale(address _wallet, address _usdOracle) {
    	require(_wallet != 0x0);
        require(_usdOracle !=0x0);
    	wallet = _wallet;
        // Initialize USD oracle
    	usdOracle = KrakenPriceTicker(_usdOracle);
        // Receive ETH price from Kraken in USD
    	usdOracle.update(0);
        tokenReward = token(0x14fda3b1e131ad2d40e98cff2722e7d22b96f88e);
        // Initializes status of crowdsale
        crowdsaleStatus = Status.CREATED;
    }

    /**
    * Starts presale
    */
    function startPresale() public onlyOwner {
        // We cannot start presale twice
    	require(crowdsaleStatus == Status.CREATED);
        presaleStart = now;
        presaleEnd = now + 30 days;
        crowdsaleStatus = Status.PRESALE;
        PresaleStarted();
    } 

    /**
    * Ends presale
    */
    function endPresale() public onlyOwner {
        require(crowdsaleStatus == Status.PRESALE);
        presaleEnd = now;
        crowdsaleStatus = Status.PRESALE_FINISHED;
        wallet.transfer(this.balance);
        PresaleFinished();
    }

    /**
    * Starts sale
    */
    function startSale() public onlyOwner {
        require(crowdsaleStatus == Status.PRESALE_FINISHED);
        // We cannot start sale twice
        require(saleStart == 0);
        saleStart = now;
        saleEnd = now + 60 days;
        crowdsaleStatus = Status.SALE;
        SaleStarted();
    }

    /**
    * Ends sale
    */
    function endSale() public onlyOwner {
        require(crowdsaleStatus == Status.SALE);
        saleEnd = now;
        crowdsaleStatus = Status.SALE_FINISHED;
        wallet.transfer(this.balance);
        SaleFinished();
    }

    /**
    * Calculates amount of tokens with bonus
    * @param weiAmount Amount of wei was sent
    * @return Amount of tokens should be transfered to investor
    */
    function calcAmountOfTokens(uint256 weiAmount) public returns (uint256) {
        // Updates ETH rate
        usdOracle.update(0);
        // Converts wei to USD cents
        uint256 centsAmount = weiAmount.mul(usdOracle.ETHUSD()).div(10**18);
        return centsAmount.mul(calcBonus()).div(100).div(baseRate);
    }

    /**
    * Calculates bonus by time
    * @return bonus in percents
    */
    function calcBonus() public returns (uint) {
        uint bonus = 100;

        // Retrieves current month and day
        uint16 month = getMonth(now);
        uint16 day = getDay(now);

        if (crowdsaleStatus == Status.PRESALE) {
            bonus += presaleBonus;
        } else {            
            if (month >= 7 && day >= 30) {
                bonus = 100;            
            } else if (month >= 7 && day >= 15) {
                bonus += lastBonus;
            } else if (month >= 7 && day >= 1) {
                bonus += julyBonus;
            } else if (month >= 6 && day >= 1) {
                bonus += juneBonus;
            }
        }

        return bonus;
    }

    function () public payable {
        // Checks if sale or presale was started
        require(crowdsaleStatus == Status.SALE || crowdsaleStatus == Status.PRESALE);
        
        uint256 tokenAmount = calcAmountOfTokens(msg.value);

        // Checks if there amount tokens to be sold
        if (crowdsaleStatus == Status.PRESALE) {
            require(tokenAmount <= presaleSupply);
            tokenReward.transfer(msg.sender, tokenAmount);
            presaleSupply.sub(tokenAmount);
        } else {
            tokenReward.transfer(msg.sender, tokenAmount);
        }
    }

    /**
    * Sets new base rate
    */
    function setBaseRate(uint newRate) public onlyOwner {
        require(newRate != 0);
        baseRate = newRate;
    }

    /**
     * Sets new presale bonus
     */
    function setPresaleBonus(uint bonus) public onlyOwner {
        presaleBonus = bonus;
    }

    /**
     * Sets new bonus after 1 June
     */
    function setJuneBonus(uint bonus) public onlyOwner {
        juneBonus = bonus;
    }

    /**
     * Sets new bonus after 1 July
     */
    function setJulyBonus(uint bonus) public onlyOwner {
        julyBonus = bonus;
    }

    /**
     * Sets new bonus after 15 July
     */
    function setLastBonus(uint bonus) public onlyOwner {
        lastBonus = bonus;
    }
}
