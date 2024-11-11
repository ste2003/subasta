// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract SubastaSandra {
    //variables de estado
    uint256 private startDate;    
    uint256 private maxPrice;
    address private maxAddr;    
    address private owner;    
    // estructura para ofertantes: direccion del ofertante y valor de la oferta
    struct Bidder {
        address bidderAddr;
        uint256 price; 
    }
    // estructura para registrar el balance y el ultimo valor que ofertó
    struct Record {
        address bidderAddr;
        uint256 price;
        uint256 balance;
    }
    // array para guardar todas las ofertas
    Bidder[] private bidders;
    // mapping para llevar el balance
    mapping (address => Record) public balance;  
    // array de direcciones únicas
    address[] private uniqueAddrs;

    //eventos nueva oferta y fin de subasta
    event NewBidCreated(address indexed addrBidder, uint256 price);
    event EndSubasta(uint256 maxAddr, uint256 maxPrice);
    //constructor registra el dueño del contrato y la hora de inicio
    constructor() {
        owner = msg.sender;
        startDate = block.timestamp;        
    }
    // modificador que habilita solo al dueño del contrato
     modifier onlyOwner() {
        require(msg.sender == owner, "No autorizado");
        _; 
    }
    //modificador para verificar si se cumplio el tiempo establecido
     modifier timeOut(){
        require(block.timestamp < startDate + 10 minutes, "La subasta termino");
        _;                    
    }
    //modificador para verificar si la nueva oferta es mayor en un 5% 
    modifier isGreater(){
        require(msg.value > maxPrice + maxPrice * 5 / 100, "No superaste");
        _;
    }
    //modificador para verificar si tiene balance para devolver
    modifier hasBalance(){
        require(balance[msg.sender].balance > maxPrice, "Nada a devolver");
        _;
    }
    //funcion para ofertar. Utiliza dos modificadores:
    //  timeout: verifica si la subasta está activa
    //  isGreater: si el valor es mayor 
    // Guarda la oferta en el array de ofertas: bidders
    // Actualiza el balance del ofertante: balance
    // Guarda un array de direcciones únicas: uniqueAddrs 
    // Actualiza el tiempo: startDate, precio máximo ofrecido: maxPrice y 
    //  dirección del ofertante mayor: maxAddr
    function bid() external payable timeOut isGreater {        
        address _addrBidder = msg.sender; 
        uint256 _price = msg.value;
        bidders.push(Bidder(_addrBidder, _price));        
        if(balance[_addrBidder].balance==0){
            uniqueAddrs.push(_addrBidder);                
        }
        balance[_addrBidder].balance +=_price;
        balance[_addrBidder].price =_price;
        startDate = block.timestamp;     
        maxPrice = _price ;
        maxAddr = _addrBidder;
    
        emit NewBidCreated(_addrBidder, _price);
    } 

    //función para mostrar todas las ofertas
    function showBids() external  view returns (Bidder[] memory){
        return bidders;
    }

    // función para mostrar el ofertante ganador y el valor de la oferta ganadora
    function getWinner() external view returns(address, uint256) {
        return (maxAddr, maxPrice);
    }
    // funcion privada para devolver. 
    // Recibe dos parametros: direccion y valor a transferir
    // Es invocada por las función partialRefund y endRefund
    function  refund(address _addr, uint256 _value) private{
        uint256 _valueAfterGas = (_value) - (_value) * 2 / 100; // resto el 2 % de gas
        address payable _receiver = payable(_addr);
        _receiver.transfer(_valueAfterGas);      
        // actualizo la suma, restando lo que se devolvio
        balance[_addr].balance -=_value; 
    }
    //funcion para devolucion parcial
    function partialRefund() external hasBalance{
        address _addrToRefund = msg.sender;
        uint256 _balance = balance[_addrToRefund].balance;
        uint256 _price = balance[_addrToRefund].price;
        uint256 _difference = (_balance - _price) ;
        refund(_addrToRefund, _difference); 
    }
    //funcion para rescatar el balance del contrato, solo habilitada para el dueño
    function withdraw() external onlyOwner{
        require(block.timestamp > startDate + 10 minutes, "La subasta no termino");
        payable(msg.sender).transfer(address(this).balance); // retira el dueño del contrato
    }
    //funcion para devolver los depositos una vez finalizada la subasta
    function endRefund() external onlyOwner{
        require(block.timestamp > startDate + 10 minutes, "La subasta no termino");
        // prize to winner
        refund(maxAddr, maxPrice);
        //return to rest of bidders
        uint256 len = uniqueAddrs.length;
        for(uint256 i=0; i< len; i++){
            if(balance[uniqueAddrs[i]].balance>0) {
                refund(uniqueAddrs[i], balance[uniqueAddrs[i]].balance);
            }
        }
    } 
}
  