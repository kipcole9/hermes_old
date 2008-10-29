// endless_page.js
var currentPage = 1;

function checkScroll() {
  if (nearBottomOfPage()) {
    currentPage++;
	var url = getNewUrl(currentPage);
	$('loading').show();
    new Ajax.Request(url, {asynchronous:true, evalScripts:true, method:'get'});
  } else {
    setTimeout("checkScroll()", 250);
  }
}

function nearBottomOfPage() {
  return scrollDistanceFromBottom() < 150;
}

function scrollDistanceFromBottom(argument) {
  return pageHeight() - (document.viewport.getScrollOffsets()[1] + document.viewport.getHeight());
}

function pageHeight() {
  return Math.max(document.body.scrollHeight, document.body.offsetHeight);
}

function setPage() {
	var page = getUrlParam("page");
	if (!page) {
		page = 1;
	};
	currentPage = page;
	checkScroll();
}

function getNewUrl(new_page) {
	// The idea is just to update the url since
	// it may have parameters we care about
	var href = window.location.href;
	var has_params = /\?.+=/;
	var new_url = "";
	if (!getUrlParam('page')) {
		// Just add it to the end
		if (has_params.exec(href)) {
			new_url = href + "&page=" + new_page;
		} else {
			new_url = href + "?page=" + new_page;
		}
	} else {
		// We need to substitute it
		var regex = /[\?&](page=\d)/;
		var page_param = regex.exec(href);
		if (page_param) {
			new_url = href.replace(page_param[1],"page=" + new_page);
		} else {
			alert('Woops: Thought there was a page param but couldn\'t find it!');
			new_url =  href;
		}
	};
	return new_url + "&format=js";
}

function getUrlParam(name) {
  name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
  var regexS = "[\\?&]"+name+"=([^&#]*)";
  var regex = new RegExp( regexS );
  var results = regex.exec( window.location.href );
  if( results == null )
    return null;
  else
    return results[1];
}

document.observe('dom:loaded', setPage);
