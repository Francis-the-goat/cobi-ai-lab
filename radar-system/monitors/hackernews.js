#!/usr/bin/env node
// Monitor Hacker News for AI posts and Show HN
// Output: JSON file with signals

const https = require('https');
const fs = require('fs');
const path = require('path');

const queueDir = path.resolve(__dirname, '..', 'queue');
const CACHE_FILE = path.join(queueDir, 'hn-seen.txt');
const OUTPUT_FILE = path.join(
    queueDir,
    `hn-signals-${new Date().toISOString().slice(0,10).replace(/-/g,'')}-${new Date().toISOString().slice(11,13)}${new Date().toISOString().slice(14,16)}.json`
);

if (!fs.existsSync(queueDir)) {
    fs.mkdirSync(queueDir, { recursive: true });
}

// Ensure cache exists
if (!fs.existsSync(CACHE_FILE)) {
    fs.writeFileSync(CACHE_FILE, '');
}
const seen = new Set(fs.readFileSync(CACHE_FILE, 'utf8').split('\n').filter(Boolean));

function fetch(url) {
    return new Promise((resolve, reject) => {
        https.get(url, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => resolve(JSON.parse(data)));
        }).on('error', reject);
    });
}

async function main() {
    const oneDayAgo = Math.floor(Date.now() / 1000) - 86400;
    
    // Fetch Show HN
    const showHN = await fetch(`https://hn.algolia.com/api/v1/search?tags=show_hn&numericFilters=created_at_i>${oneDayAgo}`);
    
    // Fetch AI posts
    const aiPosts = await fetch(`https://hn.algolia.com/api/v1/search?query=AI&tags=story&numericFilters=created_at_i>${oneDayAgo}`);
    
    // Filter for high engagement
    const showSignals = showHN.hits
        .filter(h => h.points > 10)
        .filter(h => !seen.has(h.objectID))
        .map(h => ({
            id: h.objectID,
            title: h.title,
            url: h.url,
            points: h.points,
            comments: h.num_comments,
            created: h.created_at,
            source: 'hackernews-show'
        }));
        
    const aiSignals = aiPosts.hits
        .filter(h => h.points > 20)
        .filter(h => !seen.has(h.objectID))
        .map(h => ({
            id: h.objectID,
            title: h.title,
            url: h.url,
            points: h.points,
            comments: h.num_comments,
            created: h.created_at,
            source: 'hackernews-ai'
        }));
    
    // Add to seen
    [...showSignals, ...aiSignals].forEach(s => {
        seen.add(s.id);
        fs.appendFileSync(CACHE_FILE, s.id + '\n');
    });
    
    const output = {
        timestamp: new Date().toISOString(),
        source: 'hackernews',
        signals: [...showSignals, ...aiSignals]
    };
    
    fs.writeFileSync(OUTPUT_FILE, JSON.stringify(output, null, 2));
    console.log(`HN monitor: ${showSignals.length} Show HN + ${aiSignals.length} AI posts`);
}

main().catch(console.error);
