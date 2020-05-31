function Outlines () {
    this.headings = document.querySelectorAll("h1, h2, h3, h4, h5, h6");

    this.getHeadingObjects = function () {
        var headings = [];
        for (i = 0; i < this.headings.length; i++) { 
            var element = this.headings[i];
            var obj = {};
            obj.index = i;
            obj.tagName = element.tagName;
            obj.textContent = element.textContent;
            headings.push(obj);
        }
        return headings;
    }

    this.scrollToView = function (index) {
        this.headings[index].scrollIntoView();
    }

    this.getVisibleHeadingIndex = function () {
        var viewHeight = Math.max(document.documentElement.clientHeight, window.innerHeight);
        var aboveIndexes = [];
        var visibleIndexes = [];
        var belowIndexes = [];

        for (i = 0; i < this.headings.length; i++) { 
            var element = this.headings[i];
            var rect = element.getBoundingClientRect();

            var isAboveTopBorder = rect.top - 10 < 0;
            var isBelowBottomBorder = viewHeight - rect.top < 0;

            if (isAboveTopBorder) {
                aboveIndexes.push(i);
            } else if (isBelowBottomBorder) {
                belowIndexes.push(i);
            } else {
                visibleIndexes.push(i);
            }
        }

        if (aboveIndexes.length > 0) {
            return [aboveIndexes[aboveIndexes.length-1]].concat(visibleIndexes);
        } else {
            return visibleIndexes;
        }
    }

    this.startCallBack = function () {
        var handleScroll = function() {
            var indexes = tableOfContents.getVisibleHeadingIndex();
            if (indexes.length > 0) {
                window.location = 'pagescroll:scrollEnded?start=' + indexes[0] + '&length=' + indexes.length;
            }
        }
        window.onscroll = handleScroll;
        handleScroll();
    }

    this.stopCallBack = function () {
        window.onscroll = undefined;
    }
}

function Snippet () {
    this.parse = function () {
        var snippet = '';
        var elements = document.getElementsByTagName('p');
        for (i = 0; i < elements.length; i++) {
            var localSnippet = this.extractCleanText(elements[i]);
            if (snippet != '') {snippet += ' ';}
            snippet += localSnippet;
            if (snippet.length > 200) {break;}
        }
        var parts = snippet.split(".");
        if (parts.length > 0 && parts[0].length > 0) {
            snippet = parts[0] + ".";
        }
        return snippet;
    }

    this.extractCleanText = function (element) {
        var text = element.textContent || element.innerText || "";
        if (text.replace(/\s/g, '').length) {
            var regex = /\[[0-9|a-z|A-Z| ]*\]/g;
            text = text.replace(regex, "");
            return text;
        } else {
            return '';
        }
    }
}

function getImageURLs () {
    return [...document.getElementsByTagName("img")].map(e => e.src)
}

var outlines = new Outlines();
var snippet = new Snippet();
document.querySelectorAll("details").forEach((detail) => {detail.setAttribute("open", true)});
