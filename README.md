# RubyJobScout

RubyJobScout is an automated data pipeline and web application designed to scrape, normalize, and display remote programming job postings.

## 🚀 Features

- **Automated Scraping:** Automatically fetches the latest remote programming jobs from the We Work Remotely RSS feed.
- **Data Normalization:** Cleverly parses job descriptions to extract and normalize tricky data points like salary ranges (e.g., "$100k - $120k" becomes `min: 100000, max: 120000`). It also normalizes location data (e.g., mapping "München" to "Munich").
- **Modern Web Interface:** A premium, fully responsive UI built with Svelte & Vite featuring dark mode, glassmorphism, real-time filtering, and live "Scrape New Jobs" capabilities.
- **Resilient Backend-Frontend Integration:** The frontend can trigger the Ruby scraping script on demand, fetching freshly scraped `jobs.json` data seamlessly.

## 🛠 Tech Stack

**Backend (Data Pipeline)**
- **Ruby:** Core scraping and normalization logic (`scraper.rb`).
- **Nokogiri:** Robust XML/HTML parsing (extracting from the RSS feed).
- **JSON:** Local data storage (`frontend/public/jobs.json`).

**Frontend (Web App)**
- **Svelte:** Component-based UI framework.
- **Vite:** Next-generation frontend tooling and dev server.
- **TypeScript:** For type-safe frontend code.
- **Bun/Node:** Package management and script execution.

## 🔍 Scraping Details & Parameters

The core scraping logic lives in `backend/scraper.rb`. 

### Target Source
- **Website:** We Work Remotely (WWR)
- **Endpoint:** `https://weworkremotely.com/categories/remote-programming-jobs.rss`
- **Format:** RSS XML Feed

### Extracted Fields
The scraper parses the XML items and extracts the following fields for each job:
- `title` (Job Title)
- `company` (Company Name)
- `url` (Direct link to the job posting)
- `description` (The raw HTML description tag contents)
- `source` (Hardcoded to 'We Work Remotely')

### Normalization Parameters
Because RSS feeds often group data or hide it in the description, the script features a dedicated `DataNormalizer` to process the raw data before saving:
- **Location Normalization:** Extracts the raw location from the `<region>` tag and applies dictionary mapping (e.g., matching common city variations) and keyword cleanup (e.g., "Anywhere in the World" -> "Worldwide").
- **Salary Extraction:** WWR often embeds salary data unstructured within the HTML description. The script runs an advanced Regex (`/\$[\d,]+[kK]?\s*(?:[-–to]+\s*\$[\d,]+[kK]?)?/`) against the description text to capture complex formats like `$50K`, `$100k - $120k`, or `$250,000 - $280,000`.
- **Salary Normalization:** Converts those extracted string matches into clean structured integers (`min` and `max` values) for precise frontend rendering.
- **Timestamps:** Tracks `created_at` (first time the job was scraped) and `last_seen_at` (most recent successful scrape where the job was still present) for tracking new vs existing jobs.

## ⚙️ Getting Started

### Prerequisites
- [Ruby](https://www.ruby-lang.org/en/documentation/installation/) (v3+ recommended)
- [Bun](https://bun.sh/) or [Node.js/npm](https://nodejs.org/)

### Installation

1. **Clone the repository:**
   ```bash
   git clone <your-repo-url>
   cd RubyJobScout
   ```

2. **Backend Setup:**
   Navigate to the backend directory and install the Ruby gems (Nokogiri).
   ```bash
   cd backend
   bundle install
   ```

3. **Frontend Setup:**
   Navigate to the frontend directory and install Javascript dependencies.
   ```bash
   cd ../frontend
   bun install
   ```

### Running the Application

1. **Start the Frontend Dev Server:**
   From the `frontend` directory, start the Vite server.
   ```bash
   bun run dev
   ```
   *The server will typically start at `http://localhost:5173`.*

2. **Scraping Data:**
   - **Via the UI:** Simply click the "Scrape New Jobs" button in the web app. The Vite server will intercept the API command and run the Ruby script for you automatically.
   - **Via CLI:** If you prefer, you can manually run the scraper from the terminal:
     ```bash
     cd backend
     ruby scraper.rb
     ```
     This will generate/update the `frontend/public/jobs.json` file.
