const API_KEY = "AIzaSyBlOIuJNwvkfzaYCseAbhMuF5ubEg6YiFA";
const MODEL = "gemma-4-26b-it";

async function testV1() {
  console.log("Testing v1...");
  const resp = await fetch(`https://generativelanguage.googleapis.com/v1/models/${MODEL}:generateContent?key=${API_KEY}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ role: "user", parts: [{ text: "hi" }] }]
    })
  });
  console.log("v1 status:", resp.status);
  console.log("v1 body:", await resp.text());
}

async function testV1Beta() {
  console.log("\nTesting v1beta...");
  const resp = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${API_KEY}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ role: "user", parts: [{ text: "hi" }] }]
    })
  });
  console.log("v1beta status:", resp.status);
  console.log("v1beta body:", await resp.text());
}

testV1().then(testV1Beta);
