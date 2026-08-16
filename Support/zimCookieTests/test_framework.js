/**
 * Based on: https://alexwlchan.net/2023/testing-javascript-without-a-framework/
 * CC by 4.0 https://creativecommons.org/licenses/by/4.0/
 */
function it(description, body_of_test) {
  const result = document.createElement("p");
  result.classList.add("test_result");
  let testResult = body_of_test();
  if (testResult === true) {
    result.classList.add("success");
    result.innerHTML = description;
  } else {
    result.classList.add("failure");
    result.innerHTML = `${description}<br/><pre>${testResult}</pre>`;
  }
  document.body.appendChild(result);
}

function assertEqual(x, y) {
  if (
    x === y ||
    (typeof x === "object" &&
      typeof y === "object" &&
      x.length === y.length &&
      x.every((element, index) => element === y[index]))
  ) {
    return true;
  } else {
    return `${x} != ${y}`;
  }
}