<script lang="ts">
  import { onMount } from "svelte";

  interface Job {
    title: string;
    company: string;
    location: string;
    url: string;
    created_at: string;
    last_seen_at: string;
    salary_raw?: string;
    salary_normalized?: { min: number; max: number };
    source?: string;
  }

  let jobs: Job[] = [];
  let searchQuery = "";
  let isScraping = false;
  let isLoading = true;

  async function loadJobs() {
    isLoading = true;
    try {
      // Add a timestamp to bypass Vite static caching
      const response = await fetch(`/jobs.json?t=${Date.now()}`);
      if (response.ok) {
        const text = await response.text();
        if (text.trim() === "") {
          jobs = [];
        } else {
          jobs = JSON.parse(text);
        }
      } else {
        jobs = [];
      }
    } catch (e) {
      console.error("Error loading jobs:", e);
      jobs = [];
    } finally {
      isLoading = false;
    }
  }

  onMount(() => {
    loadJobs();
  });

  async function triggerScrape() {
    isScraping = true;
    try {
      const response = await fetch("/api/scrape", { method: "POST" });
      if (response.ok) {
        await loadJobs(); // instantly reload jobs in state
      }
    } catch (e) {
      console.error("Failed to trigger scrape:", e);
    } finally {
      isScraping = false;
    }
  }

  $: filteredJobs = jobs.filter(
    (job) =>
      job.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      job.company.toLowerCase().includes(searchQuery.toLowerCase()),
  );

  function formatSalary(salaryObj?: { min: number; max: number }) {
    if (!salaryObj) return null;
    if (salaryObj.min === salaryObj.max) {
      return `$${(salaryObj.min / 1000).toFixed(0)}k`;
    }
    return `$${(salaryObj.min / 1000).toFixed(0)}k - $${(salaryObj.max / 1000).toFixed(0)}k`;
  }
</script>

<main class="container">
  <header class="hero">
    <div class="glow-orb"></div>
    <h1>RubyJobScout</h1>
    <p class="subtitle">Automated Data Pipeline for Remote Programming Roles</p>

    <div class="search-wrap">
      <input
        type="text"
        bind:value={searchQuery}
        placeholder="Search jobs or companies..."
        class="search-bar"
      />

      <button
        class="btn-primary scrape-btn"
        on:click={triggerScrape}
        disabled={isScraping}
      >
        {#if isScraping}
          <svg class="spinner" viewBox="0 0 50 50"
            ><circle
              class="path"
              cx="25"
              cy="25"
              r="20"
              fill="none"
              stroke-width="5"
            ></circle></svg
          >
          Scraping...
        {:else}
          <svg
            class="icon sync-icon"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            ><path d="M23 4v6h-6"></path><path d="M1 20v-6h6"></path><path
              d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"
            ></path></svg
          >
          Scrape New Jobs
        {/if}
      </button>
    </div>
  </header>

  <section class="job-list">
    {#if isLoading}
      <div class="empty-state">
        <svg
          class="spinner"
          viewBox="0 0 50 50"
          style="margin: 0 auto 1rem; color: var(--primary)"
          ><circle
            class="path"
            cx="25"
            cy="25"
            r="20"
            fill="none"
            stroke-width="5"
          ></circle></svg
        >
        <h3>Loading jobs</h3>
        <p>Fetching from the database...</p>
      </div>
    {:else if filteredJobs.length === 0}
      <div class="empty-state">
        <svg
          class="icon empty-icon"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          ><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline
            points="17 8 12 3 7 8"
          ></polyline><line x1="12" y1="3" x2="12" y2="15"></line></svg
        >
        <h3>No jobs found</h3>
        <p>
          Try scraping jobs, adjusting your search, saving a valid jobs.json.
        </p>
      </div>
    {:else}
      <div class="stats">
        <span>showing {filteredJobs.length} remote positions</span>
      </div>

      {#each filteredJobs as job}
        <article class="job-card">
          <div class="job-header">
            <div class="job-company">
              {job.company}
              <span class="job-source"
                >• {job.source || "We Work Remotely"}</span
              >
            </div>
            {#if job.created_at === job.last_seen_at}
              <span class="badge new-badge">New</span>
            {/if}
          </div>

          <h2 class="job-title">{job.title}</h2>

          <div class="job-meta">
            <div class="meta-item">
              <svg
                class="icon"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                ><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"
                ></path><circle cx="12" cy="10" r="3"></circle></svg
              >
              {job.location}
            </div>

            {#if job.salary_normalized}
              <div class="meta-item salary">
                <svg
                  class="icon"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  ><line x1="12" y1="1" x2="12" y2="23"></line><path
                    d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"
                  ></path></svg
                >
                {formatSalary(job.salary_normalized)}
              </div>
            {/if}
          </div>

          <div class="job-actions">
            <a
              href={job.url}
              target="_blank"
              rel="noopener noreferrer"
              class="btn-primary"
            >
              Apply Now
              <svg
                class="arrow"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                ><line x1="5" y1="12" x2="19" y2="12"></line><polyline
                  points="12 5 19 12 12 19"
                ></polyline></svg
              >
            </a>
          </div>
        </article>
      {/each}
    {/if}
  </section>
</main>

<style>
  .container {
    max-width: 900px;
    margin: 0 auto;
    padding: 2rem 1rem 6rem;
  }

  .hero {
    position: relative;
    text-align: center;
    padding: 4rem 0 3rem;
    margin-bottom: 2rem;
  }

  .glow-orb {
    position: absolute;
    top: 0;
    left: 50%;
    transform: translateX(-50%);
    width: 300px;
    height: 300px;
    background: radial-gradient(
      circle,
      rgba(88, 166, 255, 0.15) 0%,
      transparent 70%
    );
    z-index: -1;
    pointer-events: none;
  }

  h1 {
    font-size: 3.5rem;
    font-weight: 700;
    letter-spacing: -0.05em;
    background: linear-gradient(135deg, #ffffff 0%, #8b949e 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    margin-bottom: 0.5rem;
  }

  .subtitle {
    color: var(--text-secondary);
    font-size: 1.1rem;
    font-weight: 400;
    margin-bottom: 2.5rem;
  }

  .search-wrap {
    max-width: 650px;
    margin: 0 auto;
    position: relative;
    display: flex;
    gap: 1rem;
    align-items: center;
  }

  .search-bar {
    flex: 1;
    padding: 1rem 1.5rem;
    border-radius: 999px;
    border: 1px solid var(--border-color);
    background: var(--card-bg);
    color: var(--text-primary);
    font-family: inherit;
    font-size: 1rem;
    backdrop-filter: blur(10px);
    transition: all 0.3s ease;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
  }

  .search-bar:focus {
    outline: none;
    border-color: var(--accent);
    box-shadow:
      0 0 0 3px rgba(88, 166, 255, 0.2),
      0 4px 20px rgba(0, 0, 0, 0.2);
  }

  .stats {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1.5rem;
    padding-bottom: 0.5rem;
    border-bottom: 1px solid var(--border-color);
    color: var(--text-secondary);
    font-size: 0.9rem;
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }

  .job-card {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: 16px;
    padding: 1.5rem 2rem;
    margin-bottom: 1rem;
    backdrop-filter: blur(10px);
    transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
    position: relative;
    overflow: hidden;
  }

  .job-card::before {
    content: "";
    position: absolute;
    top: 0;
    left: 0;
    width: 4px;
    height: 100%;
    background: var(--accent);
    transform: scaleY(0);
    transition: transform 0.3s ease;
    transform-origin: bottom;
  }

  .job-card:hover {
    transform: translateY(-4px);
    border-color: rgba(88, 166, 255, 0.3);
    box-shadow: 0 12px 30px rgba(0, 0, 0, 0.3);
  }

  .job-card:hover::before {
    transform: scaleY(1);
    transform-origin: top;
  }

  .job-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 0.5rem;
  }

  .job-company {
    color: var(--accent);
    font-weight: 600;
    font-size: 0.9rem;
    letter-spacing: 0.05em;
    text-transform: uppercase;
  }

  .badge {
    background: rgba(35, 134, 54, 0.2);
    color: #3fb950;
    border: 1px solid rgba(35, 134, 54, 0.4);
    padding: 0.15rem 0.5rem;
    border-radius: 999px;
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
  }

  .job-title {
    font-size: 1.4rem;
    font-weight: 600;
    color: var(--text-primary);
    margin-bottom: 1rem;
    line-height: 1.3;
  }

  .job-meta {
    display: flex;
    flex-wrap: wrap;
    gap: 1.5rem;
    margin-bottom: 1.5rem;
  }

  .meta-item {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    color: var(--text-secondary);
    font-size: 0.9rem;
  }

  .meta-item.salary {
    color: #3fb950;
    font-weight: 500;
  }

  .icon {
    width: 16px;
    height: 16px;
    opacity: 0.8;
  }

  .job-actions {
    display: flex;
    justify-content: flex-end;
  }

  .btn-primary {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    background: rgba(88, 166, 255, 0.1);
    color: var(--accent);
    padding: 0.6rem 1.25rem;
    border-radius: 8px;
    font-weight: 500;
    font-size: 0.9rem;
    border: 1px solid rgba(88, 166, 255, 0.2);
    transition: all 0.2s ease;
  }

  .btn-primary:hover {
    background: var(--accent);
    color: #fff;
    box-shadow: 0 4px 12px rgba(88, 166, 255, 0.3);
  }

  .btn-primary .arrow {
    width: 16px;
    height: 16px;
    transition: transform 0.2s ease;
  }

  .btn-primary:hover .arrow {
    transform: translateX(4px);
  }

  .scrape-btn {
    white-space: nowrap;
    height: 100%;
    padding: 1rem 1.5rem;
    border-radius: 999px;
    font-size: 1rem;
    background: rgba(35, 134, 54, 0.1);
    color: var(--success);
    border-color: rgba(35, 134, 54, 0.3);
  }

  .scrape-btn:hover:not(:disabled) {
    background: var(--success);
    color: #fff;
    box-shadow: 0 4px 12px rgba(35, 134, 54, 0.3);
  }

  .scrape-btn:disabled {
    opacity: 0.7;
    cursor: wait;
  }

  .job-source {
    color: var(--text-secondary);
    font-weight: 400;
  }

  .sync-icon {
    width: 18px;
    height: 18px;
  }

  .spinner {
    animation: rotate 2s linear infinite;
    width: 18px;
    height: 18px;
  }

  .spinner .path {
    stroke: currentColor;
    stroke-linecap: round;
    animation: dash 1.5s ease-in-out infinite;
  }

  @keyframes rotate {
    100% {
      transform: rotate(360deg);
    }
  }

  @keyframes dash {
    0% {
      stroke-dasharray: 1, 150;
      stroke-dashoffset: 0;
    }
    50% {
      stroke-dasharray: 90, 150;
      stroke-dashoffset: -35;
    }
    100% {
      stroke-dasharray: 90, 150;
      stroke-dashoffset: -124;
    }
  }

  .empty-state {
    text-align: center;
    padding: 4rem 2rem;
    color: var(--text-secondary);
    background: var(--card-bg);
    border: 1px dashed var(--border-color);
    border-radius: 16px;
  }

  @media (max-width: 600px) {
    .search-wrap {
      flex-direction: column;
    }

    .scrape-btn {
      width: 100%;
      justify-content: center;
    }

    .job-card {
      padding: 1.25rem;
    }

    .job-meta {
      flex-direction: column;
      gap: 0.5rem;
    }

    h1 {
      font-size: 2.5rem;
    }
  }
</style>
