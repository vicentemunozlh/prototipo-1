// segunda version de la polla donde el jugador ingresa toda su apuesta en una funcion.
// Esta programado para 3 partidos, pero si se quiere modificar basta con cambiar los uint8[3] => uint8[#]

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

error Polla_NotAmountToEnter();

contract Polla is Ownable {
    address payable[] private players; //se deben agregar estos para crearlo como que cada adress entra por si solo
    mapping(address => uint256) balances; // para mapear que el address puede entrar solo 1 vez
    address payable public recentWinner;
    // ahora se enumera los estados posibles de la polla
    uint256 private immutable i_entry_fee = 10000000000000000;

    // aca se determina el estado de la polla, esta empezando, esta cerrada o se esta calculando el ganador
    enum POLLA_STATE {
        RECEIVING,
        NOTRECEIVING,
        MUNDIALENDED,
        CALCULATING_WINNER,
        CLOSED
    }
    POLLA_STATE public polla_state;

    struct Participante {
        uint256 puntaje;
    }
    mapping(address => Participante) public addressToPuntaje; // aca se genera el mapeado para poder encontrar el puntaje actual de algun participante

    /* Events*/
    event PollaEnter(address indexed player);
    event PlayerElections(uint8[3] elections);

    function enterPolla() public payable {
        // 0.01 ETH entrance
        if (msg.value != i_entry_fee) {
            revert Polla_NotAmountToEnter();
        }
        require(balances[msg.sender] == 0, "Player already in Polla!"); // se define si el participante ya participó anteriormente, esto puede cambiarse si no se quiere esta restricción
        require(polla_state == POLLA_STATE.RECEIVING, "Polla is closed!");
        balances[msg.sender] += msg.value;
        players.push(payable(msg.sender));
        // participantes.push(Participante(msg.sender,0));
        addressToPuntaje[msg.sender].puntaje = 0;
        emit PollaEnter(msg.sender);
    }

    function startPolla() public onlyOwner {
        require(polla_state == POLLA_STATE.CLOSED, "Can't start a new polla yet!");
        polla_state = POLLA_STATE.RECEIVING;
    }

    struct EleccionesJugadorPartidos {
        uint8[3] elecciones;
        bool eleccionRealizada;
    }

    mapping(address => EleccionesJugadorPartidos) addressToEleccions;

    function EleccionesJugador(uint8[3] memory _elecciones) public {
        require(polla_state == POLLA_STATE.RECEIVING, "Polla is not receiving bets!");
        require(balances[msg.sender] > 0, "Player not in Polla!"); // se define si el participante ya participó anteriormente, esto puede cambiarse si no se quiere esta restricción
        //require(_elecciones.length ==64, "Son 64 elecciones! no mas ni menos") se elimina este require para ahorrar gas fee, por definicion no se deberian poder entregar mas o menos valores que 64
        for (uint256 p = 0; p < _elecciones.length; p++) {
            require(
                _elecciones[p] < 3,
                "Admisible values are: 0=>Gana Local  ; 1=>GanaVisita ; 2 => empate"
            );
        }
        addressToEleccions[msg.sender].elecciones = _elecciones;
        addressToEleccions[msg.sender].eleccionRealizada = true;
        emit PlayerElections(_elecciones);
    }

    function vereleccionpartidox(address _address, uint8 partido)
        public
        view
        returns (uint8 Eleccion)
    {
        Eleccion = addressToEleccions[_address].elecciones[partido];
        return Eleccion;
    }

    function EmpiezaMundial() public onlyOwner {
        require(polla_state == POLLA_STATE.RECEIVING, "Polla closed or not started!");
        polla_state = POLLA_STATE.NOTRECEIVING;
    }

    function TerminaMundial() public onlyOwner {
        require(
            polla_state == POLLA_STATE.NOTRECEIVING,
            "Polla has to be started and stoped reciving!"
        );
        polla_state = POLLA_STATE.MUNDIALENDED;
    }

    function QuienGanoPartidos(uint8[3] memory _partidos_ganados_por) public onlyOwner {
        // en esta parte se determina el ganador del partido, la idea es que los resultados vengan de una api y no se tengan que agregar manualmente
        require(polla_state == POLLA_STATE.MUNDIALENDED, "Mundial has not ended yet!");
        for (uint256 p = 0; p < _partidos_ganados_por.length; p++) {
            require(
                _partidos_ganados_por[p] < 3,
                "Admisible values are: 0=>Gana Local  ; 1=>GanaVisita ; 2 => empate"
            );
        }
        for (uint256 p = 0; p < players.length; p++) {
            if (addressToEleccions[players[p]].eleccionRealizada == true) {
                for (uint256 j = 0; j < _partidos_ganados_por.length; j++) {
                    if (addressToEleccions[players[p]].elecciones[j] == _partidos_ganados_por[j]) {
                        addressToPuntaje[players[p]].puntaje += 3;
                    }
                }
            }
        }
        polla_state = POLLA_STATE.CALCULATING_WINNER;
    }

    uint256 indexOfWinner = 0;

    function endPollaAndCalculateWinner() public onlyOwner {
        require(
            polla_state == POLLA_STATE.CALCULATING_WINNER,
            "Mundial needs to end and polla calculate points!"
        );
        // Ahora se calcula el winner, pasando por las address que estan jugando y viendo su puntaje gracias al mapping addressToPuntaje
        uint256 PuntajeMaximo = 0;
        for (uint256 p = 0; p < players.length; p++) {
            if (addressToPuntaje[players[p]].puntaje > PuntajeMaximo) {
                PuntajeMaximo = addressToPuntaje[players[p]].puntaje;
                indexOfWinner = p;
            }

            // Falta poner un else por si existe mas de 1 ganador de la polla (ejemplo: dos con el mismo puntaje).
        }
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance); // terminologia sacada de lottery.sol, revisar si esta correcto
        players = new address payable[](0);
        polla_state = POLLA_STATE.CLOSED;
    }

    function getPOLLA_STATE() public view returns (POLLA_STATE) {
        return polla_state;
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entry_fee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return players[index];
    }
}
