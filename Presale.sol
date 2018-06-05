pragma solidity ^0.4.21;

import "./PapushaToken.sol";
import "./Crowdsale.sol";
import "./Ownable.sol";

contract Presale is Ownable {

    using SafeMath for uint;

    address public multisig;
    uint256 public rate;
    PapushaToken public token; //Token contract
    Crowdsale public crowdsale; // Crowdsale contract
    uint256 public hardcap;
    uint256 public weiRaised;

    uint256 public saleSupply = 60000000 * 1 ether;

    function Presale(address _multisig) public {
        multisig = _multisig;
        rate = 250000000000000;
        token = new PapushaToken();
        hardcap = 5000 * 1 ether;
    }

    modifier isUnderHardcap {
        require(weiRaised < hardcap);
        _;
    }

    function startCrowdsale() onlyOwner public returns(bool) {
        crowdsale = new Crowdsale(multisig, token, saleSupply);
        token.transfer(address(crowdsale), token.balanceOf(this));
        token.transferOwnership(address(crowdsale));
        crowdsale.transferOwnership(owner);
        return true;
    }

    function createTokens() isUnderHardcap payable public {
        uint256 weiAmount = msg.value;
        require(weiAmount <= hardcap - weiRaised);
        weiRaised = weiRaised.add(weiAmount);
        uint256 tokens = weiAmount.div(rate);
        require(saleSupply >= tokens);
        saleSupply = saleSupply.sub(tokens);
        token.transfer(msg.sender, tokens);
        forwardFunds(msg.value);
    }

    function forwardFunds(uint256 _value) private {
        multisig.transfer(_value);
    }

    function setPrice(uint256 _rate) onlyOwner public {
        rate = _rate;
    }

    function setMultisig(address _multisig) onlyOwner public {
        multisig = _multisig;
    }

    function() external payable {
        createTokens();
    }

}
