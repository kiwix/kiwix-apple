function TableOfContents () {
    this.headings = document.querySelectorAll("h1, h2, h3, h4, h5, h6");

    this.getHeadingObjects = function () {
        var headings = [];
        for (i = 0; i < this.headings.length; i++) { 
            var element = this.headings[i];
            var obj = {};
            obj.id = element.id;
            obj.index = i;
            obj.textContent = element.textContent;
            obj.tagName = element.tagName;
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

var tableOfContents = new TableOfContents();
