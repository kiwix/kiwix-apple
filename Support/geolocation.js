// Bridge the HTML5 Geolocation API to CoreLocation via a script message handler.
// This lets map ZIM files (e.g. WikiVoyage, the maps_* scraper output) use
// navigator.geolocation; the native side prompts the user for CoreLocation
// permission on first use. Supports both getCurrentPosition (one-shot) and
// watchPosition (continuous).
//
// Loaded at .atDocumentStart so <head> scripts that call navigator.geolocation
// during initial parse hit the shim, not the broken WKWebView native API path.
(function () {
    const handler = window.webkit &&
        window.webkit.messageHandlers &&
        window.webkit.messageHandlers.geolocation
    if (!handler) {
        // Surface installation state explicitly so the Web Inspector can tell
        // "not installed" apart from "script never ran".
        window.__kiwixGeolocationShimInstalled = false
        return
    }

    const pending = new Map()
    let nextId = 1

    function deliverSuccess(success, payload) {
        if (typeof success !== 'function') { return }
        success({
            coords: {
                latitude: payload.coords.latitude,
                longitude: payload.coords.longitude,
                accuracy: payload.coords.accuracy,
                altitude: payload.coords.altitude ?? null,
                altitudeAccuracy: payload.coords.altitudeAccuracy ?? null,
                heading: payload.coords.heading ?? null,
                speed: payload.coords.speed ?? null
            },
            timestamp: payload.timestamp
        })
    }

    function deliverError(error, err) {
        if (typeof error !== 'function') { return }
        error({
            code: err.code,
            message: err.message,
            PERMISSION_DENIED: 1,
            POSITION_UNAVAILABLE: 2,
            TIMEOUT: 3
        })
    }

    window.__kiwixGeolocationResolve = function (id, payload) {
        const entry = pending.get(id)
        if (!entry) { return }
        if (payload && payload.coords) {
            deliverSuccess(entry.success, payload)
        } else if (payload && payload.error) {
            deliverError(entry.error, payload.error)
        }
        // One-shot requests are cleaned up after a single delivery. Watches
        // are normally retained until clearWatch() — except permission denial,
        // which the native side won't recover from, so drop the entry to
        // avoid a stale handler hanging on for the page's lifetime.
        const isPermissionDenied = !!(payload && payload.error && payload.error.code === 1)
        if (!entry.isWatch || isPermissionDenied) {
            pending.delete(id)
        }
    }

    function getCurrentPosition(success, error, options) {
        const id = nextId++
        pending.set(id, { success: success, error: error, isWatch: false })
        handler.postMessage({
            type: 'getCurrentPosition',
            id: id,
            highAccuracy: !!(options && options.enableHighAccuracy)
        })
    }

    function watchPosition(success, error, options) {
        const id = nextId++
        pending.set(id, { success: success, error: error, isWatch: true })
        handler.postMessage({
            type: 'watchPosition',
            id: id,
            highAccuracy: !!(options && options.enableHighAccuracy)
        })
        return id
    }

    function clearWatch(id) {
        if (!pending.has(id)) { return }
        pending.delete(id)
        handler.postMessage({ type: 'clearWatch', id: id })
    }

    const shim = {
        getCurrentPosition: getCurrentPosition,
        watchPosition: watchPosition,
        clearWatch: clearWatch
    }
    let installed = false
    try {
        Object.defineProperty(navigator, 'geolocation', {
            configurable: true,
            value: shim
        })
        installed = true
    } catch (_) {
        try {
            // Some hardened runtimes mark navigator.geolocation non-configurable
            // on the instance; the prototype property is still replaceable.
            Object.defineProperty(Object.getPrototypeOf(navigator), 'geolocation', {
                configurable: true,
                value: shim
            })
            installed = true
        } catch (_) {
            // Native navigator.geolocation stays in place.
        }
    }
    window.__kiwixGeolocationShimInstalled = installed
})();
