(async () => {
    divider("Cookie Store API tests");

    await asyncIt("set one and getAll cookies", async () => {
        const store = new ZimCookieStore();
        await store.set("testKey", "some value");
        await cookieStore.set("testKey", "some value");

        const zimCookies = await store.getAll();
        const realCookies = await cookieStore.getAll();
        // clean up:
        return assertEqualCookies(zimCookies, realCookies);
    });
    // clean up
    await cookieStore.delete("testKey");

    const kv1 = { key: "key1", value: "one value is 1" };
    const kv2 = { key: "key2", value: "two value is 2" };
    await asyncIt("set two cookies and get them back one by one", async () => {
        const store = new ZimCookieStore();
        await store.set(kv1.key, kv1.value);
        await store.set(kv2.key, kv2.value);
        await cookieStore.set(kv1.key, kv1.value);
        await cookieStore.set(kv2.key, kv2.value);
        const storeResults = [await store.get(kv1.key), await store.get(kv2.key)];
        const cookieResults = [await cookieStore.get(kv1.key), await cookieStore.get(kv2.key)];
        return assertEqualCookies(storeResults, cookieResults);
    });
    // clean up
    await cookieStore.delete(kv1.key);
    await cookieStore.delete(kv2.key);

    const key = "random";
    await asyncIt("overwrite a value", async () => {
        const store = new ZimCookieStore();
        await store.set(key, "first value");
        await cookieStore.set(key, "first value");
        const finalValue = "other value";
        await store.set(key, finalValue);
        await cookieStore.set(key, finalValue);
        return assertEqualCookies(await store.getAll(), await cookieStore.getAll());
    });
    // clean up
    cookieStore.delete(key);

    await asyncIt("setting an expiry date", async () => {
        const store = new ZimCookieStore();
        await store.set({ name: key, value: "obj value", maxAge: 20 });
        await cookieStore.set({ name: key, value: "obj value", maxAge: 20 });
        const zimCookies = await store.getAll();
        const realCookies = await cookieStore.getAll();
        return assertEqualCookies(zimCookies, realCookies);
    });

    await asyncIt("delete a value", async () => {
        const store = new ZimCookieStore();
        await store.set(key, "some value");
        await cookieStore.set(key, "some value");
        await store.delete(key);
        await cookieStore.delete(key);
        return assertEqualCookies(await store.getAll(), await cookieStore.getAll());
    });

    await asyncIt("delete by object key", async () => {
        const store = new ZimCookieStore();
        await store.set(key, "some value");
        await cookieStore.set(key, "some value");
        await store.delete({ name: key });
        await cookieStore.delete({ name: key });
        return assertEqualCookies(await store.getAll(), await cookieStore.getAll());
    });

    await asyncIt("getAll by key", async () => {
        const store = new ZimCookieStore();
        await store.set(kv1.key, kv1.value);
        await store.set(kv2.key, kv2.value);
        await cookieStore.set(kv1.key, kv1.value);
        await cookieStore.set(kv2.key, kv2.value);

        const storeResult = await store.getAll(kv1.key);
        const cookieResult = await cookieStore.getAll(kv1.key);
        return assertEqualCookies(storeResult, cookieResult);
    });
    await cookieStore.delete(kv1.key); // clean up
    await cookieStore.delete(kv2.key); // clean up

    await asyncIt("get by object key", async () => {
        const store = new ZimCookieStore();
        await store.set(key, "extra");
        await cookieStore.set(key, "extra");

        const storeResult = await store.get({ name: key });
        const cookieResult = await cookieStore.get({ name: key });
        return assertEqualCookie(storeResult, cookieResult);
    });
    await cookieStore.delete(key); // clean up

    await asyncIt("try to get an expired cookie", async () => {
        const store = new ZimCookieStore();
        const inThePast = new Date(Date.now() - 9999999);
        const now = new Date();
        const futureDate = new Date(Date.now() + 9999999);
        await store.set(
            { name: key, value: "expired in distant past", expires: now.getTime() },
            undefined,
            undefined,
            inThePast,
        );
        const storeResult = await store.get(key, futureDate);
        return assertEqual(storeResult === null, true);
    });

    await asyncIt("try to get value by non existing key", async () => {
        const store = new ZimCookieStore();
        const cookieResult = await cookieStore.get("non-existing");
        const storeResult = await store.get("non-existing");
        return assertEqual(storeResult, cookieResult);
    });

    await asyncIt("check clean ups", async () => {
        return assertEqualCookies(await cookieStore.getAll(), []);
    });
})();
