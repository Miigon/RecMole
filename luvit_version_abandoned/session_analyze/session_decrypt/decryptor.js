var flash_wrapper = null;

function main()
{
    flash_wrapper = document.getElementById("flash_wrapper");
    document.addEventListener("dragover", function(event) {
        event.preventDefault();
      });
    document.addEventListener("drop",function(e)
    {
        e.preventDefault();
        var fileList = e.dataTransfer.files;
        if (fileList.length == 0) {
            return false;
        }
        console.log(fileList);
        a=fileList
        var reader=new FileReader();
        read.readAsText(fileList[0]);
        reader.onerror=function(){
        
        }
        reader.onprogress=function(){
        
        }
        reader.onload=function(){
            decrypt_session(reader.result)
            
        }
    
    },
    false);
}



function dataToHex(byteArray) {
    return Array.prototype.map.call(byteArray, function(byte) {
        return ('0' + (byte & 0xFF).toString(16)).slice(-2);
    }).join('');
}
function hexToData(hexString) {
    var result = "";
    while (hexString.length >= 2) {
        result += String.fromCharCode(parseInt(hexString.substring(0, 2), 16));
        hexString = hexString.substring(2, hexString.length);
    }
    return result;
}
  

function decrypt()
{

}
    

window.onload = main;