To run these javascript unit tests, you need to run symlink 2 files via CLI (from this test folder):
```
ln -s ../icon.png icon.png
ln -s ../zimCookies.js zimCookies.js
```

To have a true comparison between the ZimCookieStore implemenation and the browser supported API, the SHIMs should be commented out in the zimCookies.js file, starting here:
```
(function () {
    // document.cookie SHIM
```

With that ready you can run it by using a local server:
```
python3 -m http.server
```

Note: the Cookie Store API is not working in Safari browser over pure http, it requires https.
Nevertheless the tests can be run fine in Firefox, where everything runs OK.