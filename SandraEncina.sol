// SPDX-License-Identifier: MIT
pragma solidity >0.7.0 <0.9.0;

contract RegistrySandraEncina {
    string mensaje;

    function getMensajeSandra() public view returns(string memory){
        return mensaje;
    }

    function setMensajeSandra(string calldata _mensaje) public {
        mensaje = _mensaje;
    }
}