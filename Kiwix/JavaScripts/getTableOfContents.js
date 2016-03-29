function getTOC() {
	var content = document.getElementById("mw-content-text");
	var headers = [];

	if (content) {
		for (var i = 0; i < content.children.length; i++) {
			var element = content.children[i];
			if (element.tagName.toUpperCase() == "h2".toUpperCase()) {
				var h2Headline = element.children[0]
				headers.push({
					key: "h2",
					value: h2Headline.textContent
				});
			}
		}
	}

	return headers.length
}

function getCount() {
	var content = document.getElementById("mw-content-text");
	var headers = [];

	if (content) {
		for (var i = 0; i < content.children.length; i++) {
			var element = content.children[i];
			if (element.tagName.toUpperCase() == "h2".toUpperCase() || element.tagName.toUpperCase() == "h3".toUpperCase()) {
				var header = {};
				header.id = element.getAttribute("id");
				header.textContent = element.textContent;
				header.tagName = element.tagName;
				headers.push(header);
			}
		}
	}

	return headers;
}
getCount();