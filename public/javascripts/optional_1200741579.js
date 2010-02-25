function GMarkerGroup(active,markers,markersById){this.active=active;this.markers=markers||new Array();this.markersById=markersById||new Object();}
GMarkerGroup.prototype=new GOverlay();GMarkerGroup.prototype.initialize=function(map){this.map=map;if(this.active){for(var i=0,len=this.markers.length;i<len;i++){this.map.addOverlay(this.markers[i]);}
for(var id in this.markersById){this.map.addOverlay(this.markersById[id]);}}}
GMarkerGroup.prototype.remove=function(){this.deactivate();}
GMarkerGroup.prototype.redraw=function(force){}
GMarkerGroup.prototype.copy=function(){var overlay=new GMarkerGroup(this.active);overlay.markers=this.markers;overlay.markersById=this.markersById;return overlay;}
GMarkerGroup.prototype.clear=function(){this.deactivate();this.markers=new Array();this.markersById=new Object();}
GMarkerGroup.prototype.addMarker=function(marker,id){if(id==undefined){this.markers.push(marker);}else{this.markersById[id]=marker;}
if(this.active&&this.map!=undefined){this.map.addOverlay(marker);}}
GMarkerGroup.prototype.showMarker=function(id){var marker=this.markersById[id];if(marker!=undefined){GEvent.trigger(marker,"click");}}
GMarkerGroup.prototype.activate=function(active){active=(active==undefined)?true:active;if(!active){if(this.active){if(this.map!=undefined){for(var i=0,len=this.markers.length;i<len;i++){this.map.removeOverlay(this.markers[i])}
for(var id in this.markersById){this.map.removeOverlay(this.markersById[id]);}}
this.active=false;}}else{if(!this.active){if(this.map!=undefined){for(var i=0,len=this.markers.length;i<len;i++){this.map.addOverlay(this.markers[i]);}
for(var id in this.markersById){this.map.addOverlay(this.markersById[id]);}}
this.active=true;}}}
GMarkerGroup.prototype.centerAndZoomOnMarkers=function(){if(this.map!=undefined){var tmpMarkers=this.markers.slice();for(var id in this.markersById){tmpMarkers.push(this.markersById[id]);}
if(tmpMarkers.length>0){this.map.centerAndZoomOnMarkers(tmpMarkers);}}}
GMarkerGroup.prototype.deactivate=function(){this.activate(false);}
function GeoRssOverlay(rssurl,icon,proxyurl,options){this.rssurl=rssurl;this.icon=icon;this.proxyurl=proxyurl;if(options['visible']==undefined)
this.visible=true;else
this.visible=options['visible'];this.listDiv=options['listDiv'];this.contentDiv=options['contentDiv'];this.listItemClass=options['listItemClass'];this.limitItems=options['limit'];this.request=false;this.markers=[];}
GeoRssOverlay.prototype=new GOverlay();GeoRssOverlay.prototype.initialize=function(map){this.map=map;this.load();}
GeoRssOverlay.prototype.redraw=function(force){}
GeoRssOverlay.prototype.remove=function(){for(var i=0,len=this.markers.length;i<len;i++){this.map.removeOverlay(this.markers[i]);}}
GeoRssOverlay.prototype.showHide=function(){if(this.visible){for(var i=0;i<this.markers.length;i++){this.map.removeOverlay(this.markers[i]);}
this.visible=false;}else{for(var i=0;i<this.markers.length;i++){this.map.addOverlay(this.markers[i]);}
this.visible=true;}}
GeoRssOverlay.prototype.showMarker=function(id){var marker=this.markers[id];if(marker!=undefined){GEvent.trigger(marker,"click");}}
GeoRssOverlay.prototype.copy=function(){var oCopy=new GeoRssOVerlay(this.rssurl,this.icon,this.proxyurl);oCopy.markers=[];for(var i=0,len=this.markers.length;i<len;i++){oCopy.markers.push(this.markers[i].copy());}
return oCopy;}
GeoRssOverlay.prototype.load=function(){if(this.request!=false){return;}
this.request=GXmlHttp.create();if(this.proxyurl!=undefined){this.request.open("GET",this.proxyurl+'?q='+encodeURIComponent(this.rssurl),true);}else{this.request.open("GET",this.rssurl,true);}
var m=this;this.request.onreadystatechange=function(){m.callback();}
this.request.send(null);}
GeoRssOverlay.prototype.callback=function(){if(this.request.readyState==4){if(this.request.status=="200"){var xmlDoc=this.request.responseXML;if(xmlDoc.documentElement.getElementsByTagName("item").length!=0){var items=xmlDoc.documentElement.getElementsByTagName("item");}else if(xmlDoc.documentElement.getElementsByTagName("entry").length!=0){var items=xmlDoc.documentElement.getElementsByTagName("entry");}
for(var i=0,len=this.limitItems?Math.min(this.limitItems,items.length):items.length;i<len;i++){try{var marker=this.createMarker(items[i],i);this.markers.push(marker);if(this.visible){this.map.addOverlay(marker);}}catch(e){}}}
this.request=false;}}
GeoRssOverlay.prototype.createMarker=function(item,index){var title=item.getElementsByTagName("title")[0].childNodes[0].nodeValue;if(item.getElementsByTagName("description").length!=0){var description=item.getElementsByTagName("description")[0].childNodes[0].nodeValue;var link=item.getElementsByTagName("link")[0].childNodes[0].nodeValue;}else if(item.getElementsByTagName("summary").length!=0){var description=item.getElementsByTagName("summary")[0].childNodes[0].nodeValue;var link=item.getElementsByTagName("link")[0].attributes[0].nodeValue;}
if(navigator.userAgent.toLowerCase().indexOf("msie")<0){if(item.getElementsByTagNameNS("http://www.w3.org/2003/01/geo/wgs84_pos#","lat").length!=0){var lat=item.getElementsByTagNameNS("http://www.w3.org/2003/01/geo/wgs84_pos#","lat")[0].childNodes[0].nodeValue;var lng=item.getElementsByTagNameNS("http://www.w3.org/2003/01/geo/wgs84_pos#","long")[0].childNodes[0].nodeValue;}else if(item.getElementsByTagNameNS("http://www.georss.org/georss","point").length!=0){var latlng=item.getElementsByTagNameNS("http://www.georss.org/georss","point")[0].childNodes[0].nodeValue.split(" ");var lat=latlng[0];var lng=latlng[1];}}else{if(item.getElementsByTagName("geo:lat").length!=0){var lat=item.getElementsByTagName("geo:lat")[0].childNodes[0].nodeValue;var lng=item.getElementsByTagName("geo:long")[0].childNodes[0].nodeValue;}else if(item.getElementsByTagName("georss:point").length!=0){var latlng=item.getElementsByTagName("georss:point")[0].childNodes[0].nodeValue.split(" ");var lat=latlng[0];var lng=latlng[1];}}
var point=new GLatLng(parseFloat(lat),parseFloat(lng));var marker=new GMarker(point,{'title':title});var html="<a href=\""+link+"\">"+title+"</a><p/>"+description;if(this.contentDiv==undefined){GEvent.addListener(marker,"click",function(){marker.openInfoWindowHtml(html);});}else{var contentDiv=this.contentDiv;GEvent.addListener(marker,"click",function(){document.getElementById(contentDiv).innerHTML=html;});}
if(this.listDiv!=undefined){var a=document.createElement('a');a.innerHTML=title;a.setAttribute("href","#");var georss=this;a.onclick=function(){georss.showMarker(index);return false;};var div=document.createElement('div');if(this.listItemClass!=undefined){div.setAttribute("class",this.listItemClass);}
div.appendChild(a);document.getElementById(this.listDiv).appendChild(div);}
return marker;}