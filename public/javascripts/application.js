// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

// This function is to format the map copyright so it doesn't splat all over
// everything else on the page.
function formatMapCopyright(my_gmap) {
   var my_gmapd = $('_sidebarMap') //$(my_gmap);  // id of your map 
   var div = document.createElement('DIV'); 
   div.style.backgroundColor = 'white'; 
   div.style.position = 'absolute'; 
   div.style.bottom = '0px'; 
   div.style.height = '25px'; 
   div.style.borderTop = '1px solid #aaa'; 
   my_gmapd.appendChild(div); 
   div.style.width = '100%'; 
   div.style.zIndex = '500'; // move to middle 
   var divs = my_gmapd.getElementsByTagName('DIV'); // get map's child divs 
   divs[1].style.zIndex = '1000';  // move to front; the google image 
   divs[2].style.zIndex = '1000';  // move to front; the copyright string 
   divs[2].style.wordWrap = 'break-word';  // wrap the copyright string around 
   divs[2].style.width = '50%';  // optionally, set a pixel-width here 
   divs[2].style.fontSize = '80%';  // make it teensy bit smaller
}