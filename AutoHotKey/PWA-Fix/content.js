console.log("🟢 Native Extension Active: UI-Synced Fullscreen Grid loaded.");

// -----------------------------------------------------------------------------
// Feature 1: The 'Smart Stop Media' & Global Shortcut Repair
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
        return;
    }

    // THE FOCUS LIMBO REPAIR
    if (window.location.pathname.startsWith('/watch')) {
        let active = document.activeElement;
        if (active && (['INPUT', 'TEXTAREA', 'SELECT'].includes(active.tagName) || active.isContentEditable)) {
            return;
        }
        
        const ytKeys = ['f', 'j', 'k', 'l', 'm', 'i', 'c', ' ', 'arrowleft', 'arrowright', 'arrowup', 'arrowdown', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
        
        if (e.key && ytKeys.includes(e.key.toLowerCase())) {
            let player = document.getElementById('movie_player');
            if (player && active !== player) {
                player.focus();
            }
        }
    }
}, true);

// -----------------------------------------------------------------------------
// Feature 2: The Infinite Grid Hijack
// -----------------------------------------------------------------------------
let gridObserver = null;
let fastPollTimer = null;

window.addEventListener('ended', function(e) {
    if (e.target && e.target.tagName && e.target.tagName.toLowerCase() === 'video') {
        if (window.location.hostname.includes('youtube.com')) {
            
            if (document.fullscreenElement) {
                document.exitFullscreen().catch(err => console.log(err));
            }

            window.scrollBy(0, 500); 
            window.dispatchEvent(new Event('scroll'));

            let attempts = 0;
            if (fastPollTimer) clearInterval(fastPollTimer);
            
            fastPollTimer = setInterval(() => {
                attempts++;
                
                const rawLinks = document.querySelectorAll('a[href*="/watch?v="]');
                
                if (rawLinks.length >= 6 || attempts >= 60) {
                    clearInterval(fastPollTimer); 
                    
                    if (rawLinks.length < 2) return;

                    console.log(`⚡ BOOM! Building UI-Synced Ghost-Free Grid...`);
                    
                    let overlay = document.getElementById('pwa-hijack-grid');
                    if (!overlay) {
                        overlay = document.createElement('div');
                        overlay.id = 'pwa-hijack-grid';
                        overlay.style.cssText = `
                            position: fixed; top: 0; left: 0; width: 100vw; height: 100vh;
                            background: #0f0f0f; z-index: 2147483647; 
                            overflow-y: auto; padding: 40px; box-sizing: border-box;
                            display: grid; grid-template-columns: repeat(4, 1fr);
                            gap: 24px; align-content: start;
                            opacity: 0; transition: opacity 0.3s ease-in-out;
                        `;
                        document.documentElement.appendChild(overlay);

                        let closeBtn = document.createElement('button');
                        closeBtn.id = 'pwa-hijack-close';
                        closeBtn.innerText = '✕ Close Grid';
                        closeBtn.style.cssText = `
                            position: fixed; top: 20px; right: 30px; z-index: 2147483648;
                            background: rgba(255,255,255,0.1); color: white; border: none;
                            padding: 10px 16px; border-radius: 20px; cursor: pointer;
                            font-size: 14px; font-weight: bold; backdrop-filter: blur(5px);
                        `;
                        closeBtn.onclick = () => { 
                            if (gridObserver) gridObserver.disconnect();
                            overlay.remove(); 
                            closeBtn.remove(); 
                        };
                        document.documentElement.appendChild(closeBtn);

                        setTimeout(() => overlay.style.opacity = '1', 50);

                        overlay.addEventListener('scroll', () => {
                            if (overlay.scrollTop + overlay.clientHeight >= overlay.scrollHeight - 600) {
                                window.scrollBy(0, 800); 
                            }
                        });
                    }

                    const extractAndAppend = () => {
                        let cards = document.querySelectorAll('ytd-rich-item-renderer, ytd-compact-video-renderer, ytd-video-renderer, yt-lockup-view-model, #dismissible');
                        let videoMap = new Map();
                        
                        cards.forEach(card => {
                            try {
                                let watchLink = card.querySelector('a[href^="/watch?v="]');
                                if (!watchLink) return;

                                let urlObj = new URL(watchLink.href, window.location.origin);
                                let videoId = urlObj.searchParams.get('v');
                                if (!videoId) return;

                                if (!videoMap.has(videoId)) {
                                    videoMap.set(videoId, { 
                                        id: videoId, url: watchLink.href, 
                                        title: '', channel: '', duration: '', metadata: '',
                                        originalNode: watchLink
                                    });
                                }
                                let v = videoMap.get(videoId);

                                // Strict Title Update
                                let titleEl = card.querySelector('#video-title, h3 a, h3 .yt-core-attributed-string, [id*="video-title"]');
                                if (titleEl) {
                                    let rawText = titleEl.getAttribute('title') || titleEl.innerText || titleEl.textContent || "";
                                    let tempTitle = rawText.split('\n')[0].trim(); 
                                    if (tempTitle && tempTitle !== "LIVE" && tempTitle !== "PREMIERE" && !/^(\d+:)?\d+:\d+$/.test(tempTitle)) {
                                        if (tempTitle.length > v.title.length) v.title = tempTitle;
                                    }
                                }
                                
                                if (!v.title || v.title.length < 2) return; 

                                // Duration
                                let durEl = card.querySelector('ytd-thumbnail-overlay-time-status-renderer, badge-shape, .badge-shape-wiz__text');
                                if (durEl) {
                                    let tempDur = (durEl.innerText || durEl.textContent || "").replace(/\n/g, '').trim();
                                    if (tempDur.length > v.duration.length) v.duration = tempDur;
                                }

                                // Universal Scrape
                                let allTexts = [];
                                let walker = document.createTreeWalker(card, NodeFilter.SHOW_TEXT, null, false);
                                let node;
                                while(node = walker.nextNode()) {
                                    let val = node.nodeValue.trim();
                                    if (val.length > 0 && !val.includes('\n')) {
                                        allTexts.push(val);
                                    }
                                }

                                let candidates = allTexts.filter(t => 
                                    t !== v.title && 
                                    t !== v.duration && 
                                    t !== "LIVE" && 
                                    t !== "SHORTS" && 
                                    !/^(\d+:)?\d+:\d+$/.test(t) &&
                                    !t.includes("http")
                                );

                                let viewOrTimePatterns = [/views?/i, /ago/i, /streamed/i, /watching/i, /K\b/, /M\b/, /B\b/];
                                let metaParts = [];
                                let channelParts = [];

                                candidates.forEach(text => {
                                    if (viewOrTimePatterns.some(pattern => pattern.test(text))) {
                                        metaParts.push(text);
                                    } else if (text.length > 1 && text.length < 40) {
                                        channelParts.push(text);
                                    }
                                });

                                if (channelParts.length > 0 && !v.channel) v.channel = channelParts[0];
                                if (metaParts.length > 0 && !v.metadata) v.metadata = metaParts.join(' • ');

                            } catch(err) {}
                        });

                        videoMap.forEach((v, videoId) => {
                            if (!v.title || v.title.length < 2) return; // Ghost Killer

                            let cardId = `pwa-card-${videoId}`;
                            let existingCard = document.getElementById(cardId);

                            if (existingCard) {
                                existingCard.querySelector('.pwa-title').innerText = v.title;
                                if (v.channel) existingCard.querySelector('.pwa-channel').innerText = v.channel;
                                if (v.metadata) existingCard.querySelector('.pwa-meta').innerText = v.metadata;
                                if (v.duration) {
                                    let badge = existingCard.querySelector('.pwa-dur');
                                    if (badge) {
                                        badge.innerText = v.duration;
                                        badge.style.display = 'block';
                                    }
                                }
                            } else {
                                let uiCard = document.createElement('a');
                                uiCard.id = cardId;
                                uiCard.href = `https://www.youtube.com/watch?v=${videoId}`;
                                uiCard.style.cssText = `text-decoration: none; display: flex; flex-direction: column; cursor: pointer; transition: transform 0.2s; min-width: 0;`;
                                uiCard.onmouseover = () => uiCard.style.transform = 'scale(1.02)';
                                uiCard.onmouseout = () => uiCard.style.transform = 'scale(1)';

                                // --- THE UI-SYNCED FULLSCREEN FIX ---
                                uiCard.addEventListener('click', (e) => {
                                    e.preventDefault(); 
                                    
                                    const triggerNavigation = () => {
                                        if (v.originalNode && document.body.contains(v.originalNode)) {
                                            v.originalNode.click();
                                        } else {
                                            let appRoot = document.querySelector('ytd-app') || document.body;
                                            let tempLink = document.createElement('a');
                                            tempLink.href = uiCard.href;
                                            appRoot.appendChild(tempLink);
                                            tempLink.click();
                                            tempLink.remove();
                                        }

                                        setTimeout(() => {
                                            let activePlayer = document.getElementById('movie_player');
                                            if (activePlayer) activePlayer.focus();
                                        }, 500);
                                    };

                                    if (!document.fullscreenElement) {
                                        // Find YouTube's authentic Fullscreen button
                                        let fsBtn = document.querySelector('.ytp-fullscreen-button');
                                        if (fsBtn) {
                                            // Wait for the browser to confirm the monitor has expanded
                                            const fsHandler = () => {
                                                document.removeEventListener('fullscreenchange', fsHandler);
                                                clearTimeout(fsFailsafe);
                                                setTimeout(triggerNavigation, 50); // Small buffer before routing
                                            };
                                            document.addEventListener('fullscreenchange', fsHandler);

                                            // Failsafe in case the browser blocks the click
                                            const fsFailsafe = setTimeout(() => {
                                                document.removeEventListener('fullscreenchange', fsHandler);
                                                triggerNavigation();
                                            }, 800);

                                            // Trigger YouTube's native UI button
                                            fsBtn.click();
                                        } else {
                                            triggerNavigation();
                                        }
                                    } else {
                                        triggerNavigation(); 
                                    }
                                });
                                // -------------------------------------

                                let thumbContainer = document.createElement('div');
                                thumbContainer.style.cssText = `position: relative; width: 100%; aspect-ratio: 16/9; margin-bottom: 12px;`;

                                let img = document.createElement('img');
                                img.src = `https://i.ytimg.com/vi/${videoId}/hqdefault.jpg`;
                                img.style.cssText = `width: 100%; height: 100%; border-radius: 12px; object-fit: cover; background: #222; display: block;`;
                                thumbContainer.appendChild(img);

                                let durBadge = document.createElement('div');
                                durBadge.className = 'pwa-dur';
                                durBadge.innerText = v.duration;
                                durBadge.style.cssText = `position: absolute; bottom: 6px; right: 6px; background: rgba(0, 0, 0, 0.8); color: white; font-size: 12px; font-weight: 500; font-family: "Roboto", sans-serif; padding: 3px 4px; border-radius: 4px; line-height: 1; z-index: 2; display: ${v.duration ? 'block' : 'none'};`;
                                thumbContainer.appendChild(durBadge);

                                let titleText = document.createElement('div');
                                titleText.className = 'pwa-title';
                                titleText.innerText = v.title;
                                titleText.style.cssText = `color: #f1f1f1; font-size: 16px; font-family: "Roboto", sans-serif; font-weight: 500; line-height: 1.4; margin-bottom: 4px; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; word-break: break-word; min-height: 44px;`;

                                let channelText = document.createElement('div');
                                channelText.className = 'pwa-channel';
                                channelText.innerText = v.channel || '\u00A0'; 
                                channelText.style.cssText = `color: #aaaaaa; font-size: 14px; font-family: "Roboto", sans-serif; line-height: 1.4; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; display: block; width: 100%; min-height: 20px;`;

                                let metaText = document.createElement('div');
                                metaText.className = 'pwa-meta';
                                metaText.innerText = v.metadata || '\u00A0'; 
                                metaText.style.cssText = `color: #aaaaaa; font-size: 14px; font-family: "Roboto", sans-serif; line-height: 1.4; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; display: block; width: 100%; min-height: 20px;`;

                                uiCard.appendChild(thumbContainer);
                                uiCard.appendChild(titleText);
                                uiCard.appendChild(channelText);
                                uiCard.appendChild(metaText);
                                
                                let gridTarget = document.getElementById('pwa-hijack-grid');
                                if (gridTarget) gridTarget.appendChild(uiCard);
                            }
                        });
                    };

                    extractAndAppend();

                    if (gridObserver) gridObserver.disconnect();
                    gridObserver = new MutationObserver(() => extractAndAppend());
                    gridObserver.observe(document.body, { childList: true, subtree: true });
                }
            }, 50); 
        }
    }
}, true);

window.addEventListener('yt-navigate-start', function() {
    if (fastPollTimer) clearInterval(fastPollTimer);
    if (gridObserver) gridObserver.disconnect();
    
    let overlay = document.getElementById('pwa-hijack-grid');
    let closeBtn = document.getElementById('pwa-hijack-close');
    
    if (overlay) overlay.remove();
    if (closeBtn) closeBtn.remove();
});