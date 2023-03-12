
var selectedCell = false;
var selectedColor = "";
var cell;

function selectCell(row,col) {
  if (selectedCell==false) {
    cell = document.getElementById("cell" + row + col);
    selectedColor = cell.style.backgroundColor;
    cell.style.backgroundColor = "#FF0000";
    selectedCell = true;
  } else {
    cell.style.backgroundColor = "#FFFFFF";
    var newCell = document.getElementById("cell" + row + col);
    newCell.innerHTML = cell.innerHTML;
    cell.innerHTML = ""
    cell.style.backgroundColor = selectedColor;
    selectedCell = false;
  }  
  
}


Resources