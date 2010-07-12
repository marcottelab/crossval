/*
Table sorting script  by Joost de Valk, check it out at http://www.joostdevalk.nl/code/sortable-table/.
Based on a script from http://www.kryogenix.org/code/browser/sorttable/.
Distributed under the MIT license: http://www.kryogenix.org/code/browser/licence.html .

Copyright (c) 1997-2007 Stuart Langridge, Joost de Valk.

Version 1.5.7
*/

/* You can change these values */
var image_path = "/images/";
var image_up = "arrow-up.gif";
var image_down = "arrow-down.gif";
var image_none = "arrow-none.gif";
var europeandate = false;
var alternate_row_colors = true;

/* Don't change anything below this unless you know what you're doing */
addEvent(window, "load", sortables_init);

var SORT_COLUMN_INDEX;
var thead = false;

function sortables_init() {
    // Find all tables with class sortable and make them sortable
    if (!document.getElementsByTagName) return;
    tbls = document.getElementsByTagName("table");
    for (ti=0;ti<tbls.length;ti++) {
        thisTbl = tbls[ti];
        if (((' '+thisTbl.className+' ').indexOf("sortable") != -1) && (thisTbl.id)) {
            ts_makeSortable(thisTbl);
        }
    }
}

function ts_makeSortable(t) {
    var firstRow;
    if (t.rows && t.rows.length > 0) {
        if (t.tHead && t.tHead.rows.length > 0) {
            firstRow = t.tHead.rows[t.tHead.rows.length-1];
            thead = true;
        } else firstRow = t.rows[0];
    }
    if (!firstRow) return;

    // We have a first row: assume it's the header, and make its contents clickable links
    for (var i=0;i<firstRow.cells.length;i++) {
        var cell = firstRow.cells[i];
        var txt = ts_getInnerText(cell);
        if (cell.className != "unsortable" && cell.className.indexOf("unsortable") == -1)
            cell.innerHTML = '<a href="#" class="sortheader" onclick="ts_resortTable(this, '+i+');return false;">'+txt+'<span class="sortarrow">&nbsp;&nbsp;<img src="'+ image_path + image_none + '" alt="&darr;"/></span></a>';
    }
    if (alternate_row_colors) alternate(t);
}

function ts_getInnerText(el) {
    if (typeof el == "string") return el;
    if (typeof el == "undefined") return el;
    if (el.innerText) return el.innerText;	//Not needed but it is faster
    var str = "";

    var cs = el.childNodes;
    var l = cs.length;
    for (var i = 0; i < l; i++) {
        switch (cs[i].nodeType) {
        case 1: //ELEMENT_NODE
            str += ts_getInnerText(cs[i]);
            break;
        case 3:	//TEXT_NODE
            str += cs[i].nodeValue;
            break;
        }
    }
    return str;
}

function strip_html(str) {
    str.replace(/&(lt|gt);/g, function (strMatch, p1){
 	return (p1 == "lt")? "<" : ">";
    });
    return str.replace(/<\/?[^>]+(>|$)/g, "");
}

function ts_resortTable(lnk, clid) {
    var span;
    for (var cci=0;cci<lnk.childNodes.length;cci++) {
        if (lnk.childNodes[cci].tagName && lnk.childNodes[cci].tagName.toLowerCase() == 'span') span = lnk.childNodes[cci];
    }
    var spantext = ts_getInnerText(span);
    var td = lnk.parentNode;
    var column = clid || td.cellIndex;
    var t = getParent(td,'TABLE');
    // Work out a type for the column
    if (t.rows.length <= 1) return;
    var itm = "";
    var i = 0;
    if (!thead) i += 1;
    while (itm == "" && i < t.tBodies[0].rows.length) {
        itm = ts_getInnerText(t.tBodies[0].rows[i].cells[column]);
        itm = trim(itm);
        if (itm.substr(0,4) == "<!--" || itm.length == 0) itm = "";
        i++;
    }
    if (itm == "") return;
    sortfn = ts_sort_caseinsensitive;
    if (itm.match(/^-?[�$�ۢ�]\d/)) sortfn = ts_sort_numeric;
    if (itm.match(/^-?(\d+[,\.]?)+(E[-+][\d]+)?%?$/)) sortfn = ts_sort_numeric;
    SORT_COLUMN_INDEX = column;
    var firstRow = new Array();
    var newRows = new Array();
    for (k=0;k<t.tBodies.length;k++) {
        for (i=0;i<t.tBodies[k].rows[0].length;i++) {
            firstRow[i] = t.tBodies[k].rows[0][i];
        }
    }
    for (k=0;k<t.tBodies.length;k++) {
        if (!thead)
            // Skip the first row
            for (j=1;j<t.tBodies[k].rows.length;j++)
                    newRows[j-1] = t.tBodies[k].rows[j];
        else
            // Do NOT skip the first row
            for (j=0;j<t.tBodies[k].rows.length;j++)
                    newRows[j] = t.tBodies[k].rows[j];
    }
    newRows.sort(sortfn);
    if (span.getAttribute("sortdir") == 'down') {
        ARROW = '&nbsp;&nbsp;<img src="'+ image_path + image_down + '" alt="&darr;"/>';
        newRows.reverse();
        span.setAttribute('sortdir','up');
    } else {
        ARROW = '&nbsp;&nbsp;<img src="'+ image_path + image_up + '" alt="&uarr;"/>';
        span.setAttribute('sortdir','down');
    }
// We appendChild rows that already exist to the tbody, so it moves them rather than creating new ones
// don't do sortbottom rows
    for (i=0; i<newRows.length; i++)
        if (!newRows[i].className || (newRows[i].className && (newRows[i].className.indexOf('sortbottom') == -1)))
            t.tBodies[0].appendChild(newRows[i]);
// do sortbottom rows only
    for (i=0; i<newRows.length; i++)
        if (newRows[i].className && (newRows[i].className.indexOf('sortbottom') != -1))
            t.tBodies[0].appendChild(newRows[i]);

    // Delete any other arrows there may be showing
    var allspans = document.getElementsByTagName("span");
    for (var ci=0;ci<allspans.length;ci++)
        if (allspans[ci].className == 'sortarrow')
            if (getParent(allspans[ci],"table") == getParent(lnk,"table")) // in the same table as us?
                allspans[ci].innerHTML = '&nbsp;&nbsp;<img src="'+ image_path + image_none + '" alt="&darr;"/>';
    span.innerHTML = ARROW;
    alternate(t);
}

function getParent(el, pTagName) {
    if (el == null)
        return null;
    else if (el.nodeType == 1 && el.tagName.toLowerCase() == pTagName.toLowerCase())
        return el;
    else
        return getParent(el.parentNode, pTagName);
}

function ts_sort_numeric(a,b) {
    var aa = ts_getInnerText(a.cells[SORT_COLUMN_INDEX]);
    aa = clean_num(aa);
    var bb = ts_getInnerText(b.cells[SORT_COLUMN_INDEX]);
    bb = clean_num(bb);
    return compare_numeric(aa,bb);
}
function compare_numeric(a,b) {
    var aa = parseFloat(a);
    aa = (isNaN(aa) ? 0 : aa);
    var bb = parseFloat(b);
    bb = (isNaN(bb) ? 0 : bb);
    return aa - bb;
}
function ts_sort_caseinsensitive(a,b) {
    aa = ts_getInnerText(a.cells[SORT_COLUMN_INDEX]).toLowerCase();
    bb = ts_getInnerText(b.cells[SORT_COLUMN_INDEX]).toLowerCase();
    if (aa==bb) {
        return 0;
    }
    if (aa<bb) {
        return -1;
    }
    return 1;
}
function ts_sort_default(a,b) {
    aa = ts_getInnerText(a.cells[SORT_COLUMN_INDEX]);
    bb = ts_getInnerText(b.cells[SORT_COLUMN_INDEX]);
    if (aa==bb) {
        return 0;
    }
    if (aa<bb) {
        return -1;
    }
    return 1;
}
function addEvent(elm, evType, fn, useCapture) {
// addEvent and removeEvent
// cross-browser event handling for IE5+,	NS6 and Mozilla
// By Scott Andrew
    if (elm.addEventListener){
        elm.addEventListener(evType, fn, useCapture);
        return true;
    } else if (elm.attachEvent){
        var r = elm.attachEvent("on"+evType, fn);
        return r;
    } else {
        alert("Handler could not be removed");
        return false;
    }
}
function clean_num(str) {
    str = str.replace(new RegExp(/[^-?0-9.]/g),"");
    return str;
}
function trim(s) {
    return s.replace(/^\s+|\s+$/g, "");
}
function alternate(table) {
    // Take object table and get all it's tbodies.
    var tableBodies = table.getElementsByTagName("tbody");
    // Loop through these tbodies
    for (var i = 0; i < tableBodies.length; i++) {
        // Take the tbody, and get all it's rows
        var tableRows = tableBodies[i].getElementsByTagName("tr");
        // Loop through these rows
        // Start at 1 because we want to leave the heading row untouched
        for (var j = 0; j < tableRows.length; j++) {
            // Check if j is even, and apply classes for both possible results
            if ( (j % 2) == 0  ) {
                if ( !(tableRows[j].className.indexOf('odd') == -1) )
                    tableRows[j].className = tableRows[j].className.replace('odd', 'even');
                else if ( tableRows[j].className.indexOf('even') == -1 )
                            tableRows[j].className += " even";
            } else {
                if ( !(tableRows[j].className.indexOf('even') == -1) )
                    tableRows[j].className = tableRows[j].className.replace('even', 'odd');
                else if ( tableRows[j].className.indexOf('odd') == -1 )
                        tableRows[j].className += " odd";
            }
        }
    }
}
