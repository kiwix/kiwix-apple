var __zimCookieStore = new Map();

// input should be in the format of nested arrays: [[key1, value1], [key2, value2]]
// eg: setZIMCookies([["theme", "light"], ["width", "narrow"]]);
function setZIMCookies(newValue) {
  __zimCookieStore = new Map(newValue);
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

  const nativeSet = cookieDescriptor.set;

  // 2. Redefine the property with custom hooks
  Object.defineProperty(Document.prototype, "cookie", {
    configurable: true,
    enumerable: true,

    get: function () {
      return allZIMCookies();
    },

    // Intercept updates
    set: function (newValue) {
      // storeZIMCookie(newValue);
      const zimCookies = window.webkit?.messageHandlers?.zimCookies;
      zimCookies?.postMessage(newValue);
      nativeSet.call(this, newValue);
    },
  });

  // Gets back the cookies in the same form
  // as document.cookies getter returns them.
  // It is only really key, values
  function allZIMCookies() {
    const parts = [...__zimCookieStore].map(([key, value], _) => {
      return key + "=" + value;
    });
    return parts.join("; ");
  }

})();
