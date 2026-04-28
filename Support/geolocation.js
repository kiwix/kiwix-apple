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

    function clearTimeoutFor(entry) {
        if (entry && entry.timeoutHandle !== undefined) {
            clearTimeout(entry.timeoutHandle)
            entry.timeoutHandle = undefined
        }
    }

    window.__kiwixGeolocationResolve = function (id, payload) {
        const entry = pending.get(id)
        if (!entry) { return }
        if (payload && payload.coords) {
            // Got a position — clear any pending timeout for this entry; for
            // watches, the next update will rearm via callers as needed.
            clearTimeoutFor(entry)
            deliverSuccess(entry.success, payload)
        } else if (payload && payload.error) {
            clearTimeoutFor(entry)
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

    function armTimeoutFor(entry, options) {
        // W3C Geolocation: if options.timeout is a positive finite number,
        // fire the error callback with TIMEOUT (3) and stop trying. Native
        // CoreLocation can take 30+ seconds (or never deliver) on a cold
        // start with poor signal — without this, pages relying on a timeout
        // hang forever and the pending entry leaks for the page lifetime.
        if (!options || typeof options.timeout !== 'number') { return }
        if (!isFinite(options.timeout) || options.timeout <= 0) { return }
        entry.timeoutHandle = setTimeout(function () {
            if (!pending.has(entry.id)) { return }
            pending.delete(entry.id)
            deliverError(entry.error, {
                code: 3,
                message: 'Location request timed out.'
            })
        }, options.timeout)
    }

    function getCurrentPosition(success, error, options) {
        const id = nextId++
        const entry = { id: id, success: success, error: error, isWatch: false }
        pending.set(id, entry)
        armTimeoutFor(entry, options)
        handler.postMessage({
            type: 'getCurrentPosition',
            id: id,
            highAccuracy: !!(options && options.enableHighAccuracy)
        })
    }

    function watchPosition(success, error, options) {
        const id = nextId++
        // watchPosition's spec timeout fires on each acquisition attempt
        // (not the watch as a whole) and the watch must continue trying. The
        // current bridge doesn't model per-update timing, so we deliberately
        // skip it here rather than implement a half-correct version.
        pending.set(id, { id: id, success: success, error: error, isWatch: true })
        handler.postMessage({
            type: 'watchPosition',
            id: id,
            highAccuracy: !!(options && options.enableHighAccuracy)
        })
        return id
    }

    function clearWatch(id) {
        const entry = pending.get(id)
        if (!entry) { return }
        clearTimeoutFor(entry)
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
