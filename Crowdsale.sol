pragma solidity ^0.4.10;

import "./PapushaToken.sol";
import "./Ownable.sol";

contract Crowdsale is Ownable {

    using SafeMath for uint;

    address public multisig;
    uint256 public rate;
    PapushaToken public token; //Token contract
    uint256 public saleSupply;
    uint256 public saledSupply;
    bool public saleStopped;
    bool public sendToTeam;

    uint256 public RESERVED_SUPPLY = 40000000 * 1 ether;
    uint256 public BONUS_SUPPLY = 20000000 * 1 ether;

    function Crowdsale(address _multisig, PapushaToken _token, uint _saleSupply) public {
        multisig = _multisig;
        token = _token;
        saleSupply = _saleSupply;
        saleStopped = false;
        sendToTeam = false;
    }

    modifier saleNoStopped() {
        require(saleStopped == false);
        _;
    }

    function stopSale() onlyOwner public returns(bool) {
        if (saleSupply > 0) {
            token.burn(saleSupply);
            saleSupply = 0;
        }
        saleStopped = true;
        return token.stopSale();
    }

    function createTokens() payable public {
        if (saledSupply < BONUS_SUPPLY) {
            rate = 360000000000000;
        } else {
            rate = 410000000000000;
        }
        uint256 tokens = msg.value.div(rate);
        require(saleSupply >= tokens);
        saleSupply = saleSupply.sub(tokens);
        saledSupply = saledSupply.add(tokens);
        token.transfer(msg.sender, tokens);
        forwardFunds(msg.value);
    }

    function adminSendTokens(address _to, uint256 _value) onlyOwner saleNoStopped public returns(bool) {
        require(saleSupply >= _value);
        saleSupply = saleSupply.sub(_value);
        saledSupply = saledSupply.add(_value);
        return token.transfer(_to, _value);
    }

    function adminRefundTokens(address _from, uint256 _value) onlyOwner saleNoStopped public returns(bool) {
        saleSupply = saleSupply.add(_value);
        saledSupply = saledSupply.sub(_value);
        return token.refund(_from, _value);
    }

    function refundTeamTokens() onlyOwner public returns(bool) {
        require(sendToTeam == false);
        sendToTeam = true;
        return token.transfer(msg.sender, RESERVED_SUPPLY);
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
