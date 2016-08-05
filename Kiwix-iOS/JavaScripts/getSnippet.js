function getSnippet() {
    var element = document.getElementById('mw-content-text');
    if (element) {
        var children = element.children;
        for (i = 0; i < children.length; i++) {
        var child = children[i];
        if (child.tagName == 'P') {
            var text = child.textContent || child.innerText || "";
            if (text.replace(/\s/g, '').length) {
                var regex = /\[[0-9|a-z|A-Z| ]*\]/g;
                text = text.replace(regex, "");
                return text;
                }
            }
        }

    }
}
getSnippet();