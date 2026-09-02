/**
 * Based on: https://alexwlchan.net/2023/testing-javascript-without-a-framework/
 * CC by 4.0 https://creativecommons.org/licenses/by/4.0/
 */
function it(description, body_of_test) {
    handleResult(description, body_of_test());
}

function handleResult(description, testResult) {
    const result = document.createElement("p");
    result.classList.add("test_result");
    if (testResult === true) {
        result.classList.add("success");
        result.innerHTML = description;
    } else {
        result.classList.add("failure");
        result.innerHTML = `${description}<br/><pre>${testResult}</pre>`;
    }
    document.body.appendChild(result);
}

function divider(text) {
    const result = document.createElement("p");
    const mark = "-";
    result.innerHTML = `${mark.repeat(20)} ${text} ${mark.repeat(20)}`;
    document.body.appendChild(result);
}

async function asyncIt(description, body_of_test) {
    handleResult(description, await body_of_test());
}

function assertEqual(x, y) {
    if (x === y) {
        return true;
    }
    if (areObjects(x, y) && equalObjects(x, y)) {
        return true;
    }
    return `${x} != ${y}`;
}

function assertEqualCookies(x, y) {
    if (areObjects(x, y) && x.length === y.length && x.every((element, index) => equalCookies(element, y[index]))) {
        return true;
    }
    console.log({ x }, { y });
    return `${x} != ${y}`;
}

function assertEqualCookie(x, y) {
    if (areObjects(x, y) && equalCookies(x, y)) {
        return true;
    }
    console.log({ x }, { y });
    return `${x} != ${y}`;
}

function areObjects(x, y) {
    return typeof x === "object" && typeof y === "object";
}

function equalObjects(x, y) {
    return x.length === y.length && x.every((element, index) => element === y[index]);
}

function equalCookies(x, y) {
    return x.name === y.name && x.value === y.value;
}
