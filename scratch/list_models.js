const API_KEY = "AIzaSyBlOIuJNwvkfzaYCseAbhMuF5ubEg6YiFA";

async function listModels() {
  console.log("Listing models via v1beta...");
  const resp = await fetch(`https://generativelanguage.googleapis.com/v1beta/models?key=${API_KEY}`);
  if (!resp.ok) {
    console.log("Error:", resp.status, await resp.text());
    return;
  }
  const data = await resp.json();
  console.log("Available models:");
  data.models.forEach(m => {
    if (m.name.includes("gemma")) {
      console.log("-", m.name);
    }
  });
}

listModels();
