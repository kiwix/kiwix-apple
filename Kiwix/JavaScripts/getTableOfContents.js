function getTOC() {
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
getTOC();
