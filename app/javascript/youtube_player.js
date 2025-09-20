// YouTube video işlemleri için JavaScript
document.addEventListener('turbo:load', function() {
  setupYoutubeEmbeds();
});

document.addEventListener('turbo:frame-load', function() {
  setupYoutubeEmbeds();
});

function setupYoutubeEmbeds() {
  // Menu elementlerinin z-index değerini yükselt - Bunu en başta yapıyoruz
  const menuElements = document.querySelectorAll('.dropdown-menu, .dropdown-content, .dropdown, [data-dropdown-toggle], .dropdown-toggle');
  menuElements.forEach(menu => {
    menu.style.position = 'relative';
    menu.style.zIndex = '1000'; // Çok daha yüksek z-index değeri
  });
  
  // YouTube embedlerini bul
  const youtubeEmbeds = document.querySelectorAll('.youtube-embed');
  
  youtubeEmbeds.forEach(embed => {
    // YouTube embed elementine stil ekle
    embed.style.position = 'relative';
    embed.style.zIndex = '2'; // Daha düşük z-index değeri
    embed.style.pointerEvents = 'auto';
    
    // İframe'i bul
    const iframe = embed.querySelector('iframe');
    if (iframe) {
      // İframe'e stil ve event listener ekle
      iframe.style.position = 'relative';
      iframe.style.zIndex = '2'; // Daha düşük z-index değeri
      iframe.style.pointerEvents = 'auto';
      
      // İframe'e tıklandığında event'i durdur
      iframe.addEventListener('click', function(e) {
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
    // Post içindeki YouTube embedlerini bul
    const postYoutubeEmbeds = postLink.querySelectorAll('.youtube-embed');
    
    if (postYoutubeEmbeds.length > 0) {
      // YouTube embed elementlerini post linkinden ayır
      postYoutubeEmbeds.forEach(embed => {
        // Embed elementini post linkinden çıkar ve tekrar ekle
        const parent = embed.parentNode;
        const wrapper = document.createElement('div');
        wrapper.style.position = 'relative';
        wrapper.style.zIndex = '2'; // Daha düşük z-index değeri
        wrapper.className = 'youtube-embed-wrapper';
        
        // Embed elementini wrapper'a taşı
        parent.insertBefore(wrapper, embed);
        wrapper.appendChild(embed);
      });
      
      // Post link davranışını özelleştir
      postLink.addEventListener('click', function(e) {
        // Tıklanan element veya üst elementlerinden biri youtube-embed sınıfına sahipse
        const clickedYoutubeEmbed = e.target.closest('.youtube-embed');
        if (clickedYoutubeEmbed) {
          e.stopPropagation();
          e.preventDefault();
          return false;
        }
      }, true);
    }
  });
  
  // Global click event listener
  document.addEventListener('click', function(e) {
    // Tıklanan element veya üst elementlerinden biri youtube-embed sınıfına sahipse
    const youtubeEmbed = e.target.closest('.youtube-embed');
    if (youtubeEmbed) {
      e.stopPropagation();
      e.preventDefault();
      return false;
    }
    
    // Tıklanan element veya üst elementlerinden biri youtube-embed-wrapper sınıfına sahipse
    const youtubeEmbedWrapper = e.target.closest('.youtube-embed-wrapper');
    if (youtubeEmbedWrapper) {
      e.stopPropagation();
      e.preventDefault();
      return false;
    }
  }, true);
}