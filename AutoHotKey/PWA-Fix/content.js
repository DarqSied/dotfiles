console.log("🟢 Native Extension Active: Lightning Fast Grid Watcher loaded.");

// -----------------------------------------------------------------------------
// Feature 1: The 'Smart Stop Media' (Alt + Shift + Y)
// -----------------------------------------------------------------------------
window.addEventListener('keydown', function(e) {
    if (e.altKey && !e.ctrlKey && e.shiftKey && e.code === 'KeyY') {
        document.querySelectorAll('video, audio').forEach(v => {
            if (!v.paused) {
                v.pause();
                console.log("🛑 Media paused by script!");
                document.body.style.transition = "filter 0.1s";
                document.body.style.filter = "invert(100%)";
                setTimeout(() => document.body.style.filter = "none", 100);
            }
        });
    }
}, true);

// -----------------------------------------------------------------------------
// Feature 2: The Infinite Grid Hijack (Lightning Fast)
// -----------------------------------------------------------------------------
let gridObserver = null;
let fastPollTimer = null;

window.addEventListener('ended', function(e) {
    if (e.target && e.target.tagName && e.target.tagName.toLowerCase() === 'video') {
        if (window.location.hostname.includes('youtube.com')) {
            
            // 1. Kick out of fullscreen immediately
            if (document.fullscreenElement) {
                document.exitFullscreen().catch(err => console.log(err));
            }

            // 2. Instantly shake the page to wake up the lazy-loader
            window.scrollBy(0, 500); 
            window.dispatchEvent(new Event('scroll'));

            // 3. Hyper-Polling: Check every 50ms for the videos to appear
            let attempts = 0;
            if (fastPollTimer) clearInterval(fastPollTimer);
            
            fastPollTimer = setInterval(() => {
                attempts++;
                
                // Count how many raw links exist on the page right now
                const rawLinks = document.querySelectorAll('a[href*="/watch?v="]');
                
                // If we found a good batch of videos, OR we timed out after 2 seconds (40 attempts)
                if (rawLinks.length >= 4 || attempts >= 40) {
                    clearInterval(fastPollTimer); // Stop checking
                    
                    if (rawLinks.length < 4) {
                        console.log("❌ Fast extraction failed: Videos didn't load in time.");
                        return;
                    }

                    console.log(`⚡ BOOM! Found videos in ${attempts * 50}ms! Building grid...`);
                    let seenIds = new Set();
                    
                    // --- Build the Overlay ---
                    let overlay = document.createElement('div');
                    overlay.id = 'pwa-hijack-grid';
                    overlay.style.cssText = `
                        position: fixed; top: 0; left: 0; width: 100vw; height: 100vh;
                        background: #0f0f0f; z-index: 2147483647; 
                        overflow-y: auto; padding: 40px; box-sizing: border-box;
                        display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
                        gap: 24px; align-content: start;
                    `;

                    // --- The Extraction Function ---
                    const extractAndAppend = () => {
                        const currentLinks = document.querySelectorAll('a[href*="/watch?v="]');
                        
                        currentLinks.forEach(link => {
                            let title = link.getAttribute('title');
                            if (!title) {
                                title = link.innerText.trim().replace(/\n/g, ' ').replace(/\d{1,2}:\d{2}:\d{2}|\d{1,2}:\d{2}$/, '').trim(); 
                            }
                            if (title.length < 3) return; 

                            try {
                                let urlObj = new URL(link.href);
                                let videoId = urlObj.searchParams.get('v');
                                
                                if (videoId && !seenIds.has(videoId)) {
                                    seenIds.add(videoId); 
                                    
                                    let channel = '';
                                    let container = link.closest('ytd-compact-video-renderer, ytd-rich-item-renderer, ytd-video-renderer');
                                    if (container) {
                                        let channelEl = container.querySelector('ytd-channel-name yt-formatted-string, .ytd-channel-name');
                                        if (channelEl) channel = channelEl.innerText.trim();
                                    }

                                    let card = document.createElement('a');
                                    card.href = link.href;
                                    card.style.cssText = `text-decoration: none; display: flex; flex-direction: column; cursor: pointer; transition: transform 0.2s;`;
                                    card.onmouseover = () => card.style.transform = 'scale(1.02)';
                                    card.onmouseout = () => card.style.transform = 'scale(1)';

                                    let img = document.createElement('img');
                                    img.src = `https://i.ytimg.com/vi/${videoId}/hqdefault.jpg`;
                                    img.style.cssText = `width: 100%; aspect-ratio: 16/9; border-radius: 12px; object-fit: cover; margin-bottom: 12px; background: #222;`;

                                    let titleText = document.createElement('div');
                                    titleText.innerText = title;
                                    titleText.style.cssText = `color: #f1f1f1; font-size: 16px; font-family: "Roboto", sans-serif; font-weight: 500; line-height: 1.4; margin-bottom: 4px; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;`;

                                    let channelText = document.createElement('div');
                                    channelText.innerText = channel;
                                    channelText.style.cssText = `color: #aaaaaa; font-size: 14px; font-family: "Roboto", sans-serif;`;

                                    card.appendChild(img);
                                    card.appendChild(titleText);
                                    card.appendChild(channelText);
                                    overlay.appendChild(card);
                                }
                            } catch(err) {}
                        });
                    };

                    // Run extraction immediately
                    extractAndAppend();

                    // --- The Close Button ---
                    let closeBtn = document.createElement('button');
                    closeBtn.id = 'pwa-hijack-close';
                    closeBtn.innerText = '✕ Close Grid';
                    closeBtn.style.cssText = `
                        position: fixed; top: 20px; right: 30px; z-index: 2147483648;
                        background: rgba(255,255,255,0.1); color: white; border: none;
                        padding: 10px 15px; border-radius: 20px; cursor: pointer;
                        font-size: 14px; font-weight: bold; backdrop-filter: blur(5px);
                    `;
                    closeBtn.onclick = () => { 
                        if (gridObserver) gridObserver.disconnect();
                        overlay.remove(); 
                        closeBtn.remove(); 
                    };

                    document.documentElement.appendChild(overlay);
                    document.documentElement.appendChild(closeBtn);

                    // --- The Scroll Sync ---
                    overlay.addEventListener('scroll', () => {
                        if (overlay.scrollTop + overlay.clientHeight >= overlay.scrollHeight - 600) {
                            window.scrollBy(0, 800); 
                        }
                    });

                    // --- The Mutation Watcher ---
                    if (gridObserver) gridObserver.disconnect();
                    gridObserver = new MutationObserver(() => extractAndAppend());
                    gridObserver.observe(document.body, { childList: true, subtree: true });

                }
            }, 50); // The 50 millisecond check!
        }
    }
}, true);

// -----------------------------------------------------------------------------
// Feature 3: The Cleanup
// -----------------------------------------------------------------------------
window.addEventListener('yt-navigate-start', function() {
    if (fastPollTimer) clearInterval(fastPollTimer);
    if (gridObserver) gridObserver.disconnect();
    
    let overlay = document.getElementById('pwa-hijack-grid');
    let closeBtn = document.getElementById('pwa-hijack-close');
    
    if (overlay) overlay.remove();
    if (closeBtn) closeBtn.remove();
});