
// Imp Starter Project - Device code
///
// Robert Glaser, August 3, 2018
//
// last modified: August 3, 2018
//
// invoke with agenturl +:
//
// ?LED to pulse LED on pinM
//
// ?Status to get current state
//
function DateTime() {
    return ((date().month+1) + "/" + date().day + "/" + date().year + " " + date().hour + ":" + date().min + ":" + date().sec);
    }

server.log("Hello from JHU! " + DateTime());
server.log("Device firmware version: " + imp.getsoftwareversion());

StatusMessage <- "Device Startup " + DateTime();
LastpinD <- false;
LastpinE <- false;
ReadpinD <- null;
ReadpinE <- null;

// Interface pins
LED <- hardware.pinM;
pinD <- hardware.pinD;
pinE <- hardware.pinE;


curMove <- "";
wMoved <- false;
bMoved <- false;

uartTester <- true;
uartTesterInt <- 0;
function serialTester(){



}


serial <- hardware.uartHJ;
serial.configure(9600,8,PARITY_NONE,1,NO_CTSRTS,serialTester);

// Configure the digital outputs with a starting value of digital 0 (low, 0V)
LED.configure(DIGITAL_OUT, 0);

function Status(value) {
    ReadpinDpinE();
    local pinDMessage = "<br>(pinD is high)";
    if (ReadpinD) {pinDMessage = "<br>pinD is <FONT COLOR='#FF0000'>LOW</FONT><FONT COLOR='#FFFF00'>!"};
    local pinEMessage = "<br>(pinE is high)";
    if (ReadpinE) {pinEMessage = "<br>pinE is <FONT COLOR='#FF0000'>LOW</FONT><FONT COLOR='#FFFF00'>!"};
    agent.send("Status", DateTime() + "<br>" + StatusMessage + pinDMessage + pinEMessage);
    }

function PulseLED(dummy) {
    server.log("Pulsed LED " + DateTime());

    LED.write(1);
    imp.sleep(0.25);
    LED.write(0);
    }


function sendMoveAgent(move) {
    agent.send("saveMove",move);
}

function getMove(trash) {
    agent.send("getMove",trash);
}

curBMove <- "";
local bMoveList = [];//FOR TESTING ONLY
bMoveList.append("0,1;0,3");
bMoveList.append("1,1;1,3");
bMoveList.append("2,1;2,3");
bMoveList.append("3,1;3,3");
bMoveList.append("4,1;4,3");
bMoveList.append("5,1;5,3");
bMoveList.append("6,1;6,3");
bMoveList.append("7,1;7,3");
local tester = 0;


function processMove(move) {

    if (move != curMove){
        wMoved = true;
    }
    //server.log("server sent: " + move);
    curMove = move;

}

function sendMoveArduino(move){
    //server.log(move + "move sent to arduino");
    serial.write("z");
    serial.write(move);
    server.log("Device sent: " + move + " to arduino.");
}

moveString <- "";
charsRead <- 0;
detected <- false;
read <- false;
function addSingleChar(){
    moveString += serial.readstring(1);
    if (charsRead <= 7 && read){
        imp.wakeup(3,addSingleChar);
        charsRead ++;
    } else {
        charsRead = 0;
        detected = false;
        read = false;
    }
}

index <- "n";
function flushToMove(){
    if (index != 'm'){
        index = serial.readstring(1);

        imp.wakeup(1,flushToMove);
    } else {
        return true;
    }
}

function getMoveArduino(){


    local aMove = serial.readstring();
    local indexOfM = aMove.find("m");
    if (indexOfM == null){
        return false;
    }

    aMove = aMove.slice(indexOfM + 1, indexOfM + 9);
    server.log("d: " + aMove);
    for (local i = 0; i < 4; i ++){
        if (!isDigit(aMove.slice(i*2, i*2+1))){
            return false;
        }
    }
    if (aMove.slice(7,8) != "."){
        return false;
    }
    server.log("aMove: " + aMove);
    server.log("curBMove: " + curBMove);
    if (aMove == curBMove){

        return false;
    }
    server.log("Arduino sent their move");
    curBMove = aMove;
    bMoved = true;

    /*
    local aMove = serial.readstring(1);


    //aMove = aMove &255;

    if (aMove != "" && aMove != " "){
        detected = true;
        read = true;
    }
    if (detected){
        moveString += aMove;
        addSingleChar();
    }
    if (curBMove != moveString){
        if (moveString.len() == 7){

            if (isDigit(moveString)){
                //server.log(moveString);

                curBMove = moveString;
                bMoved = true;
                moveString = "";
            }

        }
    }
    */



}
function isDigit(string){
    local id = string.slice(0,1);
    if (id == "1"){
        return true;
    }
    if (id == "2"){
        return true;
    }
    if (id == "3"){
        return true;
    }
    if (id == "4"){
        return true;
    }
    if (id == "5"){
        return true;
    }
    if (id == "6"){
        return true;
    }
    if (id == "7"){
        return true;
    }
    if (id == "8"){
        return true;
    }
    if (id == "9"){
        return true;
    }
    if (id == "0"){
        return true;
    }
    return false;
}

function flush(){
    local c = serial.read();
    for (local flusher = 0; flusher < 80; flusher++){
        c = serial.read();
    }
}

maxTurns <- 150;
turns <- 0;
wMovePart <- false;
bMovePart <- false;
function attemptTurn(){

    if (wMovePart && bMovePart){
        server.log("turn completed");
        wMoved = false;
        bMoved = false;
        wMovePart = false;
        bMovePart = false;

        turns ++;
    }

    if (wMoved){
        wMovePart = true;
        sendMoveArduino(curMove);
        server.log("white's move: " + curMove);

        if (bMoved){
            bMovePart = true;

            sendMoveAgent(curBMove);
            server.log("black's move: " + curBMove);

        } else {
            //make black move
            //get move from arduino and store it to
            //local variable

            getMoveArduino();

        }
    } else {
        //make white move
        getMove(1);
    }

    if (turns < maxTurns){
        imp.wakeup(5,attemptTurn);
    }
}

function turnLooper(){
    for (local i = 0; i < 5; i ++){
        imp.sleep(1);
    }
}



function test(t){
    server.log("test successful");
}


pinD.configure(DIGITAL_IN_PULLUP);
pinE.configure(DIGITAL_IN_PULLUP);

// Register handlers
agent.on("PulseLED", PulseLED);
agent.on("sentMove", processMove);

agent.on("test", test);

//flush();
attemptTurn();