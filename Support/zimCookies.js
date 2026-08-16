// go around Wombat.js overriding Date.now()
function currentDate() {
  if(typeof(__wb_Date_now) == "function") {
    return new Date(__wb_Date_now());
  }
  return new Date();
}

class ZimCookieStore {
  constructor() {
    this.store = new Map();
  }

  cookies(now = currentDate()) {
    var parts = new Array();
    for (const [key, valueAndDate] of this.store.entries()) {
      const { expiryDate: expDate } = valueAndDate;
      if (expDate != null && expDate <= now) {
        continue;
      } else {
        const { value: cookieValue } = valueAndDate;
        parts.push([key, cookieValue].join("="));
      }
    }
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
    if (maxAge !== undefined) {
      const maxAgeNumber = Number(maxAge);
      if (Number.isFinite(maxAgeNumber)) {
        if (maxAgeNumber <= 0) {
          this.store.delete(key);
          return;
        } else {
          const expiry = new Date(now.getTime() + maxAgeNumber * 1000);
          this.store.set(key, {
            value: value,
            expiryDate: expiry,
          });
          return;
        }
      }
    } else if (expires !== undefined) {
      const expiryDate = new Date(expires);
      if (!isNaN(expiryDate)) {
        if (now < expiryDate) {
          this.store.set(key, {
            value: value,
            expiryDate: expiryDate,
          });
          return;
        } else {
          this.store.delete(key);
          return;
        }
      }
    }
    // store in session only, without a specific date:
    this.store.set(key, { value: value, expiryDate: null });
  }

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
      console.warn('Invalid ZIM cookies payload, resetting store:', e);
      this.store = new Map();
    }
  }
}

// SHIM
var __zimCookieStore = new ZimCookieStore();

// save the cookies on native side
function getZIMCookies() {
  __zimCookieStore.persist();
}

// injecting cookies from native side here, it should be JSON encoded
function setZIMCookies(newValue) {
  __zimCookieStore.load(newValue);
}

(function () {
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
})();
