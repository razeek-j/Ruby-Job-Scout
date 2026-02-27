import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'
import { exec } from 'child_process'

const scrapePlugin = () => ({
  name: 'scrape-plugin',
  configureServer(server) {
    server.middlewares.use('/api/scrape', (req, res) => {
      if (req.method === 'POST') {
        res.setHeader('Content-Type', 'application/json');
        exec('ruby scraper.rb', { cwd: '../backend' }, (error, stdout, stderr) => {
          if (error) {
            res.statusCode = 500;
            res.end(JSON.stringify({ success: false, error: error.message }));
            return;
          }
          res.end(JSON.stringify({ success: true, message: 'Scraped successfully' }));
        });
      }
    });
  }
})

// https://vite.dev/config/
export default defineConfig({
  plugins: [svelte(), scrapePlugin()],
  server: {
    fs: {
      allow: ['..']
    }
  }
})
