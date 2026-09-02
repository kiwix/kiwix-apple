divider("document.cookie tests");

it("sets up the cookie store with empty value", () => {
    const store = new ZimCookieStore();
    store.load("[]");
    return assertEqual(store.cookies(), "");
});

it("sets up the cookie store with json values", () => {
    const store = new ZimCookieStore();
    store.load(
        '[["name",{"value":"Kiwix Tester","expiryDate":null}],["_pk_id",{"value":"b40=a8","expiryDate":"2027-09-05T19:14:17.000Z"}],["theme",{"value":"dark","expiryDate":"2027-08-14T09:00:00.000Z"}]]',
    );
    return assertEqual(store.cookies(), "name=Kiwix Tester; _pk_id=b40=a8; theme=dark");
});

it("handles invalid load data gracefully", () => {
    const store = new ZimCookieStore();
    store.load("invalid_data");
    return assertEqual(store.cookies(), "");
});

it("handles single quoted data", () => {
    const store = new ZimCookieStore();
    store.save("myKey=O'Reilly; max-age=123456", new Date(1786818460000));
    return assertEqual(
        store.valueToPersist(),
        '[["myKey",{"value":"O\'Reilly","expiryDate":"2026-08-17T04:45:16.000Z"}]]',
    );
});

it("stores a cookie with a value", () => {
    const store = new ZimCookieStore();
    const testCookie = "myKey=value;";
    store.save(testCookie);
    document.cookie = testCookie;
    return assertEqual(store.cookies(), document.cookie);
});

it("stores an empty value cookie", () => {
    const store = new ZimCookieStore();
    const testCookie = "myKey=;";
    store.save(testCookie);
    document.cookie = testCookie;
    return assertEqual(store.cookies(), document.cookie);
});

it("removes a cookie, using max-age = 0", () => {
    const store = new ZimCookieStore();
    const testCookie1 = "myKey=oldValue;";
    const testCookie2 = "myKey=oldValue; max-age=0;";
    store.save(testCookie1);
    store.save(testCookie2);
    document.cookie = testCookie1;
    document.cookie = testCookie2;
    return assertEqual(store.cookies(), document.cookie);
});

it("won't store expired values", () => {
    const store = new ZimCookieStore();
    store.save(
        "my_key=some_value; Expires=Sun, 05 Sep 2027 19:14:00 GMT;",
        new Date("Sun, 05 Sep 2027 19:14:01 GMT"), // we are a second later already
    );
    return assertEqual(store.cookies(), "");
});

it("will return the same as document.cookie for multiple values", () => {
    const store = new ZimCookieStore();
    const cookiesToSet = [
        "name=Kiwix Tester;max-age=300",
        "_pk_id=b40=a; Expires=Sun, 05 Sep 2157 19:14:17 GMT;SameSite=Lax",
        "theme=dark;;max-age=31536000",
    ];
    cookiesToSet.forEach((cookie) => {
        store.save(cookie);
        document.cookie = cookie;
    });
    const valueToPersist = store.valueToPersist();
    const newStore = new ZimCookieStore();
    newStore.load(valueToPersist);

    const stored = newStore
        .cookies()
        .split(";")
        .map((x) => {
            return x.trim();
        })
        .sort();
    const documented = document.cookie
        .split(";")
        .map((x) => {
            return x.trim();
        })
        .sort();

    return assertEqual(stored, documented);
});

it("will set the expiry date correctly", () => {
    cleanUp();

    const store = new ZimCookieStore();
    const now = new Date();
    const cookie = "name=Joe Tester; max-age=31536000";
    store.save(cookie);
    document.cookie = cookie;
    return assertEqual(store.cookies(now), document.cookie);
});

it("won't persist session only items (entries with a null expiry date)", () => {
    const store = new ZimCookieStore();
    store.save("the_key=is session only;");
    return assertEqual(store.valueToPersist(), "[]");
});

function cleanUp() {
    document.cookie.split(";").forEach((cookie) => {
        const cookieName = cookie.split("=")[0].trim();
        // Set cookie max-age to 0 date delete it
        document.cookie = `${cookieName}=; max-age=0;`;
    });
}
it("clean up", () => {
    cleanUp();
    return assertEqual(document.cookie, "");
});
