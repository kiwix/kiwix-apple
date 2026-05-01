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

    let pending = null
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

    function clearTimeout(entry) {
        if (entry && entry.timeoutHandle !== undefined) {
            clearTimeout(entry.timeoutHandle)
            entry.timeoutHandle = undefined
        }
    }

    window.__kiwixGeolocationResolve = function (payload) {
        const entry = pending
        if (!entry) { return }
        if (payload && payload.coords) {
            clearTimeout(entry)
            deliverSuccess(entry.success, payload)
        } else if (payload && payload.error) {
            clearTimeout(entry)
            deliverError(entry.error, payload.error)
        }
        const isPermissionDenied = !!(payload && payload.error && payload.error.code === 1)
        if (!entry.isWatch || isPermissionDenied) {
            pending = null
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
            if (!pending) { return }
            pending = null
            deliverError(entry.error, {
                code: 3,
                message: 'Location request timed out.'
            })
        }, options.timeout)
    }

    function getCurrentPosition(success, error, options) {
        pending = { success: success, error: error, isWatch: false }
        armTimeoutFor(pending, options)
        handler.postMessage({
            type: 'getCurrentPosition',
            highAccuracy: !!(options && options.enableHighAccuracy)
        })
    }

    function watchPosition(success, error, options) {
        // watchPosition's spec timeout fires on each acquisition attempt
        // (not the watch as a whole) and the watch must continue trying. The
        // current bridge doesn't model per-update timing, so we deliberately
        // skip it here rather than implement a half-correct version.
        pending = { success: success, error: error, isWatch: true }
        handler.postMessage({
            type: 'watchPosition',
            highAccuracy: !!(options && options.enableHighAccuracy)
        })
        const id = nextId++
        return id
    }

    function clearWatch() {
        const entry = pending
        if (!entry) { return }
        clearTimeout(entry)
        pending = null
        handler.postMessage({ type: 'clearWatch' })
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
