var toc = undefined;
var visEle = undefined;
var visibleHeaderIDs = undefined;

function getTableOfContents() {
    toc = toc == undefined ? new TableOfContents() : toc;
    return toc;
}

function TableOfContents () {
    this.getHeaderElements = function () {
        var h1 = document.getElementsByTagName('h1')[0];
        var elememts = [h1];
        
        var content = document.getElementById("mw-content-text");
        var headerTags = ['h2', 'h3', 'h4'].map(function(x){ return x.toUpperCase() });
        for (var i = 0; i < content.children.length; i++) {
            var element = content.children[i];
            if (headerTags.includes(element.tagName)) {
                elememts.push(element);
            }
        }
        return elememts;
    }
    
    this.headerElements = this.getHeaderElements();
    
    this.getHeaderObjects = function () {
        return this.headerElements.map( elementToObject );
    }
    
    this.headerObjects = this.getHeaderObjects();
    
    function elementToObject(element) {
        var obj = {};
        obj.id = element.id;
        obj.textContent = element.textContent;
        obj.tagName = element.tagName;
        return obj;
    }
}

function getVisibleElementsChecker() {
    visEle = visEle == undefined ? new VisibleElements() : visEle;
    return visEle;
}

function VisibleElements () {
    // return a 2d array [[header(h1/h2/h3), p, ul, div]]
    function getElementGroups() {
        var groups = [];
        var group = [document.getElementsByTagName('h1')[0]];
        var contents = document.getElementById("mw-content-text").children;
        var headerTags = ['h2', 'h3', 'h4'].map(function(x){ return x.toUpperCase() });
        
        for (i = 0; i < contents.length; i++) {
            var element = contents[i];
            if (headerTags.includes(element.tagName)) {
                groups.push(group);
                group = []
            }
            group.push(element);
        }
        
        groups.push(group);
        return groups;
    }
    
    this.elementGroups = getElementGroups();
    
    this.getVisibleHeaders = function () {
        var groups = this.elementGroups;
        var viewHeight = Math.max(document.documentElement.clientHeight, window.innerHeight);
        var visibleHeaders = [];
        
        for (i = 0; i < groups.length; i++) {
            var group = groups[i];
            var header = group[0];
            var groupVisible = false;
            
            for (j = 0; j < group.length; j++) {
                var element = group[j];
                var rect = element.getBoundingClientRect();
                var isVisible = !(rect.bottom < 0 || rect.top - viewHeight >= 0);
                groupVisible = groupVisible || isVisible;
                if (isVisible) { // if found an element visible in group, break and check the next group
                    visibleHeaders.push(header)
                    break;
                }
            }
            
            // If found visible groups already, but current group is not visible
            // It means we are checking area below the visible area, should break
            if (visibleHeaders.length > 0 && !groupVisible) {
                break;
            }
        }
        
        return visibleHeaders;
    }
    
    this.getVisibleHeaderIDs = function () {
        return this.getVisibleHeaders().map(function(x){ return x.id });
    }
}

function startCallBack() {
    function arraysEqual(a, b) {
        if (a === b) return true;
        if (a == null || b == null) return false;
        if (a.length != b.length) return false;
        
        for (var i = 0; i < a.length; ++i) {
            if (a[i] !== b[i]) return false;
        }
        return true;
    }
    
    visibleHeaderIDs = getVisibleElementsChecker().getVisibleHeaderIDs();
    window.onscroll = function() {
        var newVisibleHeaderIDs = getVisibleElementsChecker().getVisibleHeaderIDs();
        if (!arraysEqual(visibleHeaderIDs, newVisibleHeaderIDs)) {
            visibleHeaderIDs = newVisibleHeaderIDs;
            console.log(visibleHeaderIDs);
            
            var parameter = visibleHeaderIDs.map(function(x){ return 'header=' + x }).join('&');
            window.location = 'pagescroll:scrollEnded?' + parameter;
        }
    };
}

function stopCallBack() {
    window.onscroll = undefined;
}
