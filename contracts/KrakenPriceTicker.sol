/*
   Kraken-based ETH/USD price ticker

   This contract keeps in storage an updated ETH/USD price,
   which is optionally updated every ~60 seconds.
*/

pragma solidity ^0.4.18;
import "./oraclizeAPI.sol";

contract KrakenPriceTicker is usingOraclize {

    uint public ETHUSD;

    event newOraclizeQuery(string description);
    event newKrakenPriceTicker(string price);

    function KrakenPriceTicker() {
        oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
        update(0);
    }

    function __callback(bytes32 myid, string result, bytes proof) {
        if (msg.sender != oraclize_cbAddress()) throw;
        newKrakenPriceTicker(result);
        ETHUSD = parseInt(result, 2); // save it in storage as $ cents
       
    }

    function update(uint delay) payable {
        if (oraclize_getPrice("URL") > this.balance) {
            newOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            newOraclizeQuery("Oraclize query was sent, standing by for the answer..");
            oraclize_query(delay, "URL", "json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHZUSD.c.0");
        }
    }

} 
