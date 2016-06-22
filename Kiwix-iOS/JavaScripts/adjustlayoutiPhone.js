/**
 * Created by chrisli on 10/5/15.
 */
function adjustTables() {
	var tables = document.getElementsByTagName("table");
	var i;
	for (i = 0; i < tables.length; i++) {
	    org_html = tables[i].outerHTML;
	    new_html = "<div id='slidesInner' style ='width:100%;'>" + org_html + "</div>";
	    tables[i].outerHTML = new_html;
	    tables[i].parentNode.style.overflow = "auto";
	    tables[i].style.margin = "auto";
	    tables[i].style.width = "100%";
	}
}

function adjustThumbLayout(thumbs) {
	var i;
	for (i = 0; i < thumbs.length; i++) {
		thumbs[i].style.width = "100%";
		thumbs[i].style.paddingLeft = "4px";
        thumbs[i].style.paddingRight = "4px";
		var inner = thumbs[i].getElementsByClassName("thumbinner")[0];
		if (inner) {
			inner.style.width = "100%";
			var captions = inner.getElementsByClassName("thumbcaption");
			var j;
			for (j= 0; j < captions.length; j++) {
				captions[j].style.textAlign = "center";
			}
		}
	}
}

adjustTables();
adjustThumbLayout(document.getElementsByClassName("thumb tright"));
adjustThumbLayout(document.getElementsByClassName("thumb tleft"));
adjustThumbLayout(document.getElementsByClassName("thumb tmulti tright"));
adjustThumbLayout(document.getElementsByClassName("thumb tmulti tleft"));
