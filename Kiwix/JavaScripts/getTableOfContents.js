function getTableOfContents() {
    var h1 = document.getElementsByTagName('h1')[0];
    var headers = [elementToObject(h1)];
    
    var content = document.getElementById("mw-content-text");
    var headerTags = ['h2', 'h3', 'h4'].map(function(x){ return x.toUpperCase() });
    for (var i = 0; i < content.children.length; i++) {
        var element = content.children[i];
        if (headerTags.includes(element.tagName)) {
            headers.push(elementToObject(element));
        }
    }
    return headers;
}

function elementToObject(element) {
    var obj = {};
    obj.id = element.id;
    obj.textContent = element.textContent;
    obj.tagName = element.tagName;
    return obj;
}

getTableOfContents();
