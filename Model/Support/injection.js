// expand all detail tags
document.querySelectorAll('details').forEach( detail => detail.setAttribute('open', true) )

// generate id for all headings if there isn't one already
let headings = Array.from(document.querySelectorAll('h1, h2, h3, h4, h5, h6'))
headings.forEach( (heading, index) => {
	if (!heading.id) {
		let parts = heading.textContent.trim().split(' ').concat([index])
		heading.id = parts.join('_')
	}
})

// convert all headings into objects and send it to app side
function getOutlineItem() {
	window.webkit.messageHandlers.headings.postMessage(
		headings.map( heading => {
			return {
				id: heading.id,
				text: heading.textContent.trim(),
				tag: heading.tagName,
			}
		})
	)
}

// create observer and register headings
let observer = new IntersectionObserver(function(entries) {
	for (index in entries) {
		let entry = entries[index]
		console.log(entry)
		if (entry.isIntersecting === false && entry.boundingClientRect.top <= entry.rootBounds.top) {
			window.webkit.messageHandlers.headingVisible.postMessage({id: entry.target.id})
			return
		} else if (
			entry.isIntersecting === false &&
			entry.boundingClientRect.bottom > entry.rootBounds.bottom
		) {
			let index = headings.findIndex(element => element.id == entry.target.id )
			let previousHeading = headings[index - 1]
			window.webkit.messageHandlers.headingVisible.postMessage({id: previousHeading.id})
			return
		}
	}
}, { rootMargin: '-50px 0 -35% 0', threshold: 1.0 });
headings.forEach( heading => { observer.observe(heading) });

// top element
window.onscroll = function() {
	if (document.documentElement.scrollTop <= 0) {
		window.webkit.messageHandlers.headingVisible.postMessage({id: headings[0].id})
	}
}