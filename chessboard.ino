#include <DFRobot_RGBMatrix.h> // Hardware-specific library

#define OE     9
#define LAT   10
#define CLK   11
#define A     A0
#define B     A1
#define C     A2
#define D     A3
#define E     A4
#define WIDTH 64
#define _HIGH 64

DFRobot_RGBMatrix matrix(A, B, C, D, E, CLK, LAT, OE, false, WIDTH, _HIGH);

bool boardTurn;

int cx;//cursor location
int cy;

char bx1 = 'x';
char by1 = 'x';
char bx2 = 'x';
char by2 = 'x';

int board[8][8] = {{ -2, -3, -4, -5, -6, -4, -3, -2},
  { -1, -1, -1, -1, -1, -1, -1, -1},
  {0, 0, 0, 0, 0, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0, 0},
  {1, 1, 1, 1, 1, 1, 1, 1},
  {2, 3, 4, 5, 6, 4, 3, 2}
};
/*
   pawns are int 1, rooks are 2, knights 3, bishops 4, queens 5, kings 6
   negative for black
   0 for nothing
   could enum this but I'm just going to check manually
*/

const int pawn = 1;
const int rook = 2;
const int knight = 3;
const int bishop = 4;
const int queen = 5;
const int king = 6;

String prev = "";

void setup() {
  Serial.begin(9600);
  Serial1.begin(9600);
  pinMode(48, INPUT);//left
  pinMode(49, INPUT);//right
  pinMode(50, INPUT);//up
  pinMode(51, INPUT);//down
  pinMode(52, INPUT);//pick up
  pinMode(53, INPUT);//drop


  matrix.begin();
  cx = 3;
  cy = 4;
  //setBoard();


  smartSetBoard();

  boardTurn = false;
  delay(500);
  readSerial();

}

void loop() {


/*
    String content = "";
    char character;
        
    while(Serial1.available()) {
      character = Serial1.read();
      content.concat(character);
    }
          
    if (content != "") {
      Serial.println(content);
    }
    Serial1.write("1,0;2,2");
  */   

  if (Serial1.available()){
    checkMove();
  }
  
  if (boardTurn) {
    deployCursor();
    boardTurn = false;
    readSerial();
    
    Serial.println("black Moved");
  } else {
    transmitBoard();
    delay(500);
    //readSerial();
  }
  

  
  delay(1000);

  


}
String readSerial() {
  String content = "";
  String character = "";

  while (Serial1.peek() != 'z'){
    character = Serial1.read();  
  }
  Serial.println("move detected " + Serial1.peek());

  while(Serial1.available()){
    character = Serial1.readString();
    content.concat(character);
  }
    
  Serial.println(content.substring(1,content.length()));
  return content.substring(1, content.length());
}

boolean checkMove(){
  
  Serial.println("Checking");
  String content = readSerial();
  Serial.println("recieved: " + content);
  if (content != ""){
    if (content.length() == 4){
      
      Serial.println("content: " + content);
      
      
      char ch1[1];
      char ch2[1];
      char ch3[1];
      char ch4[1];
      
      content.substring(0,1).toCharArray(ch1,1);
      content.substring(1,2).toCharArray(ch2,1);      
      content.substring(2,3).toCharArray(ch3,1);      
      content.substring(3,4).toCharArray(ch4,1);
      /*
      if (!isDigit(ch1[0])){
          boardTurn = false;
          Serial.println(ch1[0]);
          return false;
      }
      if (!isDigit(ch2[0])){
          boardTurn = false;
          
          Serial.println(ch2[0]);
          return false;
      }
      if (!isDigit(ch3[0])){
          boardTurn = false;
          
          Serial.println(ch3[0]);
          return false;
      }
      if (!isDigit(ch4[0])){
          boardTurn = false;
          
          Serial.println(ch4[0]);
          return false;
      }
      */
      for (int i = 0; i < 4; i ++){
        if (!isDigit(content.charAt(i))){
          Serial.println(content.charAt(i));
          Serial.println("is not a digit");
          return false;
          
        }
      }

      if (prev != content){
        prev = content;
        Serial.println("different");
      } else {
        Serial.println("duplicate");
        return false;
      }
      
      int x1 = content.substring(0,1).toInt();
      int y1 = content.substring(1,2).toInt();
      int x2 = content.substring(2,3).toInt();
      int y2 = content.substring(3,4).toInt();

      
      int pickedPiece = board[y1][x1];
      bool color = true;
      if (pickedPiece < 0) {
        color = false;
      }
      printPiece(x2, y2, abs(pickedPiece), color);
      determineSquare(x1, y1);
      board[y1][x1] = 0;//might need editing?
      board[y2][x2] = pickedPiece;
      Serial.println("Board's turn");      
      boardTurn = true;
      return true;
    } else {
      boardTurn = false;
    }
  }
  return false;
    
}

void transmitBoard(){
  delay(50);
  Serial1.write("m");
  delay(50);
  Serial1.write(bx1);
  delay(50);
  Serial1.write(",");
  delay(50);
  Serial1.write(by1);
  delay(50);
  Serial1.write(";");
  delay(50);
  Serial1.write(bx2);
  delay(50);
  Serial1.write(",");
  delay(50);
  Serial1.write(by2);
  delay(50);
  Serial1.write(".");
  delay(50);

  
  Serial.println(bx1);
  Serial.println(",");
  Serial.println(by1);
  Serial.println(";");
  Serial.println(bx2);
  Serial.println(",");
  Serial.println(by2);
  Serial.println(".");
        
}

/*
   draws full white, use this when power supply isn't there to show board being incapable of displaying properly
*/
void testColors() {
  for (int row = 0; row < 64; row++) {
    for (int col = 0; col < 64; col++) {
      matrix.drawPixel(row, col, matrix.Color333(0, 7, 7));
      delay(20);
    }
  }
}

/*
   deploys the cursor and allows the user to move it as well as select and drop pieces
*/
void deployCursor() {
  //show cursor
  //loop as long as drop button isn't hit
  //  loop to wait for pickup button or else we don't allow drop button
  //if piece is picked up, highlight it
  //inside the loop, scan for all buttons and move the cursor depending which one is clicked

  bool dropped = false;
  bool picked = false;
  int pickedPiece = 0;
  int pickX;
  int pickY;
  drawCursor(cx, cy);

  /*int testingIterations = 0;

    /*
       For testing only, get rid of this later
  */


  while (!dropped) {

    /*testingIterations = testingIterations + 1;*/
    delay(100);


    determineSquare(cx, cy);
    bool checkColor = true;
    if (board[cy][cx] < 0) {
      checkColor = false;
    }
    printPiece(cx, cy, abs(board[cy][cx]), checkColor);


    if (picked) {
      highlightSquare(pickX, pickY);
    }

    if (digitalRead(48) == HIGH) {
      if (cx > 0) {
        cx = cx - 1;
      }
    }
    if (digitalRead(49) == HIGH) {
      if (cx < 7) {
        cx = cx + 1;
      }
    }
    if (digitalRead(50) == HIGH) {
      if (cy > 0) {
        cy = cy - 1;
      }
    }
    if (digitalRead(51) == HIGH) {
      if (cy < 7) {
        cy = cy + 1;
      }
    }

    drawCursor(cx, cy);

    if (!picked) {
      if (digitalRead(52) == HIGH) {
        if (board[cy, cx] != 0) {
          pickedPiece = board[cy][cx];
          picked = true;
          pickX = cx;
          pickY = cy;

          highlightSquare(cx, cy);

        }
      }
    } else {
      if (digitalRead(53) == HIGH) {
        bool color = true;
        if (pickedPiece < 0) {
          color = false;
        }
        printPiece(cx, cy, abs(pickedPiece), color);
        determineSquare(pickX, pickY);
        board[pickY][pickX] = 0;//might need editing?
        board[cy][cx] = pickedPiece;
        dropped = true;
        bx1 = pickX + 48;
        by1 = pickY + 48;
        bx2 = cx + 48;
        by2 = cy + 48;
        transmitBoard();

        //char sender[7] = {pickX,',',pickY,';',cx,',',cy};
        
        //Serial1.write(sender);
        //Serial.println(sender);
        /*
           ------------------------------------------
           NEEDS WORK: CASTLING AND EN PASSANT
           ------------------------------------------
        */

      }
    }
  }


}



/*
   highlights the square at the coordinates
*/
void highlightSquare(int x, int y) {
  for (int i = 0; i < 8; i ++) {
    matrix.drawPixel(x * 8 + i, y * 8, matrix.Color333(7, 7, 7));
    matrix.drawPixel(x * 8 + i, y * 8 + 7, matrix.Color333(7, 7, 7));
    matrix.drawPixel(x * 8, y * 8 + i, matrix.Color333(7, 7, 7));
    matrix.drawPixel(x * 8 + 7, y * 8 + i, matrix.Color333(7, 7, 7));
  }
}

/*
   draws cursor at the location
*/
void drawCursor(int x, int y) {
  uint16_t color = matrix.Color333(0, 7, 3);

  int baseX = x * 8;
  int baseY = y * 8;

  matrix.drawPixel(baseX, baseY, color);
  matrix.drawPixel(baseX + 1, baseY, color);
  matrix.drawPixel(baseX, baseY + 1, color);

  matrix.drawPixel(baseX + 7, baseY, color);
  matrix.drawPixel(baseX + 6, baseY, color);
  matrix.drawPixel(baseX + 7, baseY + 1, color);

  matrix.drawPixel(baseX, baseY + 7, color);
  matrix.drawPixel(baseX + 1, baseY + 7, color);
  matrix.drawPixel(baseX, baseY + 6, color);

  matrix.drawPixel(baseX + 7, baseY + 7, color);
  matrix.drawPixel(baseX + 6, baseY + 7, color);
  matrix.drawPixel(baseX + 7, baseY + 6, color);


}

/*
   draw a light square
*/
void drawLightSquare(int x, int y) {
  //matrix.fillRect(x*8,y*8,(x+1)*8, (y+1)*8, matrix.Color333(1,2,4));
  //not using fillrect because it's too slow and bad
  int baseX = x * 8;
  int baseY = y * 8;
  for (int i = 0; i < 8; i ++) {
    for (int i2 = 0; i2 < 8; i2 ++) {
      matrix.drawPixel(baseX + i, baseY + i2, matrix.Color333(1, 2, 4));
    }
  }

}
/*
   draw a dark square
*/
void drawDarkSquare(int x, int y) {
  //matrix.fillRect(x*8,y*8,(x+1)*8, (y+1)*8, matrix.Color333(1,1,1));
  int baseX = x * 8;
  int baseY = y * 8;
  for (int i = 0; i < 8; i ++) {
    for (int i2 = 0; i2 < 8; i2 ++) {
      matrix.drawPixel(baseX + i, baseY + i2, matrix.Color333(1, 1, 1));
    }
  }
}

/*
   draws the color of the square at the given coordinate
*/
void determineSquare(int x, int y) {
  if (x % 2 == 0) {
    //even row assuming 0,0 is top left starts white
    if (y % 2 == 0) {
      drawLightSquare(x, y);
    } else {
      drawDarkSquare(x, y);
    }
  } else {
    //odd row starts black
    if (y % 2 == 0) {
      drawDarkSquare(x, y);
    } else {
      drawLightSquare(x, y);
    }
  }
}

/*
   fills the board with properly colored squares
*/
void fillBoard() {
  //int n = 0; this and other commented section are for finding orientation
  for (int row = 0; row < 8; row++) {
    for (int col = 0; col < 8; col++) {
      determineSquare(row, col);

      /*
        matrix.setCursor(row*8,col*8);
        matrix.setTextColor(matrix.Color333(3,0,0));
        matrix.setTextSize(1);
        matrix.print(n);
        n++;
      */
    }
  }
}

/*
   draws the entire board pieces included
*/
void setBoard() {
  fillBoard();
  for (int i = 0; i < 8; i ++) {
    drawPawn(i, 1, false); //these are drawn as the x value being how many blocks right and y = blocks down
    drawPawn(i, 6, true);
  }

  drawRook(0, 0, false);
  drawRook(7, 0, false);
  drawRook(0, 7, true);
  drawRook(7, 7, true);

  drawKnight(1, 0, false);
  drawKnight(6, 0, false);
  drawKnight(1, 7, true);
  drawKnight(6, 7, true);

  drawBishop(2, 0, false);
  drawBishop(5, 0, false);
  drawBishop(2, 7, true);
  drawBishop(5, 7, true);

  drawQueen(3, 0, false);
  drawQueen(3, 7, true);

  drawKing(4, 0, false);
  drawKing(4, 7, true);
}

/*
   also sets the board but scans through our board array instead, no difference
*/
void smartSetBoard() {
  fillBoard();
  for (int row = 0; row < 8; row++) {
    for (int col = 0; col < 8; col++) {
      bool color = true;
      int cur = board[col][row];
      /*
          IMPORTANT-------------------------------
          This has to be reversed because the iteration through the array operates different
          from the way the board treats its pixels
      */
      if (cur < 0) {
        color = false;
      }
      cur = abs(cur);

      printPiece(row, col, cur, color);

    }
  }
}

void printPiece(int pieceX, int pieceY, int pieceVal, bool color) {
  if (pieceVal == pawn) {
    drawPawn(pieceX, pieceY, color);
  }
  if (pieceVal == rook) {
    drawRook(pieceX, pieceY, color);
  }
  if (pieceVal == knight) {
    drawKnight(pieceX, pieceY, color);
  }
  if (pieceVal == bishop) {
    drawBishop(pieceX, pieceY, color);
  }
  if (pieceVal == queen) {
    drawQueen(pieceX, pieceY, color);
  }
  if (pieceVal == king) {
    drawKing(pieceX, pieceY, color);
  }
}

/*
   draws a pawn of unknown color at the given square, currently assuming black is board player and oriented as such
   Will be oriented as calling coordinates x = blocks to the right, and y = blocks down
*/
void drawPawn(int x, int y, bool color) {
  //if color == true, draw white pawn
  uint16_t pieceColor = 0;

  if (color) {
    pieceColor = matrix.Color333(7, 7, 2); //yellow for white pieces
  } else {
    pieceColor = matrix.Color333(4, 1, 4); //purple for black pieces
  }

  int baseX = x * 8;
  int baseY = y * 8;
  matrix.drawPixel(baseX + 2, baseY + 1, pieceColor);
  matrix.drawPixel(baseX + 3, baseY + 1, pieceColor);
  matrix.drawPixel(baseX + 4, baseY + 1, pieceColor);
  matrix.drawPixel(baseX + 5, baseY + 1, pieceColor);
  matrix.drawPixel(baseX + 3, baseY + 2, pieceColor);
  matrix.drawPixel(baseX + 4, baseY + 2, pieceColor);
  matrix.drawPixel(baseX + 3, baseY + 3, pieceColor);
  matrix.drawPixel(baseX + 4, baseY + 3, pieceColor);
  matrix.drawPixel(baseX + 3, baseY + 4, pieceColor);
  matrix.drawPixel(baseX + 4, baseY + 4, pieceColor);
  matrix.drawPixel(baseX + 2, baseY + 4, pieceColor);
  matrix.drawPixel(baseX + 5, baseY + 4, pieceColor);
  matrix.drawPixel(baseX + 3, baseY + 5, pieceColor);
  matrix.drawPixel(baseX + 4, baseY + 5, pieceColor);

}

void drawRook(int x, int y, bool color) {
  uint16_t pieceColor = 0;

  if (color) {
    pieceColor = matrix.Color333(7, 7, 2); //yellow for white pieces
  } else {
    pieceColor = matrix.Color333(4, 1, 4); //purple for black pieces
  }

  int baseX = x * 8;
  int baseY = y * 8;

  for (int i = 1; i < 7; i ++) {
    matrix.drawPixel(baseX + i, baseY + 1, pieceColor);
  }

  for (int i = 1; i < 7; i ++) {
    matrix.drawPixel(baseX + i, baseY + 2, pieceColor);
  }

  for (int i = 2; i < 6; i ++) {
    matrix.drawPixel(baseX + i, baseY + 3, pieceColor);
  }

  for (int i = 2; i < 6; i ++) {
    matrix.drawPixel(baseX + i, baseY + 4, pieceColor);
  }

  for (int i = 1; i < 7; i ++) {
    matrix.drawPixel(baseX + i, baseY + 5, pieceColor);
  }

  matrix.drawPixel(baseX + 1, baseY + 6, pieceColor);
  matrix.drawPixel(baseX + 3, baseY + 6, pieceColor);
  matrix.drawPixel(baseX + 4, baseY + 6, pieceColor);
  matrix.drawPixel(baseX + 6, baseY + 6, pieceColor);

}

void drawKnight(int x, int y, bool color) {
  uint16_t pieceColor = 0;

  if (color) {
    pieceColor = matrix.Color333(7, 7, 2); //yellow for white pieces
  } else {
    pieceColor = matrix.Color333(4, 1, 4); //purple for black pieces
  }

  int baseX = x * 8;
  int baseY = y * 8;

  for (int i = 1; i < 7; i ++) {
    matrix.drawPixel(baseX + i, baseY + 1, pieceColor);
  }

  for (int i = 2; i < 6; i ++) {
    matrix.drawPixel(baseX + i, baseY + 2, pieceColor);
  }

  matrix.drawPixel(baseX + 2, baseY + 3, pieceColor);
  matrix.drawPixel(baseX + 3, baseY + 3, pieceColor);
  matrix.drawPixel(baseX + 2, baseY + 4, pieceColor);
  matrix.drawPixel(baseX + 3, baseY + 4, pieceColor);
  matrix.drawPixel(baseX + 5, baseY + 4, pieceColor);

  for (int i = 2; i < 6; i ++) {
    matrix.drawPixel(baseX + i, baseY + 5, pieceColor);
  }

  for (int i = 2; i < 6; i ++) {
    matrix.drawPixel(baseX + i, baseY + 6, pieceColor);
  }
}

void drawBishop(int x, int y, bool color) {
  uint16_t pieceColor = 0;

  if (color) {
    pieceColor = matrix.Color333(7, 7, 2); //yellow for white pieces
  } else {
    pieceColor = matrix.Color333(4, 1, 4); //purple for black pieces
  }

  int baseX = x * 8;
  int baseY = y * 8;

  for (int i = 1; i < 7; i ++) {
    matrix.drawPixel(baseX + i, baseY + 1, pieceColor);
  }

  matrix.drawPixel(baseX + 3, baseY + 2, pieceColor);
  matrix.drawPixel(baseX + 4, baseY + 2, pieceColor);
  matrix.drawPixel(baseX + 3, baseY + 3, pieceColor);
  matrix.drawPixel(baseX + 4, baseY + 3, pieceColor);
  matrix.drawPixel(baseX + 2, baseY + 4, pieceColor);
  matrix.drawPixel(baseX + 5, baseY + 4, pieceColor);
  matrix.drawPixel(baseX + 2, baseY + 5, pieceColor);
  matrix.drawPixel(baseX + 5, baseY + 5, pieceColor);
  matrix.drawPixel(baseX + 3, baseY + 6, pieceColor);
  matrix.drawPixel(baseX + 4, baseY + 6, pieceColor);
}

void drawQueen(int x, int y, bool color) {
  uint16_t pieceColor = 0;

  if (color) {
    pieceColor = matrix.Color333(7, 7, 2); //yellow for white pieces
  } else {
    pieceColor = matrix.Color333(4, 1, 4); //purple for black pieces
  }

  int baseX = x * 8;
  int baseY = y * 8;

  for (int i = 1; i < 7; i ++) {
    matrix.drawPixel(baseX + i, baseY + 1, pieceColor);
  }

  matrix.drawPixel(baseX + 3, baseY + 2, pieceColor);
  matrix.drawPixel(baseX + 4, baseY + 2, pieceColor);
  matrix.drawPixel(baseX + 3, baseY + 3, pieceColor);
  matrix.drawPixel(baseX + 4, baseY + 3, pieceColor);

  for (int i = 1; i < 7; i ++) {
    matrix.drawPixel(baseX + i, baseY + 4, pieceColor);
  }
  for (int i = 2; i < 6; i ++) {
    matrix.drawPixel(baseX + i, baseY + 5, pieceColor);
  }

  matrix.drawPixel(baseX + 1, baseY + 6, pieceColor);
  matrix.drawPixel(baseX + 3, baseY + 6, pieceColor);
  matrix.drawPixel(baseX + 4, baseY + 6, pieceColor);
  matrix.drawPixel(baseX + 6, baseY + 6, pieceColor);


}

void drawKing(int x, int y, bool color) {
  uint16_t pieceColor = 0;

  if (color) {
    pieceColor = matrix.Color333(7, 7, 2); //yellow for white pieces
  } else {
    pieceColor = matrix.Color333(4, 1, 4); //purple for black pieces
  }

  int baseX = x * 8;
  int baseY = y * 8;

  for (int i = 1; i < 7; i ++) {
    matrix.drawPixel(baseX + i, baseY + 1, pieceColor);
  }

  matrix.drawPixel(baseX + 3, baseY + 2, pieceColor);
  matrix.drawPixel(baseX + 4, baseY + 2, pieceColor);

  for (int i = 2; i < 6; i ++) {
    matrix.drawPixel(baseX + i, baseY + 3, pieceColor);
  }

  for (int i = 2; i < 6; i ++) {
    matrix.drawPixel(baseX + i, baseY + 4, pieceColor);
  }

  matrix.drawPixel(baseX + 3, baseY + 5, pieceColor);
  matrix.drawPixel(baseX + 4, baseY + 5, pieceColor);


  for (int i = 2; i < 6; i ++) {
    matrix.drawPixel(baseX + i, baseY + 6, pieceColor);
  }

  matrix.drawPixel(baseX + 3, baseY + 7, pieceColor);
  matrix.drawPixel(baseX + 4, baseY + 7, pieceColor);


}
