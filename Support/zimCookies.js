// go around Wombat.js overriding Date.now()
function currentDate() {
    if (typeof __wb_Date_now == "function") {
        return new Date(__wb_Date_now());
    }
    return new Date();
}

const construct = (type, values) => ({
    case: (cases) => cases[type].apply(null, values),
});

// possible outcomes of maxDate | expiryDate values
const ExpiryCheck = {
    Date: (dateValue) => construct("Date", [dateValue]),
    NoDate: construct("NoDate", []),
    Expired: construct("Expired", []),
};

class ZimCookieStore {
    constructor() {
        this.store = new Map();
    }

    // document.cookie API
    cookies(now = currentDate()) {
        var parts = new Array();
        var expiredKeys = new Array();
        for (const [key, valueAndDate] of this.store.entries()) {
            if (this.isExpired(valueAndDate, now)) {
                expiredKeys.push(key);
            } else {
                const { value: cookieValue } = valueAndDate;
                parts.push([key, cookieValue].join("="));
            }
        }
        expiredKeys.forEach((key) => this.store.delete(key));
        return parts.join("; ");
    }

    save(cookie, now = currentDate()) {
        const [keyValue, ...attributes] = String(cookie).split(";");
        const [rawKey, ...rawVal] = String(keyValue ?? "").split("=");
        const key = (rawKey ?? "").trim();
        const value = rawVal.join("=").trim();
        if (!key) {
            console.warn("invalid cookie key:", key);
            return;
        }

        const attrMap = new Map(
            attributes
                .map((s) => String(s).trim())
                .filter(Boolean)
                .map((s) => {
                    const [k, ...v] = s.split("=");
                    return [String(k).trim().toLowerCase(), v.join("=").trim()];
                }),
        );
        const maxAge = attrMap.get("max-age");
        const expires = attrMap.get("expires");

        this.mapToExpiry(maxAge, expires, now).case({
            Date: (expiryDate) => this.store.set(key, { value: value, expiryDate: expiryDate }),
            NoDate: () => this.store.set(key, { value: value, expiryDate: null }), // session only
            Expired: () => this.store.delete(key),
        });
    }

    // Cookie Store API
    async set(keyOrOptions, inputValue, inputOptions = {}, now = currentDate()) {
        let key;
        let value;
        let options;

        if (typeof keyOrOptions === "string") {
            key = keyOrOptions;
            value = inputValue;
            options = inputOptions || {};
        } else {
            options = keyOrOptions || {};
            key = options.name;
            value = options.value;
        }

        if (!key) {
            throw new TypeError("Cookie name is required");
        }
        if (value === undefined) {
            throw new TypeError("Cookie value is required");
        }

        this.mapToExpiry(options.maxAge, options.expires, now).case({
            Date: (expiryDate) => this.store.set(key, { value: value, expiryDate: expiryDate }),
            NoDate: () => this.store.set(key, { value: value, expiryDate: null }), // session only
            Expired: () => this.store.delete(key),
        });
    }

    async getAll(keyOrOptions, now = currentDate()) {
        const key = keyOrOptions === undefined ? undefined : this.getKeyFrom(keyOrOptions);
        const result = [];
        for (const [name, valueAndDate] of this.store) {
            if (this.isExpired(valueAndDate, now)) {
                this.store.delete(name);
                continue;
            }
            if (key === undefined || name === key) {
                result.push({
                    name,
                    value: valueAndDate.value,
                });
            }
        }
        return result;
    }

    async get(keyOrOptions, now = currentDate()) {
        const key = this.getKeyFrom(keyOrOptions);
        const valueAndDate = this.store.get(key);
        if (valueAndDate === undefined) {
            return null;
        }
        if (this.isExpired(valueAndDate, now)) {
            this.store.delete(key);
            return null;
        }
        return { name: key, value: valueAndDate.value };
    }

    async delete(keyOrOptions) {
        const key = this.getKeyFrom(keyOrOptions);
        this.store.delete(key);
    }

    // helpers
    mapToExpiry(maxAge, expires, now) {
        // for inputs
        if (maxAge !== undefined) {
            const maxAgeNumber = Number(maxAge);
            if (Number.isFinite(maxAgeNumber)) {
                if (maxAgeNumber <= 0) {
                    return ExpiryCheck.Expired;
                } else {
                    const expiry = new Date(now.getTime() + maxAgeNumber * 1000);
                    return ExpiryCheck.Date(expiry);
                }
            }
        } else if (expires !== undefined) {
            const expiryDate = new Date(expires);
            if (!isNaN(expiryDate)) {
                if (now < expiryDate) {
                    return ExpiryCheck.Date(expiryDate);
                } else {
                    return ExpiryCheck.Expired;
                }
            }
        }
        return ExpiryCheck.NoDate;
    }

    isExpired(valueAndDate, now) {
        //for outputs
        return valueAndDate.expiryDate != null && valueAndDate.expiryDate <= now;
    }

    getKeyFrom(keyOrOptions) {
        if (typeof keyOrOptions === "string") {
            return keyOrOptions;
        }
        if (keyOrOptions !== null && typeof keyOrOptions === "object") {
            const key = keyOrOptions.name;
            if (!key) {
                throw new TypeError("Cookie name is required");
            }
            return key;
        }
        throw new TypeError("Cookie name is required");
    }

    // persistence

    valueToPersist() {
        const entries = Array.from(this.store).filter((entry) => {
            return entry[1].expiryDate != null;
        });
        return JSON.stringify(entries);
    }

    persist() {
        const zimCookies = window.webkit?.messageHandlers?.zimCookies;
        zimCookies?.postMessage(this.valueToPersist());
    }

    load(values) {
        try {
            this.store = new Map(JSON.parse(values));
        } catch (e) {
            console.warn("Invalid ZIM cookies payload, resetting store:", e);
            this.store = new Map();
        }
    }
}

// Cookie Store API Wrapper
class CookieStoreShim {
    #store = __zimCookieStore;

    async set(keyOrOptions, inputValue, inputOptions = {}) {
        await this.#store.set(keyOrOptions, inputValue, inputOptions);
        this.#store.persist();
    }

    async get(keyOrOptions) {
        return this.#store.get(keyOrOptions);
    }

    async getAll(keyOrOptions) {
        return this.#store.getAll(keyOrOptions);
    }

    async delete(keyOrOptions) {
        await this.#store.delete(keyOrOptions);
        this.#store.persist();
    }
}

// SHIMs
const __zimCookieStore = new ZimCookieStore();
const __cookieStoreShim = new CookieStoreShim();

// save the cookies on native side
function getZIMCookies() {
    __zimCookieStore.persist();
}

// injecting cookies from native side here, it should be JSON encoded
function setZIMCookies(newValue) {
    __zimCookieStore.load(newValue);
}

(function () {
    // document.cookie SHIM

    // 1. Get the original native setter from the Prototype
    const cookieDescriptor =
        Object.getOwnPropertyDescriptor(Document.prototype, "cookie") ||
        Object.getOwnPropertyDescriptor(HTMLDocument.prototype, "cookie");

    if (!cookieDescriptor) {
        console.error("Could not find cookie descriptor.");
        return;
    }

    // 2. Redefine the property with custom hooks
    Object.defineProperty(Document.prototype, "cookie", {
        configurable: true,
        enumerable: true,

        get: function () {
            return __zimCookieStore.cookies();
        },

        // Intercept updates
        set: function (newValue) {
            __zimCookieStore.save(newValue);
            __zimCookieStore.persist();
        },
    });

    // Cookie Store API SHIM
    Object.defineProperty(window, "cookieStore", {
        configurable: true,
        enumerable: true,

        get() {
            return __cookieStoreShim;
        },
    });
})();

// important to let the native side know we are ready for receiving saved cookie values
window.webkit?.messageHandlers?.zimCookies?.postMessage("zimCookieStoreReady");
