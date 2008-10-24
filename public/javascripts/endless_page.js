// endless_page.js
var currentPage = 1;

function checkScroll() {
  if (nearBottomOfPage()) {
    currentPage++;
    new Ajax.Request("/articles.js?page=" + currentPage, {asynchronous:true, evalScripts:true, method:'get'});
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

document.observe('dom:loaded', checkScroll);
