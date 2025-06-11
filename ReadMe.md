# BuddyPond Upload Action

📡 **Deploy your static files directly to BuddyPond Pads**  
This GitHub Action uploads your app’s files to [BuddyPond](https://buddypond.com), using a secure signed URL system.

---

## 🚀 Features

- Upload your Apps to the Buddy Pond Ecosystem
- Simple drag-and-drop deployment via GitHub Actions
- Works with any static site: HTML, JS, CSS, WebAssembly, WebGL, and more

---

## 🧠 Usage

### 1. Add this to your `.github/workflows/upload.yml`

```yaml
name: Upload to BuddyPond

on:
  push:
    branches: [ main ]

jobs:
  upload:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repo
        uses: actions/checkout@v4

      - name: Upload Files to BuddyPond
        uses: buddypond/upload-action@v1
        with:
          bp_api_key: ${{ secrets.BP_API_KEY }}
          user: your-buddypond-username
          folder: pads/my-app
```

### 2. Add Your API Key

In your repository settings:

- Go to **Settings → Secrets and variables → Actions → New repository secret**
- Add the following:

```
Name: BP_API_KEY
Value: <your secret BuddyPond API key>
```

### 3. Done!

Your files will be uploaded to: https://files.buddypond.com/<your-username>/<folder>/

## 📚 Example Repo

Check out the [example app repository](https://github.com/buddypond/app-template) for a working reference.

---

## 💬 Need Help?

Join the conversation on [BuddyPond](https://buddypond.com) or ask questions via your Pad!

---
