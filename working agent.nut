#require "rocky.agent.lib.nut:3.0.0"


server.log("Agent started (version: " + imp.getsoftwareversion() + ")");
server.log("Command: " + http.agenturl() + "?Status");
savedResponse <- null;

const HTML_STRING = @"<!DOCTYPE html>

<head>
    <title>Chess(Multiplayer)</title>
    <meta charset='UTF-8'>
	<script src='https://code.jquery.com/jquery-3.5.1.min.js'></script>
	<script>
		const BOARD_WIDTH = 8;
		const BOARD_HEIGHT = 8;

		const TILE_SIZE = 50;
		const WHITE_TILE_COLOR = 'rgb(255, 228, 196)';
		const BLACK_TILE_COLOR = 'rgb(206, 162, 128)';
		const HIGHLIGHT_COLOR = 'rgb(75, 175, 75)';
		const WHITE = 0;
		const BLACK = 1;

		const EMPTY = -1;
		const PAWN = 0;
		const KNIGHT = 1;
		const BISHOP = 2;
		const ROOK = 3;
		const QUEEN = 4;
		const KING = 5;

		const INVALID = 0;
		const VALID = 1;
		const VALID_CAPTURE = 2;

		const piecesCharacters = {
			0: '♙',
			1: '♘',
			2: '♗',
			3: '♖',
			4: '♕',
			5: '♔'
		};

		let chessCanvas;
		let chessCtx;
		let currentTeamText;
		let whiteCasualitiesText;
		let blackCasualitiesText;
		let totalVictoriesText;

		let board;
		let currentTeam;

		let curX;
		let curY;
		let tempX;
		let tempY;

		let whiteCasualities;
		let blackCasualities;

		let whiteVictories;
		let blackVictories;

		//my stuff
		let lastX;
		let lastY;
		let startBlack = false;

		document.addEventListener('DOMContentLoaded', onLoad);

		function onLoad() {
			chessCanvas = document.getElementById('chessCanvas');
			chessCtx = chessCanvas.getContext('2d');
			chessCanvas.addEventListener('click', onClick);

			currentTeamText = document.getElementById('currentTeamText');

			whiteCasualitiesText = document.getElementById('whiteCasualities');
			blackCasualitiesText = document.getElementById('blackCasualities');

			totalVictoriesText = document.getElementById('totalVictories');
			whiteVictories = 0;
			blackVictories = 0;

			startGame();
		}

		function startGame() {
			board = new Board();
			curX = -1;
			curY = -1;

			currentTeam = WHITE;
			turn.textContent = 'W';
			currentTeamText.textContent = 'No Moves Yet';

			whiteCasualities = [0, 0, 0, 0, 0];
			blackCasualities = [0, 0, 0, 0, 0];

			repaintBoard();
			updateWhiteCasualities();
			updateBlackCasualities();
			updateTotalVictories();
		}

		function onClick(event) {
			let chessCanvasX = chessCanvas.getBoundingClientRect().left;
			let chessCanvasY = chessCanvas.getBoundingClientRect().top;
			let x = 0;
			let y = 0;


			if (currentTeam == WHITE){
				turn.textContent = 'W';

				x = Math.floor((event.clientX-chessCanvasX)/TILE_SIZE);
				y = Math.floor((event.clientY-chessCanvasY)/TILE_SIZE);

				let cur = curX + ',' + curY;
				let select = x.toString() + ',' + y.toString();

				currentTeamText.textContent = cur + ';' + select;

				tempX = curX;
				tempY = curY;




				/*--------------------------------------------

				IMP SIDE:

				CONSTANTLY SCAN FIRST LINE IN BODY, IGNORE W

				WHEN B, REALIZE IT IS IMP TURN

				READ NEXT LINE FOR WHITE MOVES, THEN UPDATE

				---------------------------------------------*/


			}

			if (currentTeam == BLACK){
				turn.textContent = 'B';

				//https://agent.electricimp.com/XoyF0bAQPMCg/getMove


				const bMoveURL = 'https://agent.electricimp.com/XoyF0bAQPMCg/getMove';


				const request = async() => {
				    const response = await fetch(bMoveURL);
				    const text = await response.text();

				    let readMove = text.substring(94,101);

				    turn.textContent = text;
				    let start = 0;
				    let passh1 = false;
				    let test = text.substring(start,start+1);
				    for (let i = 0; i < text.length; i ++){
				        if (!Number.isNaN(parseInt(text.substring(i,i+1)))){
				            if (!passh1){
				                passh1 = true;
				            } else {

				                start = i;
				                i += 999;
				            }
				        }
				    }
				    readMove = text.substring(start, start+7);
				    turn.textContent = readMove;

	    			let x1 = parseInt(readMove.substring(0,1));
		    		let y1 = parseInt(readMove.substring(2,3));
			    	let x2 = parseInt(readMove.substring(4,5));
				    let y2 = parseInt(readMove.substring(6,7));

	    			turn.textContent = '' + x1 + y1 + x2 + y2;


		    		if (startBlack == false){
			    	    x = x1;
				        y = y1;
			    	    startBlack = true;
			            currentTeamText.textContent = '' + x1 + y1;
			        } else {
			        	x = x2;
			        	y = y2;
			        	currentTeamText.textContent = '' + x2 + y2;
		    	    }

		    	    curX = x1;
		    	    curY = y1;

		    	    moveSelectedPiece(x2,y2);
		    	    changeCurrentTeam();
				}
				request();



			}

			if (checkValidMovement(x, y) === true) {
				if (checkValidCapture(x, y) === true) {
					if (board.tiles[y][x].pieceType === KING) {
						if (currentTeam === WHITE) whiteVictories++;
						else blackVictories++;

						startGame();
					}

					if (currentTeam === WHITE) {
						blackCasualities[board.tiles[y][x].pieceType]++;
						updateBlackCasualities();
					} else {
						whiteCasualities[board.tiles[y][x].pieceType]++;
						updateWhiteCasualities();
					}
				}

				moveSelectedPiece(x, y);

                setLocation(''+tempX+tempY+x+y);

				changeCurrentTeam();
			} else {
				curX = x;
				curY = y;
			}

			repaintBoard();
		}

		function checkPossiblePlays() {
			if (curX < 0 || curY < 0) return;

			let tile = board.tiles[curY][curX];
			if (tile.team === EMPTY || tile.team !== currentTeam) return;

			drawTile(curX, curY, HIGHLIGHT_COLOR);

			board.resetValidMoves();

			if (tile.pieceType === PAWN) checkPossiblePlaysPawn(curX, curY);
			else if (tile.pieceType === KNIGHT) checkPossiblePlaysKnight(curX, curY);
			else if (tile.pieceType === BISHOP) checkPossiblePlaysBishop(curX, curY);
			else if (tile.pieceType === ROOK) checkPossiblePlaysRook(curX, curY);
			else if (tile.pieceType === QUEEN) checkPossiblePlaysQueen(curX, curY);
			else if (tile.pieceType === KING) checkPossiblePlaysKing(curX, curY);
		}

		function checkPossiblePlaysPawn(curX, curY) {
			let direction;

			if (currentTeam === WHITE) direction = -1;
			else direction = 1;

			if (curY+direction < 0 || curY+direction > BOARD_HEIGHT-1) return;

			// Advance one tile
			checkPossibleMove(curX, curY+direction);

			// First double move
			if (curY === 1 || curY === 6) {
				checkPossibleMove(curX, curY+2*direction);
			}

			// Check diagonal left capture
			if (curX-1 >= 0) checkPossibleCapture(curX-1, curY+direction);

			// Check diagonal right capture
			if (curX+1 <= BOARD_WIDTH-1) checkPossibleCapture(curX+1, curY+direction);
		}

		function checkPossiblePlaysKnight(curX, curY) {
			// Far left moves
			if (curX-2 >= 0) {
				// Upper move
				if (curY-1 >= 0) checkPossiblePlay(curX-2, curY-1);

				// Lower move
				if (curY+1 <= BOARD_HEIGHT-1) checkPossiblePlay(curX-2, curY+1);
			}

			// Near left moves
			if (curX-1 >= 0) {
				// Upper move
				if (curY-2 >= 0) checkPossiblePlay(curX-1, curY-2);

				// Lower move
				if (curY+2 <= BOARD_HEIGHT-1) checkPossiblePlay(curX-1, curY+2);
			}

			// Near right moves
			if (curX+1 <= BOARD_WIDTH-1) {
				// Upper move
				if (curY-2 >= 0) checkPossiblePlay(curX+1, curY-2);

				// Lower move
				if (curY+2 <= BOARD_HEIGHT-1) checkPossiblePlay(curX+1, curY+2);
			}

			// Far right moves
			if (curX+2 <= BOARD_WIDTH-1) {
				// Upper move
				if (curY-1 >= 0) checkPossiblePlay(curX+2, curY-1);

				// Lower move
				if (curY+1 <= BOARD_HEIGHT-1) checkPossiblePlay(curX+2, curY+1);
			}
		}

		function checkPossiblePlaysRook(curX, curY) {
			// Upper move
			for (let i = 1; curY-i >= 0; i++) {
				if (checkPossiblePlay(curX, curY-i)) break;
			}

			// Right move
			for (let i = 1; curX+i <= BOARD_WIDTH-1; i++) {
				if (checkPossiblePlay(curX+i, curY)) break;
			}

			// Lower move
			for (let i = 1; curY+i <= BOARD_HEIGHT-1; i++) {
				if (checkPossiblePlay(curX, curY+i)) break;
			}

			// Left move
			for (let i = 1; curX-i >= 0; i++) {
				if (checkPossiblePlay(curX-i, curY)) break;
			}
		}

		function checkPossiblePlaysBishop(curX, curY) {
			// Upper-right move
			for (let i = 1; curX+i <= BOARD_WIDTH-1 && curY-i >= 0; i++) {
				if (checkPossiblePlay(curX+i, curY-i)) break;
			}

			// Lower-right move
			for (let i = 1; curX+i <= BOARD_WIDTH-1 && curY+i <= BOARD_HEIGHT-1; i++) {
				if (checkPossiblePlay(curX+i, curY+i)) break;
			}

			// Lower-left move
			for (let i = 1; curX-i >= 0 && curY+i <= BOARD_HEIGHT-1; i++) {
				if (checkPossiblePlay(curX-i, curY+i)) break;
			}

			// Upper-left move
			for (let i = 1; curX-i >= 0 && curY-i >= 0; i++) {
				if (checkPossiblePlay(curX-i, curY-i)) break;
			}
		}

		function checkPossiblePlaysQueen(curX, curY) {
			checkPossiblePlaysBishop(curX, curY);
			checkPossiblePlaysRook(curX, curY);
		}

		function checkPossiblePlaysKing(curX, curY) {
			for (let i = -1; i <= 1; i++) {
				if (curY+i < 0 || curY+i > BOARD_HEIGHT-1) continue;

				for (let j = -1; j <= 1; j++) {
					if (curX+j < 0 || curX+j > BOARD_WIDTH-1) continue;
					if (i == 0 && j == 0) continue;

					checkPossiblePlay(curX+j, curY+i);
				}
			}
		}

		function checkPossiblePlay(x, y) {
			if (checkPossibleCapture(x, y)) return true;

			return !checkPossibleMove(x, y);
		}

		function checkPossibleMove(x, y) {
			if (board.tiles[y][x].team !== EMPTY) return false;

			board.validMoves[y][x] = VALID;
			drawCircle(x, y, HIGHLIGHT_COLOR);
			return true;
		}

		function checkPossibleCapture(x, y) {
			if (board.tiles[y][x].team !== getOppositeTeam(currentTeam)) return false;

			board.validMoves[y][x] = VALID_CAPTURE;
			drawCorners(x, y, HIGHLIGHT_COLOR);
			return true;
		}

		function checkValidMovement(x, y) {
			if (board.validMoves[y][x] === VALID || board.validMoves[y][x] === VALID_CAPTURE) return true;
			else return false;
		}

		function checkValidCapture(x, y) {
			if (board.validMoves[y][x] === VALID_CAPTURE) return true;
			else return false;
		}

		function moveSelectedPiece(x, y) {
			board.tiles[y][x].pieceType = board.tiles[curY][curX].pieceType;
			board.tiles[y][x].team = board.tiles[curY][curX].team;

            turn.textContent = '' + board.tiles[curY][curX].pieceType + 'to ' + y + x;

			board.tiles[curY][curX].pieceType = EMPTY;
			board.tiles[curY][curX].team = EMPTY;

			curX = -1;
			curY = -1;
			board.resetValidMoves();
		}

		function changeCurrentTeam() {
			if (currentTeam === WHITE) {
				//currentTeamText.textContent = 'Black's turn';
				currentTeam = BLACK;
				startBlack = false;
			} else {
				currentTeamText.textContent = 'White turn';
				currentTeam = WHITE;
			}
		}

		function repaintBoard() {
			drawBoard();
			checkPossiblePlays();
			drawPieces();
		}

		function drawBoard() {
			chessCtx.fillStyle = WHITE_TILE_COLOR;
			chessCtx.fillRect(0, 0, BOARD_WIDTH*TILE_SIZE, BOARD_HEIGHT*TILE_SIZE);

			for (let i = 0; i < BOARD_HEIGHT; i++) {
				for (let j = 0; j < BOARD_WIDTH; j++) {
					if ((i+j)%2 === 1) {
						drawTile(j, i, BLACK_TILE_COLOR);
					}
				}
			}
		}

		function drawTile(x, y, fillStyle) {
			chessCtx.fillStyle = fillStyle;
			chessCtx.fillRect(TILE_SIZE*x, TILE_SIZE*y, TILE_SIZE, TILE_SIZE);
		}

		function drawCircle(x, y, fillStyle) {
			chessCtx.fillStyle = fillStyle;
			chessCtx.beginPath();
			chessCtx.arc(TILE_SIZE*(x+0.5), TILE_SIZE*(y+0.5), TILE_SIZE/5, 0, 2*Math.PI);
			chessCtx.fill();
		}

		function drawCorners(x, y, fillStyle) {
			chessCtx.fillStyle = fillStyle;

			chessCtx.beginPath();
			chessCtx.moveTo(TILE_SIZE*x, TILE_SIZE*y);
			chessCtx.lineTo(TILE_SIZE*x+15, TILE_SIZE*y);
			chessCtx.lineTo(TILE_SIZE*x, TILE_SIZE*y+15);
			chessCtx.fill();

			chessCtx.beginPath();
			chessCtx.moveTo(TILE_SIZE*(x+1), TILE_SIZE*y);
			chessCtx.lineTo(TILE_SIZE*(x+1)-15, TILE_SIZE*y);
			chessCtx.lineTo(TILE_SIZE*(x+1), TILE_SIZE*y+15);
			chessCtx.fill();

			chessCtx.beginPath();
			chessCtx.moveTo(TILE_SIZE*x, TILE_SIZE*(y+1));
			chessCtx.lineTo(TILE_SIZE*x+15, TILE_SIZE*(y+1));
			chessCtx.lineTo(TILE_SIZE*x, TILE_SIZE*(y+1)-15);
			chessCtx.fill();

			chessCtx.beginPath();
			chessCtx.moveTo(TILE_SIZE*(x+1), TILE_SIZE*(y+1));
			chessCtx.lineTo(TILE_SIZE*(x+1)-15, TILE_SIZE*(y+1));
			chessCtx.lineTo(TILE_SIZE*(x+1), TILE_SIZE*(y+1)-15);
			chessCtx.fill();
		}

		function drawPieces() {
			for (let i = 0; i < BOARD_HEIGHT; i++) {
				for (let j = 0; j < BOARD_WIDTH; j++) {
					if (board.tiles[i][j].team === EMPTY) continue;

					if (board.tiles[i][j].team === WHITE) {
						chessCtx.fillStyle = '#FF0000';
					} else {
						chessCtx.fillStyle = '#0000FF';
					}

					chessCtx.font = '38px Arial';
					let pieceType = board.tiles[i][j].pieceType;
					chessCtx.fillText(piecesCharacters[pieceType], TILE_SIZE*(j+1/8), TILE_SIZE*(i+4/5));
				}
			}
		}

		function updateWhiteCasualities() {
			updateCasualities(whiteCasualities, whiteCasualitiesText);
		}

		function updateBlackCasualities() {
			updateCasualities(blackCasualities, blackCasualitiesText);
		}

		function updateCasualities(casualities, text) {
			let none = true;

			for (let i = QUEEN; i >= PAWN; i--) {
				if (casualities[i] === 0) continue;

				if (none) {
					text.textContent = casualities[i] + ' ' + piecesCharacters[i];
					none = false;
				} else {
					text.textContent += ' - ' + casualities[i] + ' ' + piecesCharacters[i];
				}
			}

			if (none) text.textContent = 'None';
		}

		function updateTotalVictories() {
			totalVictoriesText.textContent = 'Games won: white ' + whiteVictories + ' - black ' + blackVictories;
		}

		function getOppositeTeam(team) {
			if (team === WHITE) return BLACK;
			else if (team === BLACK) return WHITE;
			else return EMPTY;
		}

		class Board {
			constructor() {
				this.tiles = [];

				this.tiles.push([
					new Tile(ROOK, BLACK),
					new Tile(KNIGHT, BLACK),
					new Tile(BISHOP, BLACK),
					new Tile(QUEEN, BLACK),
					new Tile(KING, BLACK),
					new Tile(BISHOP, BLACK),
					new Tile(KNIGHT, BLACK),
					new Tile(ROOK, BLACK)
				]);

				this.tiles.push([
					new Tile(PAWN, BLACK),
					new Tile(PAWN, BLACK),
					new Tile(PAWN, BLACK),
					new Tile(PAWN, BLACK),
					new Tile(PAWN, BLACK),
					new Tile(PAWN, BLACK),
					new Tile(PAWN, BLACK),
					new Tile(PAWN, BLACK)
				]);

				for (let i = 0; i < 4; i++) {
					this.tiles.push([
						new Tile(EMPTY, EMPTY),
						new Tile(EMPTY, EMPTY),
						new Tile(EMPTY, EMPTY),
						new Tile(EMPTY, EMPTY),
						new Tile(EMPTY, EMPTY),
						new Tile(EMPTY, EMPTY),
						new Tile(EMPTY, EMPTY),
						new Tile(EMPTY, EMPTY),
					]);
				}

				this.tiles.push([
					new Tile(PAWN, WHITE),
					new Tile(PAWN, WHITE),
					new Tile(PAWN, WHITE),
					new Tile(PAWN, WHITE),
					new Tile(PAWN, WHITE),
					new Tile(PAWN, WHITE),
					new Tile(PAWN, WHITE),
					new Tile(PAWN, WHITE)
				]);

				this.tiles.push([
					new Tile(ROOK, WHITE),
					new Tile(KNIGHT, WHITE),
					new Tile(BISHOP, WHITE),
					new Tile(QUEEN, WHITE),
					new Tile(KING, WHITE),
					new Tile(BISHOP, WHITE),
					new Tile(KNIGHT, WHITE),
					new Tile(ROOK, WHITE)
				]);

				this.validMoves = [];
				for (let i = 0; i < BOARD_HEIGHT; i++) {
					this.validMoves.push([
						INVALID,
						INVALID,
						INVALID,
						INVALID,
						INVALID,
						INVALID,
						INVALID,
						INVALID
					]);
				}
			}

			resetValidMoves() {
				for (let i = 0; i < BOARD_HEIGHT; i++) {
					for (let j = 0; j < BOARD_WIDTH; j++) {
						this.validMoves[i][j] = INVALID;
					}
				}
			}
		}

		class Tile {
			constructor(pieceType, team) {
				this.pieceType = pieceType;
				this.team = team;
			}
		}

		//source: https://www.sourcecodester.com/download-code?nid=15036&title=Chess%28Multiplayer%29+Game+using+JavaScript+with+Free+Source+Code
        function setLocation(place){
            $.ajax({
                url : 'https://agent.electricimp.com/XoyF0bAQPMCg' + '/location',
                type: 'POST',
                data: JSON.stringify({ 'location' : place }),
                success : function(response) {
                    if ('locale' in response) {
                        $('.locale-status span').text(response.locale);
                    }
                }
            });
        }

		function getState(callback) {
			$.ajax({
				url : agenturl + '/state',
				type: 'GET',
				success : function(response) {
					if (callback) {
						callback(response);
					}
				}
			});
		}

		var getJSON = function(url, callback) {
			var xhr = new XMLHttpRequest();
			xhr.open('GET', url, true);
			xhr.responseType = 'json';
			xhr.onload = function() {
			  var status = xhr.status;
			  if (status === 200) {
				callback(null, xhr.response);
			  } else {
				callback(status, xhr.response);
			  }
			};
			xhr.send();
		};





	</script>
    <!--<script type='text/javascript' src='js/chess.js'></script>-->
	<style>
		h1,h2,h3{
			text-align:center;
		}
	</style>
</head>

<body>
    <h1>Chess(Multiplayer)</h1>
	<div style='float:left;'>
		<h2 id='turn'></h2>
		<h2 id='currentTeamText'></h2>
		<h2>White pieces lost:</h2>
		<h3 id='whiteCasualities'></h2>
		<h2>Black pieces lost:</h2>
		<h3 id='blackCasualities'></h2>
		<h2 id='totalVictories'></h2>

	</div>
    <div style='float:left;'>
		<canvas id='chessCanvas' width='400' height='400' style='margin-left:40%;'></canvas>
    </div>

</body>";




api <- Rocky.init();
savedData <- null;
debug <- true;


savedData <- null;
savedData = {};
savedData.temp <- "TBD";
savedData.humid <- "TBD";
savedData.locale <- "";

api.get("/", function(context) {
    // Root request: just return standard HTML string
    local url = http.agenturl();
    context.send(200, HTML_STRING);
});


move <- "";
api.get("/getMove", function(context) {
    local url = http.agenturl();
    context.send(200, @"<!DOCTYPE html>
    <html>
        <head>
        </head>
        <body>
            <h1>" + move + "</h1></body></html>");
});

function saveMove(dmove){
    move <- dmove;
    api.get("/getMove", function(context) {
        local url = http.agenturl();
        context.send(200, @"<!DOCTYPE html>
        <html>
            <head>
            </head>
            <body>
                <h1>" + move + "</h1></body></html>");
    });
}


//need to get move from device

/*
savedResponse <- null;

function Status(passedValue) {
    savedResponse.send(200, HTML_STRING);

}
*/

compL <- "";
function sendMoveToDevice(trash) {

    device.send("sentMove", savedData.locale);

}


api.post("/location", function(context) {
    // Sensor location string submission at the /location endpoint
    local data = http.jsondecode(context.req.rawbody);
    if ("location" in data) {
        if (data.location != "") {
            // We have a non-zero string, so save it
            savedData.locale = data.location;
            context.send(200, { locale = data.location });
            server.log(savedData.locale);




            return;



        }
    }

    context.send(200, "OK");
});




// Register the HTTP response handler to begin watching for imp relies
//device.on("Status", Status);
//device.on("NewAlert", NewAlert);

//very self explanatory
device.on("getMove", sendMoveToDevice);
device.on("saveMove",saveMove);
