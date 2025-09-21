// TikTok video işlemleri için JavaScript
document.addEventListener('turbo:load', function() {
  initTikTok();
  setupTiktokEmbeds();
});

document.addEventListener('turbo:frame-load', function() {
  initTikTok();
  setupTiktokEmbeds();
});

document.addEventListener('turbo:render', function() {
  initTikTok();
  setupTiktokEmbeds();
});

function initTikTok() {
  const tiktokEmbeds = document.querySelectorAll('.tiktok-embed');
  if (tiktokEmbeds.length > 0) {
    loadTikTokScript();
  }
}

function loadTikTokScript() {
  if (document.querySelector('script[src="https://www.tiktok.com/embed.js"]')) {
    // Script zaten yüklü, bu yüzden TikTok'a yeni embed'leri işlemesini söylemeliyiz.
    if (window.tiktok && typeof window.tiktok.process === 'function') {
      window.tiktok.process();
    }
    return;
  }
  const script = document.createElement('script');
  script.src = 'https://www.tiktok.com/embed.js';
  script.async = true;
  document.body.appendChild(script);
}

function setupTiktokEmbeds() {
  // Menu elementlerinin z-index değerini yükselt - Bunu en başta yapıyoruz
  const menuElements = document.querySelectorAll('.dropdown-menu, .dropdown-content, .dropdown, [data-dropdown-toggle], .dropdown-toggle');
  menuElements.forEach(menu => {
    menu.style.position = 'relative';
    menu.style.zIndex = '1000'; // Çok daha yüksek z-index değeri
  });
  
  // TikTok embedlerini bul
  const tiktokEmbeds = document.querySelectorAll('.tiktok-embed-wrapper');
  
  tiktokEmbeds.forEach(embed => {
    // TikTok embed elementine stil ekle
    embed.style.position = 'relative';
    embed.style.zIndex = '2'; // Daha düşük z-index değeri
    embed.style.pointerEvents = 'auto';
    
    // Blockquote'u bul
    const blockquote = embed.querySelector('.tiktok-embed');
    if (blockquote) {
      // Blockquote'e stil ve event listener ekle
      blockquote.style.position = 'relative';
      blockquote.style.zIndex = '2'; // Daha düşük z-index değeri
      blockquote.style.pointerEvents = 'auto';
      
      // Blockquote'e tıklandığında event'i durdur
      blockquote.addEventListener('click', function(e) {
        e.stopPropagation();
        e.preventDefault();
        return false;
      }, true);
    }
    
    // Embed'in kendisine tıklandığında event'i durdur
    embed.addEventListener('click', function(e) {
      e.stopPropagation();
      e.preventDefault();
      return false;
    }, true);
    
    // Tüm linkleri bul
    const links = embed.querySelectorAll('a');
    links.forEach(link => {
      link.style.pointerEvents = 'auto';
      link.setAttribute('data-turbo', 'false');
    });
  });
  
  // Post linklerini bul
  const postLinks = document.querySelectorAll('.bg-black.border-b');
  
  postLinks.forEach(postLink => {
    // Post içindeki TikTok embedlerini bul
    const postTiktokEmbeds = postLink.querySelectorAll('.tiktok-embed-wrapper');
    
    if (postTiktokEmbeds.length > 0) {
      // TikTok embed elementlerini post linkinden ayır
      postTiktokEmbeds.forEach(embed => {
        // Embed elementini post linkinden çıkar ve tekrar ekle
        const parent = embed.parentNode;
        const wrapper = document.createElement('div');
        wrapper.style.position = 'relative';
        wrapper.style.zIndex = '2'; // Daha düşük z-index değeri
        wrapper.className = 'tiktok-embed-container';
        
        // Embed elementini wrapper'a taşı
        parent.insertBefore(wrapper, embed);
        wrapper.appendChild(embed);
      });
      
      // Post link davranışını özelleştir
      postLink.addEventListener('click', function(e) {
        // Tıklanan element veya üst elementlerinden biri tiktok-embed-wrapper sınıfına sahipse
        const clickedTiktokEmbed = e.target.closest('.tiktok-embed-wrapper');
        if (clickedTiktokEmbed) {
          e.stopPropagation();
          e.preventDefault();
          return false;
        }
      }, true);
    }
  });
  
  // Global click event listener
  document.addEventListener('click', function(e) {
    // TikTok embed alanına tıklandığında post navigasyonunu engelle
    const tiktokEmbed = e.target.closest('.tiktok-embed-wrapper');
    if (tiktokEmbed) {
      e.stopPropagation();
      return false;
    }
  }, true);
}